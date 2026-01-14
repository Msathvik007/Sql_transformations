/*------------------------------------------------------------------------------
asset_name: test.time_order_good
author: Sathvik Musku
owner: data-platform
purpose: Ensure good trips have dropoff >= pickup
dependencies: curated.v_trips_good
expectation: returns 0 rows
------------------------------------------------------------------------------*/
SELECT
  tpep_pickup_datetime,
  tpep_dropoff_datetime
FROM curated.v_trips_good
WHERE tpep_pickup_datetime IS NOT NULL
  AND tpep_dropoff_datetime IS NOT NULL
  AND tpep_dropoff_datetime < tpep_pickup_datetime
LIMIT 50;
