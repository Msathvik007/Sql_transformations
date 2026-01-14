SELECT
  COUNT(*) AS total_good_rows,

  COUNT(*) FILTER (WHERE total_amount > 500) AS total_amount_gt_500,
  COUNT(*) FILTER (WHERE fare_amount > 300)  AS fare_amount_gt_300,
  COUNT(*) FILTER (WHERE tip_amount > 200)   AS tip_amount_gt_200,

  COUNT(*) FILTER (WHERE trip_distance > 100) AS distance_gt_100,
  COUNT(*) FILTER (WHERE trip_duration_minutes > 300) AS duration_gt_300_min
FROM curated.v_trips_good;
