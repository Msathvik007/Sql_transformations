/*------------------------------------------------------------------------------
asset_name: master.load_taxi_zone
author: Sathvik Musku
owner: data-platform
purpose: Populate master taxi zone from validated lookup
dependencies: validated.taxi_zone_lookup
quality_expectations: location_id unique
------------------------------------------------------------------------------*/

INSERT INTO master.dim_taxi_zone (location_id, borough, zone, service_zone)
SELECT
  location_id,
  NULLIF(TRIM(borough), ''),
  NULLIF(TRIM(zone_name), ''),
  NULLIF(TRIM(service_zone), '')
FROM validated.taxi_zone_lookup
WHERE location_id IS NOT NULL
ON CONFLICT (location_id) DO UPDATE
SET borough = EXCLUDED.borough,
    zone = EXCLUDED.zone,
    service_zone = EXCLUDED.service_zone,
    updated_at = now();
