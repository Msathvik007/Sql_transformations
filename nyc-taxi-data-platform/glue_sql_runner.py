import sys
import json
import logging
from typing import List, Tuple

import boto3
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext


# ---------------------------
# Logging
# ---------------------------
def setup_logger() -> logging.Logger:
    logger = logging.getLogger("glue-sql-runner-jdbc")
    logger.setLevel(logging.INFO)
    if not logger.handlers:
        h = logging.StreamHandler(sys.stdout)
        h.setFormatter(logging.Formatter("%(asctime)s | %(levelname)s | %(message)s"))
        logger.addHandler(h)
    return logger


logger = setup_logger()
s3 = boto3.client("s3")


# ---------------------------
# Helpers: S3
# ---------------------------
def parse_s3_uri(uri: str) -> Tuple[str, str]:
    if not uri.startswith("s3://"):
        raise ValueError(f"Invalid S3 URI: {uri}")
    no_scheme = uri[5:]
    bucket, key = no_scheme.split("/", 1)
    return bucket, key


def s3_read_text(uri: str) -> str:
    bucket, key = parse_s3_uri(uri)
    obj = s3.get_object(Bucket=bucket, Key=key)
    return obj["Body"].read().decode("utf-8")


# ---------------------------
# Glue connection -> JDBC URL/user/password
# ---------------------------
def get_jdbc_conf(glue_ctx: GlueContext, connection_name: str, db_name_fallback: str):
    conf = glue_ctx.extract_jdbc_conf(connection_name)

    url = conf.get("url", "").strip()
    user = conf.get("user")
    password = conf.get("password")

    if not url or not user or not password:
        raise Exception(f"Glue connection did not return url/user/password. Keys={list(conf.keys())}")

    # Patch DB name if Glue returns host:port only
    if url.endswith(":5432"):
        url = f"{url}/{db_name_fallback}"

    return url, user, password


# ---------------------------
# SQL splitting (basic but safe enough for your scripts)
# If you have complex $$ blocks with semicolons inside, keep them in separate files.
# ---------------------------
def split_sql_statements(sql_text: str) -> List[str]:
    stmts = []
    buf = []
    in_single = False
    in_double = False

    for ch in sql_text:
        if ch == "'" and not in_double:
            in_single = not in_single
        elif ch == '"' and not in_single:
            in_double = not in_double

        if ch == ";" and not in_single and not in_double:
            stmt = "".join(buf).strip()
            if stmt:
                stmts.append(stmt)
            buf = []
        else:
            buf.append(ch)

    tail = "".join(buf).strip()
    if tail:
        stmts.append(tail)

    return [s for s in stmts if s.strip()]


def is_test_script(path: str) -> bool:
    p = path.replace("\\", "/")
    return p.startswith("sql/95_tests/") or "/95_tests/" in p


def strip_trailing_semicolon(sql_text: str) -> str:
    t = sql_text.strip()
    return t[:-1].strip() if t.endswith(";") else t


# ---------------------------
# JDBC execution via JVM
# ---------------------------
def jdbc_connect(glue_ctx: GlueContext, jdbc_url: str, user: str, password: str):
    jvm = glue_ctx._jvm
    props = jvm.java.util.Properties()
    props.setProperty("user", user)
    props.setProperty("password", password)
    # Driver is available in Glue runtime (you used org.postgresql.Driver already)
    jvm.java.lang.Class.forName("org.postgresql.Driver")
    return jvm.java.sql.DriverManager.getConnection(jdbc_url, props)


def ensure_audit_table(stmt):
    stmt.execute("CREATE SCHEMA IF NOT EXISTS audit")
    stmt.execute("""
      CREATE TABLE IF NOT EXISTS audit.sql_run_log (
        run_id TEXT NOT NULL,
        script_path TEXT NOT NULL,
        started_at TIMESTAMPTZ DEFAULT now(),
        finished_at TIMESTAMPTZ,
        status TEXT,
        error_message TEXT,
        rows_returned INT,
        PRIMARY KEY (run_id, script_path)
      )
    """)


