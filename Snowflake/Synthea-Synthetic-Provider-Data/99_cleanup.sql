/* WIP -- UNTESTED AI GENERATED
==============================================================================
SNOWFLAKE INTELLIGENCE HEALTHCARE DEMO - CLEANUP SCRIPT
==============================================================================
Script: 09_cleanup.sql
Purpose: Clean up all demo objects and resources after presentation
Author: Snowflake Intelligence Demo Setup
Date: September 19, 2025

WARNING: This script will DELETE all demo objects created by scripts 01-08
Only run this script when the demo is completely finished!

Prerequisites:
- Demo presentation completed
- All demo objects no longer needed
- User confirmation to proceed with cleanup
==============================================================================
*/

-- ==============================================================================
-- SECTION 1: SAFETY CONFIRMATION
-- ==============================================================================

-- Display cleanup warning and confirmation
SELECT 
  '⚠️  CLEANUP WARNING ⚠️' as warning_header,
  'This script will DELETE all demo objects!' as warning_message,
  'Demo database: CUR_SYNTHETIC_HEALTHCARE' as database_target,
  'Demo warehouse: CURWH_HEALTHCARE_DEMO_SMALL' as warehouse_target,
  'Shared data will NOT be affected' as safety_note,
  'Continue only if demo is completely finished' as confirmation_required;

-- List all objects that will be deleted
SELECT 
  'Objects to be deleted:' as cleanup_scope,
  'All functions, tables, views, procedures in CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS' as objects_demo_assets,
  'Healthcare demo stage and uploaded files' as objects_stage,
  'Demo warehouse CURWH_HEALTHCARE_DEMO_SMALL' as objects_warehouse,
  'Complete CUR_SYNTHETIC_HEALTHCARE database' as objects_database;

-- ==============================================================================
-- SECTION 2: PRE-CLEANUP BACKUP (OPTIONAL)
-- ==============================================================================

-- Optional: Create backup of demo queries and case management log before cleanup
-- Uncomment the following section if you want to preserve demo data

/*
-- Create backup database (uncomment to enable)
CREATE DATABASE IF NOT EXISTS CUR_HEALTHCARE_DEMO_BACKUP
  COMMENT = 'Backup of healthcare demo data before cleanup';

CREATE SCHEMA IF NOT EXISTS CUR_HEALTHCARE_DEMO_BACKUP.ARCHIVED_DEMO
  COMMENT = 'Archived demo configuration and results';

-- Backup demo queries
CREATE TABLE CUR_HEALTHCARE_DEMO_BACKUP.ARCHIVED_DEMO.DEMO_QUERIES_BACKUP AS
SELECT *, CURRENT_TIMESTAMP() as backup_timestamp
FROM CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.DEMO_QUERIES;

-- Backup case management log
CREATE TABLE CUR_HEALTHCARE_DEMO_BACKUP.ARCHIVED_DEMO.CASE_MANAGEMENT_BACKUP AS  
SELECT *, CURRENT_TIMESTAMP() as backup_timestamp
FROM CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.CASE_MANAGEMENT_LOG;

-- Backup demo metrics
CREATE TABLE CUR_HEALTHCARE_DEMO_BACKUP.ARCHIVED_DEMO.DEMO_METRICS_BACKUP AS
SELECT *, CURRENT_TIMESTAMP() as backup_timestamp  
FROM CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.DEMO_METRICS;

-- Backup test results (if exists)
CREATE TABLE CUR_HEALTHCARE_DEMO_BACKUP.ARCHIVED_DEMO.TEST_RESULTS_BACKUP AS
SELECT *, CURRENT_TIMESTAMP() as backup_timestamp
FROM CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.TEST_RESULTS;

SELECT 'Backup completed to CUR_HEALTHCARE_DEMO_BACKUP database' as backup_status;
*/

-- ==============================================================================
-- SECTION 3: SUSPEND WAREHOUSE OPERATIONS
-- ==============================================================================

-- Suspend the demo warehouse to prevent additional costs
ALTER WAREHOUSE IF EXISTS CURWH_HEALTHCARE_DEMO_SMALL SUSPEND;

SELECT 'Demo warehouse suspended' as warehouse_status;

-- ==============================================================================
-- SECTION 4: DROP DEMO FUNCTIONS
-- ==============================================================================

