/*------------------------------------------------------------------------------
asset_name: master.seed_static_dimensions
author: Sathvik Musku
owner: data-platform
purpose: Seed static vendor and rate code dimensions
dependencies: master.dim_vendor, master.dim_rate_code
quality_expectations: deterministic mappings
------------------------------------------------------------------------------*/

-- Vendors
INSERT INTO master.dim_vendor (vendor_id, vendor_name)
VALUES
  (1, 'Creative Mobile Technologies, LLC'),
  (2, 'Curb Mobility, LLC'),
  (6, 'Myle Technologies Inc'),
  (7, 'Helix')
ON CONFLICT (vendor_id) DO UPDATE
SET vendor_name = EXCLUDED.vendor_name,
    updated_at = now();

-- Rate codes
INSERT INTO master.dim_rate_code (ratecodeid, rate_code_name, description)
VALUES
  (1, 'Standard rate', 'Standard rate'),
  (2, 'JFK', 'JFK'),
  (3, 'Newark', 'Newark'),
  (4, 'Nassau or Westchester', 'Nassau or Westchester'),
  (5, 'Negotiated fare', 'Negotiated fare'),
  (6, 'Group ride', 'Group ride'),
  (99, 'Null/unknown', 'Null or unknown')
ON CONFLICT (ratecodeid) DO UPDATE
SET rate_code_name = EXCLUDED.rate_code_name,
    description = EXCLUDED.description,
    updated_at = now();
