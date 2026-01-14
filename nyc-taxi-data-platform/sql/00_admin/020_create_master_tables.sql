/*------------------------------------------------------------------------------
asset_name: master.create_tables
author: Sathvik Musku
owner: data-platform
purpose: Create master dimension tables
dependencies: validated.taxi_zone_lookup
quality_expectations: primary keys enforced
------------------------------------------------------------------------------*/

-- Taxi Zone
CREATE TABLE IF NOT EXISTS master.dim_taxi_zone (
  location_id  INT PRIMARY KEY,
  borough      TEXT,
  zone         TEXT,
  service_zone TEXT,
  updated_at   TIMESTAMPTZ DEFAULT now()
);

-- Vendor
CREATE TABLE IF NOT EXISTS master.dim_vendor (
  vendor_id   INT PRIMARY KEY,
  vendor_name TEXT NOT NULL,
  updated_at  TIMESTAMPTZ DEFAULT now()
);

-- Rate Code
CREATE TABLE IF NOT EXISTS master.dim_rate_code (
  ratecodeid     INT PRIMARY KEY,
  rate_code_name TEXT NOT NULL,
  description    TEXT,
  updated_at     TIMESTAMPTZ DEFAULT now()
);
