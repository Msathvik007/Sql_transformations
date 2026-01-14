/*------------------------------------------------------------------------------
asset_name: curated.v_trips_enriched_good
author: Sathvik Musku
owner: analytics
purpose: Enriched curated trips for BI
dependencies:
  - curated.v_trips_good
  - master.dim_taxi_zone
  - master.dim_vendor
  - master.dim_rate_code
------------------------------------------------------------------------------*/

CREATE OR REPLACE VIEW curated.v_trips_good AS
SELECT *
FROM curated.v_trips_base
WHERE dq_time_order_ok = true
  AND dq_amounts_non_negative = true;
