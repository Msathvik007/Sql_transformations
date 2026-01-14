/*------------------------------------------------------------------------------
asset_name: curated.v_trips_base
author: Sathvik Musku
owner: data-platform
purpose: Base curated trips with derived metrics and DQ flags
dependencies: validated.yellow_trips
------------------------------------------------------------------------------*/

CREATE OR REPLACE VIEW curated.v_trips_base AS
SELECT
  t.*,

  EXTRACT(EPOCH FROM (t.tpep_dropoff_datetime - t.tpep_pickup_datetime)) / 60.0
    AS trip_duration_minutes,

  CASE WHEN t.fare_amount > 0
    THEN t.tip_amount / t.fare_amount
  END AS tip_rate,

  CASE
    WHEN t.tpep_dropoff_datetime < t.tpep_pickup_datetime THEN false
    ELSE true
  END AS dq_time_order_ok,

  CASE
    WHEN t.total_amount < 0
      OR t.fare_amount < 0
      OR t.tip_amount < 0
      OR t.tolls_amount < 0
    THEN false
    ELSE true
  END AS dq_amounts_non_negative

FROM validated.yellow_trips t;
