
SELECT
  COUNT(*) AS total_rows,

  COUNT(*) FILTER (WHERE tpep_pickup_datetime IS NULL) AS null_pickup_dt,
  COUNT(*) FILTER (WHERE tpep_dropoff_datetime IS NULL) AS null_dropoff_dt,

  COUNT(*) FILTER (WHERE "PULocationID" IS NULL) AS null_pu_location,
  COUNT(*) FILTER (WHERE "DOLocationID" IS NULL) AS null_do_location,
  COUNT(*) FILTER (WHERE "VendorID" IS NULL) AS null_vendor_id,
  COUNT(*) FILTER (WHERE "RatecodeID" IS NULL) AS null_ratecode_id,
  COUNT(*) FILTER (WHERE payment_type IS NULL) AS null_payment_type,

  COUNT(*) FILTER (WHERE passenger_count < 0) AS neg_passenger_count,
  COUNT(*) FILTER (WHERE passenger_count > 9) AS passenger_count_gt_9,

  COUNT(*) FILTER (WHERE trip_distance < 0) AS neg_trip_distance,
  COUNT(*) FILTER (WHERE trip_distance > 200) AS trip_distance_gt_200,

  COUNT(*) FILTER (WHERE trip_duration_minutes < 0) AS neg_duration_min,
  COUNT(*) FILTER (WHERE trip_duration_minutes > 600) AS duration_gt_600_min
FROM curated.v_trips_base;
