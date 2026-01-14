/*------------------------------------------------------------------------------
asset_name: dq.trips_summary
author: Sathvik Musku
owner: data-platform
purpose: Data quality summary metrics
dependencies: curated.v_trips_base
------------------------------------------------------------------------------*/

SELECT
  COUNT(*) AS total_rows,
  COUNT(*) FILTER (WHERE dq_time_order_ok = false) AS bad_time_order,
  COUNT(*) FILTER (WHERE dq_amounts_non_negative = false) AS bad_amounts
FROM curated.v_trips_base;
