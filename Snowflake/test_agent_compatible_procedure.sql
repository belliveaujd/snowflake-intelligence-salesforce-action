-- Test Script for Agent-Compatible Salesforce Campaign Manager
-- This tests the new SALESFORCE_CAMPAIGN_MANAGER procedure that accepts JSON string
--
-- Run this after deploying the procedure

-- Set context
USE DATABASE CUR_SYNTHETIC_HEALTHCARE;
USE SCHEMA DEMO_ASSETS;
USE WAREHOUSE CURWH_HEALTHCARE_DEMO_SMALL;

-- Test 1: Basic functionality test with 3 patients
SELECT 'Starting Test 1: Basic 3-patient campaign test...' as test_status;

CALL SALESFORCE_CAMPAIGN_MANAGER(
    'Healthcare Outreach Agent Test 2024',
    '[
        {
            "name": "Alice Johnson",
            "patient_id": 200001,
            "email": "alice.johnson.test@healthcareagent.com"
        },
        {
            "name": "Bob Wilson",
            "patient_id": 200002,
            "email": "bob.wilson.test@healthcareagent.com"
        },
        {
            "name": "Carol Davis",
            "patient_id": 200003,
            "email": "carol.davis.test@healthcareagent.com"
        }
    ]'
);

-- Test 2: Single patient test
SELECT 'Starting Test 2: Single patient test...' as test_status;

CALL SALESFORCE_CAMPAIGN_MANAGER(
    'Single Patient Campaign Test',
    '[
        {
            "name": "David Miller",
            "patient_id": 200004,
            "email": "david.miller.test@healthcareagent.com"
        }
    ]'
);

-- Test 3: Error handling - Invalid JSON
SELECT 'Starting Test 3: Invalid JSON error test...' as test_status;

CALL SALESFORCE_CAMPAIGN_MANAGER(
    'Error Test Campaign',
    '{"invalid": "json_structure"}'  -- This should fail
);

-- Test 4: Error handling - Missing required fields
SELECT 'Starting Test 4: Missing fields error test...' as test_status;

CALL SALESFORCE_CAMPAIGN_MANAGER(
    'Missing Fields Test Campaign',
    '[
        {
            "name": "Incomplete Patient"
        }
    ]'
);

-- Test 5: Larger batch test (5 patients)
SELECT 'Starting Test 5: Larger batch test with 5 patients...' as test_status;

CALL SALESFORCE_CAMPAIGN_MANAGER(
    'Large Batch Healthcare Campaign 2024',
    '[
        {
            "name": "Emma Thompson",
            "patient_id": 200005,
            "email": "emma.thompson.test@healthcareagent.com"
        },
        {
            "name": "Frank Rodriguez",
            "patient_id": 200006,
            "email": "frank.rodriguez.test@healthcareagent.com"
        },
        {
            "name": "Grace Kim",
            "patient_id": 200007,
            "email": "grace.kim.test@healthcareagent.com"
        },
        {
            "name": "Henry Chen",
            "patient_id": 200008,
            "email": "henry.chen.test@healthcareagent.com"
        },
        {
            "name": "Isabel Garcia",
            "patient_id": 200009,
            "email": "isabel.garcia.test@healthcareagent.com"
        }
    ]'
);

-- Show current time for test completion
SELECT CURRENT_TIMESTAMP as test_completed;

-- Optional: Query to check created campaigns (if you want to verify in Snowflake)
SELECT 'Test completed. Check Salesforce for created campaigns and contacts.' as final_message;