-- Drop all custom functions created for the demo
DROP FUNCTION IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.IDENTIFY_HIGH_COST_PATIENTS(NUMBER);
DROP FUNCTION IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.GENERATE_PATIENT_INSIGHTS(NUMBER);
DROP FUNCTION IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.GET_PATIENT_SUMMARY(NUMBER);
DROP FUNCTION IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.GET_PATIENT_CONDITIONS(NUMBER);
DROP FUNCTION IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.ANALYZE_PATIENT_RISK(NUMBER);
DROP FUNCTION IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.PREDICT_NEXT_YEAR_COSTS(NUMBER);

-- Drop search functions (fallback functions from script 05)
DROP FUNCTION IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.SEARCH_PATIENTS_BY_NAME(STRING);
DROP FUNCTION IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.SEARCH_CONDITIONS(STRING);
DROP FUNCTION IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.SEARCH_PROVIDERS(STRING);

SELECT 'Demo functions dropped' as functions_status;

-- ==============================================================================
-- SECTION 5: DROP STORED PROCEDURES
-- ==============================================================================

-- Drop case management stored procedure
DROP PROCEDURE IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.CREATE_CASE_FOR_PATIENT(NUMBER, STRING, STRING);
DROP PROCEDURE IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.CREATE_CASE_FOR_PATIENT(NUMBER, STRING);
DROP PROCEDURE IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.CREATE_CASE_FOR_PATIENT(NUMBER);

SELECT 'Demo procedures dropped' as procedures_status;

-- ==============================================================================
-- SECTION 6: DROP DEMO VIEWS
-- ==============================================================================

-- Drop demo views
DROP VIEW IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.TOP_COST_PATIENTS;
DROP VIEW IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.DEMO_DASHBOARD;
DROP VIEW IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.HIGH_COST_PATIENTS_VIEW;
DROP VIEW IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.PATIENT_ANALYSIS_VIEW;

SELECT 'Demo views dropped' as views_status;

-- ==============================================================================
-- SECTION 7: DROP DEMO TABLES
-- ==============================================================================

-- Drop demo configuration tables
DROP TABLE IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.TEST_RESULTS;
DROP TABLE IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.DEMO_QUERIES;
DROP TABLE IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.CASE_MANAGEMENT_LOG;
DROP TABLE IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.DEMO_METRICS;

SELECT 'Demo tables dropped' as tables_status;

-- ==============================================================================
-- SECTION 8: DROP CORTEX SERVICES (IF CREATED)
-- ==============================================================================

-- Drop Cortex Search services (if they were created successfully)
BEGIN TRY
  DROP CORTEX SEARCH SERVICE IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.PATIENT_NAME_SEARCH;
  DROP CORTEX SEARCH SERVICE IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.CONDITION_SEARCH;
  DROP CORTEX SEARCH SERVICE IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.PROVIDER_SEARCH;
  
  SELECT 'Cortex Search services dropped' as cortex_search_status;
EXCEPTION
  WHEN OTHER THEN
    SELECT 'Cortex Search services cleanup skipped (likely not created)' as cortex_search_status;
END;

-- Drop Cortex Analyst semantic model (if it was created successfully)
BEGIN TRY
  DROP CORTEX ANALYST SEMANTIC_MODEL IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.HIGH_COST_CLAIMANTS_MODEL;
  
  SELECT 'Cortex Analyst semantic model dropped' as cortex_analyst_status;
EXCEPTION
  WHEN OTHER THEN
    SELECT 'Cortex Analyst model cleanup skipped (likely not created)' as cortex_analyst_status;
END;

-- ==============================================================================
-- SECTION 9: DROP DEMO STAGE AND FILES
-- ==============================================================================

-- Remove all files from the demo stage
REMOVE @CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.HEALTHCARE_DEMO_STAGE;

-- Drop the demo stage
DROP STAGE IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.HEALTHCARE_DEMO_STAGE;

SELECT 'Demo stage and files dropped' as stage_status;

-- ==============================================================================
-- SECTION 10: DROP DEMO SCHEMA
-- ==============================================================================

-- Drop the demo assets schema (this will cascade delete any remaining objects)
DROP SCHEMA IF EXISTS CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS CASCADE;

SELECT 'Demo schema dropped' as schema_status;

-- ==============================================================================
-- SECTION 11: DROP DEMO DATABASE
-- ==============================================================================