def audit_start(stmt, run_id: str, script_path: str):
    stmt.execute(
        f"""
        INSERT INTO audit.sql_run_log(run_id, script_path, started_at, status)
        VALUES('{run_id}', '{script_path}', now(), 'RUNNING')
        ON CONFLICT (run_id, script_path) DO UPDATE
          SET started_at = EXCLUDED.started_at,
              status = 'RUNNING',
              error_message = NULL,
              finished_at = NULL,
              rows_returned = NULL
        """
    )


def audit_finish(stmt, run_id: str, script_path: str, status: str, rows_returned=None, error_message=None):
    err_sql = "NULL" if error_message is None else "'" + error_message.replace("'", "''")[:2000] + "'"
    rows_sql = "NULL" if rows_returned is None else str(int(rows_returned))
    stmt.execute(
        f"""
        UPDATE audit.sql_run_log
           SET finished_at = now(),
               status = '{status}',
               rows_returned = {rows_sql},
               error_message = {err_sql}
         WHERE run_id = '{run_id}'
           AND script_path = '{script_path}'
        """
    )


def main():
    args = getResolvedOptions(sys.argv, [
        "CONN_NAME",
        "DB_NAME",
        "SQL_S3_PREFIX",
        "MANIFEST_KEY",
        "RUN_ID"
    ])

    CONN_NAME = args["CONN_NAME"]
    DB_NAME = args["DB_NAME"]
    SQL_S3_PREFIX = args["SQL_S3_PREFIX"].rstrip("/") + "/"
    MANIFEST_KEY = args["MANIFEST_KEY"]
    RUN_ID = args["RUN_ID"]

    sc = SparkContext.getOrCreate()
    glue_ctx = GlueContext(sc)

    jdbc_url, user, password = get_jdbc_conf(glue_ctx, CONN_NAME, DB_NAME)
    logger.info(f"JDBC URL: {jdbc_url}")
    logger.info(f"S3 prefix: {SQL_S3_PREFIX}")
    logger.info(f"Manifest: {MANIFEST_KEY}")
    logger.info(f"RUN_ID: {RUN_ID}")

    manifest_uri = SQL_S3_PREFIX + MANIFEST_KEY
    manifest = json.loads(s3_read_text(manifest_uri))
    run_order = manifest.get("run_order", [])
    if not run_order:
        raise Exception("manifest.json run_order is empty")

    conn = jdbc_connect(glue_ctx, jdbc_url, user, password)
    conn.setAutoCommit(False)
    stmt = conn.createStatement()

    try:
        ensure_audit_table(stmt)
        conn.commit()

        for rel_path in run_order:
            script_uri = SQL_S3_PREFIX + rel_path
            logger.info(f"[RUN] {rel_path}")

            try:
                audit_start(stmt, RUN_ID, rel_path)
                conn.commit()
            except Exception:
                conn.rollback()

            sql_text = s3_read_text(script_uri).strip()

            try:
                if is_test_script(rel_path):
                    q = strip_trailing_semicolon(sql_text)
                    count_sql = f"SELECT COUNT(*) AS cnt FROM ({q}) t"
                    rs = stmt.executeQuery(count_sql)
                    rs.next()
                    cnt = rs.getLong("cnt")
                    rs.close()

                    if cnt > 0:
                        raise Exception(f"TEST FAILED: {rel_path} returned {cnt} rows")

                    audit_finish(stmt, RUN_ID, rel_path, "SUCCESS", rows_returned=0)
                    conn.commit()
                    logger.info(f"[OK] {rel_path} (0 rows)")

                else:
                    for s in split_sql_statements(sql_text):
                        stmt.execute(s)

                    audit_finish(stmt, RUN_ID, rel_path, "SUCCESS")
                    conn.commit()
                    logger.info(f"[OK] {rel_path}")

            except Exception as e:
                conn.rollback()
                err = str(e)
                logger.error(f"[FAIL] {rel_path} | {err}")
                try:
                    audit_finish(stmt, RUN_ID, rel_path, "FAILED", error_message=err)
                    conn.commit()
                except Exception:
                    conn.rollback()
                raise

        logger.info("Glue SQL Runner finished SUCCESS")

    finally:
        try:
            stmt.close()
        except Exception:
            pass
        conn.close()


if __name__ == "__main__":
    main()
