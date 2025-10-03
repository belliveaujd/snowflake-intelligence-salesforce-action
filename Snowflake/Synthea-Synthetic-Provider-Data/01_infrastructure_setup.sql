/*
==============================================================================
SNOWFLAKE INTELLIGENCE HEALTHCARE DEMO - INFRASTRUCTURE SETUP
==============================================================================
Script: 01_infrastructure_setup.sql
Purpose: Create warehouse, database, and schema infrastructure for the demo
Author: Snowflake Intelligence Demo Setup
Date: September 19, 2025

Prerequisites:
- Snowflake account with appropriate privileges
- Access to create warehouses and databases
- Demo admin keypair connection configured
==============================================================================
*/

-- ==============================================================================
-- SECTION 1: CREATE DEMO WAREHOUSE
-- ==============================================================================

-- Create demo warehouse for healthcare analytics
-- Small size with auto-suspend for cost optimization
CREATE WAREHOUSE IF NOT EXISTS CURWH_HEALTHCARE_DEMO_SMALL WITH
  WAREHOUSE_SIZE = 'SMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Demo warehouse for Healthcare High-Cost Claimants analysis';

-- ==============================================================================
-- SECTION 2: CREATE DEMO DATABASE AND SCHEMA  
-- ==============================================================================

-- Create demo database for our objects (shared data remains in original location)
CREATE DATABASE IF NOT EXISTS CUR_SYNTHETIC_HEALTHCARE 
  COMMENT = 'Demo database for Synthetic Healthcare High-Cost Claimants analysis objects';

-- Create schema for demo objects
CREATE SCHEMA IF NOT EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS
  COMMENT = 'Schema for healthcare demo configuration files and objects';

-- ==============================================================================
-- SECTION 3: SET CONTEXT FOR SUBSEQUENT SCRIPTS
-- ==============================================================================

-- Set context for all subsequent setup scripts
USE WAREHOUSE CURWH_HEALTHCARE_DEMO_SMALL;
USE DATABASE CUR_SYNTHETIC_HEALTHCARE;
USE SCHEMA DEMO_ASSETS;

-- ==============================================================================
-- SECTION 4: VERIFICATION
-- ==============================================================================

-- Verify infrastructure creation
SELECT 
  'Infrastructure Setup Complete' as status,
  CURRENT_WAREHOUSE() as current_warehouse,
  CURRENT_DATABASE() as current_database, 
  CURRENT_SCHEMA() as current_schema,
  CURRENT_TIMESTAMP() as setup_timestamp;

-- Verify warehouse properties
SHOW WAREHOUSES LIKE 'CURWH_HEALTHCARE_DEMO_SMALL';

-- Verify database and schema creation
SHOW DATABASES LIKE 'CUR_SYNTHETIC_HEALTHCARE';
SHOW SCHEMAS IN DATABASE CUR_SYNTHETIC_HEALTHCARE;


/* Synthea Synthetic Healthcare Data 
- Access to SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS database
- Get the Data from the Marketplace:
  - https://app.snowflake.com/marketplace/listing/GZSTZL7M0Q6/snowflake-virtual-hands-on-labs-synthetic-healthcare-data-clinical-and-claims?sortBy=popular
- Install with the name: SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS (I believe that's the default)
- Appropriate read permissions on shared database
*/

==============================================================================
-- ==============================================================================
-- END OF SCRIPT
-- ==============================================================================

/*
Next Steps:
- Run script 02_data_verification.sql to verify access to shared healthcare data
- Ensure warehouse is properly sized for your environment
- Confirm all objects were created successfully

Estimated Runtime: < 1 minute
*/

