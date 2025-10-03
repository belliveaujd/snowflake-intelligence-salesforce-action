USE DATABASE CUR_SYNTHETIC_HEALTHCARE;
USE SCHEMA DEMO_ASSETS;
USE WAREHOUSE CURWH_HEALTHCARE_DEMO_SMALL;

-- Test 1: Test with new patients (should create new contacts)
SELECT 'Test 1: Creating new patients with unique patient IDs...' as test_status;

CALL SALESFORCE_CAMPAIGN_MANAGER(
    'Patient ID Test Campaign 20250930-1657',
    '[
        {
            "name": "Alex Thompson",
            "patient_id": 300001,
            "email": "alex.thompson.pid@healthcaretest.com"
        },
        {
            "name": "Beth Rodriguez",
            "patient_id": 300002,
            "email": "beth.rodriguez.pid@healthcaretest.com"
        }
    ]'
);

CALL SALESFORCE_CAMPAIGN_MANAGER(
    'Mixed Patient ID Test Campaign4',
    '[
        {
            "name": "Alex Thompson",
            "patient_id": 300001,
            "email": "alex.third@healthcaretest.com"
        },
        {
            "name": "Charlie Wilson",
            "patient_id": 300003,
            "email": "charlie.wilson.pid@healthcaretest.com"
        }
    ]'
);

-- Test 2: Test with same patient IDs but different emails (should find existing contacts)
SELECT 'Test 2: Using same patient IDs with different emails (should find existing)...' as test_status;

CALL SALESFORCE_CAMPAIGN_MANAGER(
    'Patient ID Lookup Test Campaign 2024',
    '[
        {
            "name": "Alex Thompson Updated",
            "patient_id": 300001,
            "email": "alex.new.email@healthcaretest.com"
        },
        {
            "name": "Beth Rodriguez Updated",
            "patient_id": 300002,
            "email": "beth.new.email@healthcaretest.com"
        }
    ]'
);

-- Test 3: Mix of existing and new patient IDs
SELECT 'Test 3: Mix of existing patient ID (300001) and new patient ID (300003)...' as test_status;

CALL SALESFORCE_CAMPAIGN_MANAGER(
    'Mixed Patient ID Test Campaign',
    '[
        {
            "name": "Alex Thompson Third Time",
            "patient_id": 300001,
            "email": "alex.third@healthcaretest.com"
        },
        {
            "name": "Charlie Wilson",
            "patient_id": 300003,
            "email": "charlie.wilson.pid@healthcaretest.com"
        }
    ]'
);

-- Test 4: Single patient with existing patient ID
SELECT 'Test 4: Single patient with existing patient ID (300002)...' as test_status;

CALL SALESFORCE_CAMPAIGN_MANAGER(
    'Single Existing Patient Test',
    '[
        {
            "name": "Beth Rodriguez Final",
            "patient_id": 300002,
            "email": "beth.final@healthcaretest.com"
        }
    ]'
);

-- Show completion
SELECT CURRENT_TIMESTAMP as patient_id_test_completed;

-- Summary message
SELECT 'Patient ID lookup tests completed. Check results above for CONTACTS_CREATED counts - should be 0 for existing patient IDs.' as summary;
