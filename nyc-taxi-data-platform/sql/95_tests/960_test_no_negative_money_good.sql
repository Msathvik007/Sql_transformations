/*------------------------------------------------------------------------------
asset_name: test.no_negative_money_good
author: Sathvik Musku
owner: data-platform
purpose: Ensure good trips contain no negative monetary fields
dependencies: curated.v_trips_good
expectation: returns 0 rows
------------------------------------------------------------------------------*/
SELECT
  total_amount, fare_amount, tip_amount, tolls_amount, mta_tax, extra,
  improvement_surcharge, congestion_surcharge, "Airport_fee", cbd_congestion_fee
FROM curated.v_trips_good
WHERE total_amount < 0
   OR fare_amount < 0
   OR tip_amount < 0
   OR tolls_amount < 0
   OR COALESCE(mta_tax,0) < 0
   OR COALESCE(extra,0) < 0
   OR COALESCE(improvement_surcharge,0) < 0
   OR COALESCE(congestion_surcharge,0) < 0
   OR COALESCE("Airport_fee",0) < 0
   OR COALESCE(cbd_congestion_fee,0) < 0
LIMIT 50;
