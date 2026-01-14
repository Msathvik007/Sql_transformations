/*------------------------------------------------------------------------------
asset_name: admin.create_schemas
author: Sathvik Musku
owner: data-platform
purpose: Create core schemas for data platform
dependencies: none
quality_expectations: schemas exist idempotently
------------------------------------------------------------------------------*/

CREATE SCHEMA IF NOT EXISTS validated;
CREATE SCHEMA IF NOT EXISTS master;
CREATE SCHEMA IF NOT EXISTS curated;
CREATE SCHEMA IF NOT EXISTS audit;
