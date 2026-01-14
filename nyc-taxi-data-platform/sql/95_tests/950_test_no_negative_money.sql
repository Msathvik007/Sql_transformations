/*------------------------------------------------------------------------------
asset_name: test.no_negative_money
author: Sathvik Musku
owner: data-platform
purpose: Fail if curated good contains negative amounts
expectation: returns 0 rows
------------------------------------------------------------------------------*/

SELECT *
FROM curated.v_trips_good
WHERE total_amount < 0
   OR fare_amount < 0
   OR tip_amount < 0
LIMIT 10;