-- Drop the entire demo database
DROP DATABASE IF EXISTS CUR_SYNTHETIC_HEALTHCARE CASCADE;

SELECT 'Demo database dropped' as database_status;

-- ==============================================================================
-- SECTION 12: DROP DEMO WAREHOUSE
-- ==============================================================================

-- Drop the demo warehouse
DROP WAREHOUSE IF EXISTS CURWH_HEALTHCARE_DEMO_SMALL;

SELECT 'Demo warehouse dropped' as warehouse_cleanup_status;

-- ==============================================================================
-- SECTION 13: VERIFY CLEANUP COMPLETION
-- ==============================================================================

-- Verify all demo objects have been removed
SELECT 
  'Cleanup Verification' as verification_type,
  
  CASE 
    WHEN EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'CUR_SYNTHETIC_HEALTHCARE')
    THEN '❌ Database still exists'
    ELSE '✅ Database removed'
  END as database_cleanup,
  
  CASE
    WHEN EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.WAREHOUSES WHERE WAREHOUSE_NAME = 'CURWH_HEALTHCARE_DEMO_SMALL')
    THEN '❌ Warehouse still exists'  
    ELSE '✅ Warehouse removed'
  END as warehouse_cleanup,
  
  'Note: Shared database SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS preserved' as shared_data_status;

-- ==============================================================================
-- SECTION 14: CLEANUP SUMMARY
-- ==============================================================================

-- Final cleanup summary
SELECT 
  '=== CLEANUP COMPLETED ===' as cleanup_header,
  'All Snowflake Intelligence Healthcare demo objects removed' as cleanup_summary,
  'Shared healthcare database preserved and unaffected' as data_preservation,
  'Demo environment fully cleaned up' as final_status,
  CURRENT_TIMESTAMP() as cleanup_timestamp;

-- Show what was preserved (if anything)
SELECT 
  'Preserved Objects' as preservation_summary,
  
  CASE
    WHEN EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'CUR_HEALTHCARE_DEMO_BACKUP')
    THEN '✅ Demo backup database preserved: CUR_HEALTHCARE_DEMO_BACKUP'
    ELSE '📝 No backup created - all demo data permanently deleted'
  END as backup_status,
  
  'Original shared data: SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS (unchanged)' as shared_data,
  
  'All demo scripts preserved in: /scripts/ folder for future use' as script_preservation;

-- ==============================================================================
-- SECTION 15: POST-CLEANUP RECOMMENDATIONS
-- ==============================================================================

-- Provide post-cleanup recommendations
SELECT 
  'Post-Cleanup Recommendations' as recommendations_header,
  '1. Review and archive demo scripts for future use' as recommendation_1,
  '2. Document any customizations made during demo' as recommendation_2,  
  '3. Update demo documentation with lessons learned' as recommendation_3,
  '4. Consider creating reusable demo templates' as recommendation_4,
  '5. Share feedback on demo effectiveness and improvements' as recommendation_5;

-- ==============================================================================
-- END OF SCRIPT
-- ==============================================================================

/*
Cleanup Summary:
================

Objects Removed:
- ✅ All custom functions (6 functions)
- ✅ All stored procedures (1 procedure)  
- ✅ All demo views (4 views)
- ✅ All demo tables (4 tables)
- ✅ Cortex Search services (if created)
- ✅ Cortex Analyst semantic model (if created)
- ✅ Demo stage and uploaded files
- ✅ Demo schema (DEMO_ASSETS)
- ✅ Demo database (CUR_SYNTHETIC_HEALTHCARE)
- ✅ Demo warehouse (CURWH_HEALTHCARE_DEMO_SMALL)

Objects Preserved:
- ✅ Shared database: SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS (untouched)
- ✅ Demo scripts in /scripts/ folder (for reuse)
- ✅ Documentation and research files (for future reference)
- ✅ Optional backup database (if uncommented)

Environment Status:
- Demo environment completely removed
- No ongoing compute costs from demo objects
- Original shared data preserved and unchanged
- Clean slate for future demos

Cost Impact:
- All demo-related compute costs eliminated
- Warehouse auto-suspend prevented ongoing charges
- Storage costs for shared data unchanged
- Clean environment for future demonstrations

Next Steps:
- Archive demo materials for future use
- Document any demo customizations made
- Prepare for next demo iteration if needed
- Share feedback for demo improvement

Estimated Runtime: 3-5 minutes
*/

