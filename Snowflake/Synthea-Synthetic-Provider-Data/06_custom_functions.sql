/*
==============================================================================
SNOWFLAKE INTELLIGENCE HEALTHCARE DEMO - CUSTOM FUNCTIONS
==============================================================================
Script: 06_custom_functions.sql
Purpose: Create custom functions for healthcare analysis and AI insights
Author: Snowflake Intelligence Demo Setup
Date: September 19, 2025

Prerequisites:
- Script 01_infrastructure_setup.sql completed successfully
- Script 02_data_verification.sql completed successfully
- Script 03_yaml_upload.sql completed successfully
- Script 04_cortex_analyst_setup.sql completed successfully  
- Script 05_cortex_search_setup.sql completed successfully
- Cortex Complete feature available
==============================================================================
*/

-- ==============================================================================
-- SECTION 1: SET CONTEXT
-- ==============================================================================

-- Ensure we're in the correct context
USE WAREHOUSE CURWH_HEALTHCARE_DEMO_SMALL;
USE DATABASE CUR_SYNTHETIC_HEALTHCARE;
USE SCHEMA DEMO_ASSETS;


-- ==============================================================================
-- SECTION 3: AI-POWERED PATIENT INSIGHTS FUNCTION
-- ==============================================================================

-- Create function that generates AI insights using Cortex Complete
CREATE OR REPLACE FUNCTION GENERATE_PATIENT_INSIGHTS(PATIENT_ID NUMBER)
RETURNS STRING
LANGUAGE SQL
COMMENT = 'Generates AI-powered care management insights using Cortex Complete'
AS
$$
  SELECT SNOWFLAKE.CORTEX.COMPLETE(
    'snowflake-arctic',
    'Analyze this healthcare patient data and provide care management insights: Patient ' || 
    p.FIRST || ' ' || p.LAST || 
    ', Age ' || DATEDIFF('year', p.BIRTHDATE, CURRENT_DATE()) || 
    ', Total Healthcare Costs: $' || TO_CHAR(p.HEALTHCARE_EXPENSES + p.HEALTHCARE_COVERAGE, '999,999,999') ||
    ', Gender: ' || p.GENDER || 
    '. Provide 3 specific recommendations for care management and cost reduction.'
  )
  FROM SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS.SILVER.PATIENTS p 
  WHERE p.PATIENT_ID = PATIENT_ID
$$;

-- ==============================================================================
-- SECTION 4: PATIENT SUMMARY FUNCTION
-- ==============================================================================
-- Create comprehensive patient summary function
CREATE OR REPLACE FUNCTION GET_PATIENT_SUMMARY(INPUT_PATIENT_ID NUMBER)  
RETURNS STRING
LANGUAGE SQL
COMMENT = 'Returns formatted patient profile with key metrics and demographics'
AS
$$
  SELECT 
    'PATIENT PROFILE' || CHR(10) ||
    '================' || CHR(10) ||
    'Name: ' || p.FIRST || ' ' || p.LAST || CHR(10) ||
    'Age: ' || DATEDIFF('year', p.BIRTHDATE, CURRENT_DATE()) || ' years' || CHR(10) ||
    'Gender: ' || p.GENDER || CHR(10) ||
    'City: ' || p.CITY || ', ' || p.STATE || CHR(10) ||
    'Total Healthcare Costs: $' || TO_CHAR(p.HEALTHCARE_EXPENSES + p.HEALTHCARE_COVERAGE, '999,999,999') || CHR(10) ||
    'Patient Costs: $' || TO_CHAR(p.HEALTHCARE_EXPENSES, '999,999,999') || CHR(10) ||
    'Insurance Coverage: $' || TO_CHAR(p.HEALTHCARE_COVERAGE, '999,999,999') || CHR(10) ||
    'Encounters: ' || COALESCE(e.encounter_count, 0) || CHR(10) ||
    'Active Conditions: ' || COALESCE(c.condition_count, 0) || CHR(10) ||
    'Risk Level: ' || CASE 
      WHEN (p.HEALTHCARE_EXPENSES + p.HEALTHCARE_COVERAGE) > 1000000 THEN 'MILLION+'
      WHEN (p.HEALTHCARE_EXPENSES + p.HEALTHCARE_COVERAGE) > 500000 THEN 'CRITICAL'
      WHEN (p.HEALTHCARE_EXPENSES + p.HEALTHCARE_COVERAGE) > 100000 THEN 'HIGH'
      ELSE 'MODERATE'
    END
  FROM SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS.SILVER.PATIENTS p
  LEFT JOIN (
    SELECT PATIENT_ID, COUNT(*) as encounter_count 
    FROM SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS.SILVER.ENCOUNTERS 
    GROUP BY PATIENT_ID
  ) e ON p.PATIENT_ID = e.PATIENT_ID
  LEFT JOIN (
    SELECT PATIENT_ID, COUNT(DISTINCT CONDITION_ID) as condition_count
    FROM SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS.SILVER.CONDITIONS
    GROUP BY PATIENT_ID  
  ) c ON p.PATIENT_ID = c.PATIENT_ID
  WHERE p.PATIENT_ID = INPUT_PATIENT_ID
$$;

-- ==============================================================================
-- SECTION 5: PATIENT CONDITIONS FUNCTION
-- ==============================================================================
-- Create function to get patient conditions list
CREATE OR REPLACE FUNCTION GET_PATIENT_CONDITIONS(PATIENT_ID NUMBER)
RETURNS STRING
LANGUAGE SQL
COMMENT = 'Returns semicolon-separated list of all patient conditions'
AS
$$
  SELECT 
    LISTAGG(DISTINCT c.DESCRIPTION, '; ') WITHIN GROUP (ORDER BY c.DESCRIPTION)
  FROM SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS.SILVER.CONDITIONS c
  WHERE c.PATIENT_ID = PATIENT_ID
$$;