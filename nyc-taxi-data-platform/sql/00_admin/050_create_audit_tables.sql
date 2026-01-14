/*------------------------------------------------------------------------------
asset_name: audit.sql_run_log
author: Sathvik Musku
owner: data-platform
purpose: Track SQL workflow execution
dependencies: none
------------------------------------------------------------------------------*/

CREATE TABLE IF NOT EXISTS audit.sql_run_log (
  run_id TEXT NOT NULL,
  script_path TEXT NOT NULL,
  started_at TIMESTAMPTZ DEFAULT now(),
  finished_at TIMESTAMPTZ,
  status TEXT,
  error_message TEXT,
  rows_returned INT,
  PRIMARY KEY (run_id, script_path)
);
