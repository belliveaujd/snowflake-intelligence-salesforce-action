/*
==============================================================================
SNOWFLAKE INTELLIGENCE HEALTHCARE DEMO - CORTEX SEARCH SETUP (FIXED)
==============================================================================
Script: 05_cortex_search_setup_fixed.sql
Purpose: Create Cortex Search services with proper containment and local tables
Author: Snowflake Intelligence Demo Setup  
Date: September 19, 2025

CRITICAL FIX APPLIED:
- Uses fully qualified names for proper demo containment
- Creates local tables to avoid shared database change tracking restrictions
- Ensures all objects are created in CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS

==============================================================================
*/

-- ==============================================================================
-- SECTION 1: SET CONTEXT WITH FULLY QUALIFIED NAMES
-- ==============================================================================

-- CRITICAL: Set proper context to ensure containment
USE WAREHOUSE CURWH_HEALTHCARE_DEMO_SMALL;
USE DATABASE CUR_SYNTHETIC_HEALTHCARE;
USE SCHEMA DEMO_ASSETS;


-- ==============================================================================
-- SECTION 2: CREATE LOCAL TABLES (SHARED DATABASE WORKAROUND)
-- ==============================================================================

-- CRITICAL: Create local tables with fully qualified names to avoid shared database restrictions
-- Cortex Search requires change tracking which isn't available on shared databases

--SELECT TOP 1 * FROM SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS.SILVER.PATIENTS;

-- Cortex Search Services

-- Create full patient dataset (1.42M records)
CREATE OR REPLACE TABLE CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.PATIENTS_FULL_SCALE
COMMENT = 'LINEAGE: Full clone from SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS.SILVER.PATIENTS'
AS SELECT * FROM SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS.SILVER.PATIENTS;

-- Create optimized search table for high-cost patients  
CREATE OR REPLACE TABLE CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.PATIENT_SEARCH_OPTIMIZED
COMMENT = 'LINEAGE: Optimized search table derived from PATIENTS_FULL_SCALE (1.21M high-cost patients)'
AS
SELECT
  PATIENT_ID,
  FIRST || ' ' || LAST as FULL_NAME,
  FIRST, LAST, CITY, STATE, BIRTHDATE,
  DATEDIFF('year', BIRTHDATE, '2024-09-19'::DATE) as AGE,
  HEALTHCARE_EXPENSES, HEALTHCARE_COVERAGE,
  (HEALTHCARE_EXPENSES + HEALTHCARE_COVERAGE) as TOTAL_COST,
  CASE
    WHEN (HEALTHCARE_EXPENSES + HEALTHCARE_COVERAGE) > 2000000 THEN 'ULTRA-HIGH'
    WHEN (HEALTHCARE_EXPENSES + HEALTHCARE_COVERAGE) > 1000000 THEN 'MILLION+'
    WHEN (HEALTHCARE_EXPENSES + HEALTHCARE_COVERAGE) > 500000 THEN 'CRITICAL'
    WHEN (HEALTHCARE_EXPENSES + HEALTHCARE_COVERAGE) > 100000 THEN 'HIGH'
    ELSE 'MODERATE'
  END as COST_CATEGORY,
  FIRST || ' ' || LAST || ' ' || CITY || ' ' || STATE as SEARCH_TEXT,
  PREFIX || ' ' || FIRST || ' ' || LAST || ' ' || SUFFIX as FULL_DISPLAY_NAME
FROM CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.PATIENTS_FULL_SCALE
WHERE (HEALTHCARE_EXPENSES + HEALTHCARE_COVERAGE) > 50000;


-- 3.2 Cortex Search Services
-- Search Service 1: High-Cost Patients (1.21M records)
CREATE CORTEX SEARCH SERVICE CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.PATIENT_SEARCH_FULL_SCALE
ON SEARCH_TEXT
ATTRIBUTES PATIENT_ID, FULL_NAME, CITY, STATE, TOTAL_COST, COST_CATEGORY, AGE
WAREHOUSE = CURWH_HEALTHCARE_DEMO_SMALL
TARGET_LAG = '30 days'
COMMENT = 'Full-scale patient search on high-cost patients'
AS (
  SELECT PATIENT_ID, SEARCH_TEXT, FULL_NAME, CITY, STATE, TOTAL_COST, COST_CATEGORY, AGE
  FROM CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.PATIENT_SEARCH_OPTIMIZED
);

-- Search Service 2: Maximum Scale (1.42M records)  
CREATE CORTEX SEARCH SERVICE CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.PATIENT_SEARCH_MAXIMUM_SCALE
ON SEARCH_TEXT
ATTRIBUTES PATIENT_ID, FULL_NAME, CITY, STATE, TOTAL_COST, COST_CATEGORY, AGE, GENDER
WAREHOUSE = CURWH_HEALTHCARE_DEMO_SMALL
TARGET_LAG = '30 days'
COMMENT = 'Maximum scale search across all patients'
AS (
  SELECT 
    PATIENT_ID, SEARCH_TEXT, FULL_NAME, CITY, STATE, TOTAL_COST, COST_CATEGORY, AGE, GENDER
  FROM CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.PATIENT_SEARCH_OPTIMIZED
  UNION ALL
  SELECT
    PATIENT_ID,
    FIRST || ' ' || LAST || ' ' || CITY || ' ' || STATE as SEARCH_TEXT,
    FIRST || ' ' || LAST as FULL_NAME,
    CITY, STATE,
    HEALTHCARE_EXPENSES + HEALTHCARE_COVERAGE as TOTAL_COST,
    'LOW' as COST_CATEGORY,
    DATEDIFF('year', BIRTHDATE, '2024-09-19'::DATE) as AGE,
    GENDER
  FROM CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.PATIENTS_FULL_SCALE
  WHERE (HEALTHCARE_EXPENSES + HEALTHCARE_COVERAGE) <= 50000
);


