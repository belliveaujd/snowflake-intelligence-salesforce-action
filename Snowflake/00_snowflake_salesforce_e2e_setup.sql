use database cur_synthetic_healthcare;
use schema demo_assets;
use warehouse curwh_healthcare_demo_small;

-- Create secret for Salesforce Client ID (Consumer Key)
CREATE OR REPLACE SECRET salesforce_client_id
TYPE = GENERIC_STRING
SECRET_STRING = "CLIENT ID HERE";

-- Create secret for Salesforce Client Secret (Consumer Secret)
CREATE OR REPLACE SECRET salesforce_client_secret
TYPE = GENERIC_STRING
SECRET_STRING = "SECRET HERE";

-- Create secret for Salesforce Instance URL
CREATE OR REPLACE SECRET salesforce_instance_url
TYPE = GENERIC_STRING
SECRET_STRING = "https://orgfarm-6359004976-dev-ed.develop.my.salesforce.com";

-- For development/testing (broader access)
GRANT USAGE ON SECRET salesforce_client_id TO ROLE sysadmin;
GRANT USAGE ON SECRET salesforce_client_secret TO ROLE sysadmin;
GRANT USAGE ON SECRET salesforce_instance_url TO ROLE sysadmin;
GRANT USAGE ON SECRET salesforce_client_id TO ROLE accountadmin;
GRANT USAGE ON SECRET salesforce_client_secret TO ROLE accountadmin;
GRANT USAGE ON SECRET salesforce_instance_url TO ROLE accountadmin;

-- For production (specific integration role - RECOMMENDED)
-- CREATE ROLE IF NOT EXISTS salesforce_integration_role;
-- GRANT USAGE ON SECRET salesforce_client_id TO ROLE salesforce_integration_role;
-- GRANT USAGE ON SECRET salesforce_client_secret TO ROLE salesforce_integration_role;
-- GRANT USAGE ON SECRET salesforce_instance_url TO ROLE salesforce_integration_role;



-- Create network rule for Salesforce domains
CREATE OR REPLACE NETWORK RULE salesforce_network_rule
MODE = EGRESS
TYPE = HOST_PORT
VALUE_LIST = (
    '*.salesforce.com:443', 
    '*.force.com:443', 
    'login.salesforce.com:443',
    '*.develop.my.salesforce.com:443',
    '*.my.salesforce.com:443'
);

/*
ALTER NETWORK RULE salesforce_network_rule
SET VALUE_LIST = (
    '*.salesforce.com:443', 
    '*.force.com:443', 
    'login.salesforce.com:443',
    '*.develop.my.salesforce.com:443',
    '*.my.salesforce.com:443'
);
*/

-- Create external access integration
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION salesforce_synthea_integration_jdb
ALLOWED_NETWORK_RULES = (salesforce_network_rule)
ENABLED = true;

ALTER EXTERNAL ACCESS INTEGRATION salesforce_synthea_integration_jdb
SET ALLOWED_AUTHENTICATION_SECRETS = (
    'CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.salesforce_client_id',
    'CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.salesforce_client_secret',
    'CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.salesforce_instance_url'
);

-- Grant usage to appropriate roles
GRANT USAGE ON INTEGRATION salesforce_synthea_integration_jdb TO ROLE sysadmin;
GRANT USAGE ON INTEGRATION salesforce_synthea_integration_jdb TO ROLE accountadmin;
-- GRANT USAGE ON INTEGRATION SALESFORCE_SYNTHEA_INTEGRATION_JDB TO ROLE your_integration_role;


-- STEP 4
-- List Integrations
SHOW INTEGRATIONS LIKE 'SALESFORCE%';
SHOW EXTERNAL ACCESS INTEGRATIONS LIKE 'SALESFORCE%';
DESCRIBE INTEGRATION SALESFORCE_SYNTHEA_INTEGRATION_JDB;
-- Note the 'owner' column in the result.

-- List all secrets
SHOW SECRETS;

-- Check specific secret metadata (does not show actual values)
DESC SECRET salesforce_client_id;
DESC SECRET salesforce_client_secret;
DESC SECRET salesforce_instance_url;



-- Snowflake-Salesforce Integration: Agent-Compatible Stored Procedure
-- Compatible with Snowflake Agents (string parameters only)
--
-- This procedure accepts a JSON string for patient data instead of an array,
-- making it compatible with Snowflake Agent tools which only support:
-- "string", "integer", "number", "boolean" parameter types

-- Usage Example:
-- CALL SALESFORCE_CAMPAIGN_MANAGER(
--   'Healthcare Outreach 2024',
--   '[
--     {"name": "John Doe", "patient_id": 100001, "email": "john.doe@email.com"},
--     {"name": "Jane Smith", "patient_id": 100002, "email": "jane.smith@email.com"},
--     {"name": "Bob Johnson", "patient_id": 100003, "email": "bob.johnson@email.com"}
--   ]'
-- );

CREATE OR REPLACE PROCEDURE SALESFORCE_CAMPAIGN_MANAGER(
    CAMPAIGN_NAME STRING,
    PATIENTS_JSON STRING
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests', 'snowflake-snowpark-python')
HANDLER = 'main'
EXTERNAL_ACCESS_INTEGRATIONS = (SALESFORCE_SYNTHEA_INTEGRATION_JDB)
SECRETS = (
    'salesforce_client_id' = SALESFORCE_CLIENT_ID,
    'salesforce_client_secret' = SALESFORCE_CLIENT_SECRET,
    'salesforce_instance_url' = SALESFORCE_INSTANCE_URL
)
EXECUTE AS CALLER
AS
$$
import requests
import json
import sys
import _snowflake
from datetime import datetime, date

def get_salesforce_credentials():
    """
    Retrieve Salesforce credentials from Snowflake Secrets
    This is the secure way to handle credentials in production
    """
    try:
        client_id = _snowflake.get_generic_secret_string('salesforce_client_id')
        client_secret = _snowflake.get_generic_secret_string('salesforce_client_secret')
        instance_url = _snowflake.get_generic_secret_string('salesforce_instance_url')
        
        # Validate that all credentials were retrieved
        if not client_id or not client_secret or not instance_url:
            raise Exception("One or more Salesforce credentials are missing from secrets")
            
        return client_id, client_secret, instance_url
    except Exception as e:
        raise Exception(f"Failed to retrieve Salesforce credentials from secrets: {str(e)}")

def get_access_token(client_id, client_secret, instance_url):
    """Get Salesforce OAuth access token"""
    token_url = f"{instance_url}/services/oauth2/token"
    
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    data = {
        'grant_type': 'client_credentials',
        'client_id': client_id,
        'client_secret': client_secret
    }
    
    response = requests.post(token_url, headers=headers, data=data)
    if response.status_code == 200:
        return response.json()['access_token']
    else:
        raise Exception(f"Failed to get access token. Status: {response.status_code}, Response: {response.text}")

def find_campaign_by_name(access_token, instance_url, campaign_name):
    """Find campaign by name in Salesforce"""
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    # Use SOQL query to find campaign by name
    query = f"SELECT Id, Name FROM Campaign WHERE Name = '{campaign_name.replace(\"'\", \"\\'\")}' LIMIT 1"
    query_url = f"{instance_url}/services/data/v58.0/query"
    params = {'q': query}
    
    response = requests.get(query_url, headers=headers, params=params)
    if response.status_code == 200:
        data = response.json()
        if data['totalSize'] > 0:
            return data['records'][0]['Id']
    return None

def create_campaign(access_token, instance_url, campaign_name):
    """Create new campaign in Salesforce"""
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    campaign_data = {
        "Name": campaign_name,
        "IsActive": True,
        "Status": "In Progress",
        "Type": "Other",
        "Description": f"Campaign created from Snowflake on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    }
    
    create_url = f"{instance_url}/services/data/v58.0/sobjects/Campaign"
    response = requests.post(create_url, headers=headers, json=campaign_data)
    
    if response.status_code == 201:
        return response.json()['id']
    else:
        raise Exception(f"Failed to create campaign. Status: {response.status_code}, Response: {response.text}")

def find_contact_by_email(access_token, instance_url, email):
    """Find contact by email in Salesforce"""
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    query = f"SELECT Id FROM Contact WHERE Email = '{email.replace(\"'\", \"\\'\"))}' LIMIT 1"
    query_url = f"{instance_url}/services/data/v58.0/query"
    params = {'q': query}
    
    response = requests.get(query_url, headers=headers, params=params)
    if response.status_code == 200:
        data = response.json()
        if data['totalSize'] > 0:
            return data['records'][0]['Id']
    return None

def create_contact(access_token, instance_url, patient_name, patient_id, email):
    """Create new contact in Salesforce"""
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    # Split name into first and last name
    name_parts = str(patient_name).strip().split(' ', 1)
    first_name = name_parts[0] if len(name_parts) > 0 else 'Unknown'
    last_name = name_parts[1] if len(name_parts) > 1 else 'Patient'
    
    contact_data = {
        "FirstName": first_name,
        "LastName": last_name,
        "Email": str(email),
        "patient_id__c": float(patient_id),  # Convert to float for Salesforce number field
        "Title": "Patient",
        "Description": f"Contact created from Snowflake on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    }
    
    create_url = f"{instance_url}/services/data/v58.0/sobjects/Contact"
    response = requests.post(create_url, headers=headers, json=contact_data)
    
    if response.status_code == 201:
        return response.json()['id']
    else:
        return None

def add_contact_to_campaign(access_token, instance_url, campaign_id, contact_id):
    """Add contact to campaign as a member"""
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    member_data = {
        "CampaignId": campaign_id,
        "ContactId": contact_id,
        "Status": "Sent"
    }
    
    create_url = f"{instance_url}/services/data/v58.0/sobjects/CampaignMember"
    response = requests.post(create_url, headers=headers, json=member_data)
    
    if response.status_code == 201:
        return response.json()['id']
    else:
        return None

def parse_patients_json(patients_json):
    """
    Parse the JSON string into a list of patient dictionaries
    Handles various JSON format variations and validates structure
    """
    try:
        # Parse the JSON string
        if isinstance(patients_json, str):
            patients = json.loads(patients_json)
        else:
            patients = patients_json
            
        # Ensure it's a list
        if not isinstance(patients, list):
            raise ValueError("Patient data must be a JSON array")
            
        # Validate each patient object
        validated_patients = []
        for i, patient in enumerate(patients):
            if not isinstance(patient, dict):
                raise ValueError(f"Patient {i+1} must be a JSON object")
                
            # Ensure required fields exist
            required_fields = ['name', 'patient_id', 'email']
            missing_fields = [field for field in required_fields if field not in patient or not patient[field]]
            
            if missing_fields:
                raise ValueError(f"Patient {i+1} missing required fields: {', '.join(missing_fields)}")
                
            validated_patients.append(patient)
            
        return validated_patients
        
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid JSON format: {str(e)}")
    except Exception as e:
        raise ValueError(f"Error parsing patient data: {str(e)}")

def main(session, campaign_name, patients_json):
    """
    Main procedure handler for Salesforce Campaign Management (Agent-Compatible Version)
    
    Args:
    - campaign_name: String - Name of the campaign to create/use
    - patients_json: String - JSON string containing array of patient objects
    
    Patient JSON structure:
    [
        {
            'name': 'John Doe',
            'patient_id': 100001, 
            'email': 'john.doe@email.com'
        },
        ...
    ]
    
    Returns:
    String with comprehensive results including success/failure counts and details
    """
    try:
        # Validate inputs
        if not campaign_name or not isinstance(campaign_name, str):
            return "ERROR: Campaign name is required and must be a string"
        
        if not patients_json or not isinstance(patients_json, str):
            return "ERROR: Patients JSON is required and must be a string"
        
        # Parse and validate patient JSON
        try:
            patients = parse_patients_json(patients_json)
        except ValueError as e:
            return f"ERROR: {str(e)}"
            
        total_patients = len(patients)
        if total_patients == 0:
            return "ERROR: No patients provided in JSON"
            
        # Get Salesforce credentials
        try:
            client_id, client_secret, sf_instance_url = get_salesforce_credentials()
        except Exception as e:
            return f"ERROR: Credential retrieval failed - {str(e)}"
        
        # Get access token
        try:
            access_token = get_access_token(client_id, client_secret, sf_instance_url)
        except Exception as e:
            return f"ERROR: Authentication failed - {str(e)}"
        
        # Find or create campaign
        campaign_id = find_campaign_by_name(access_token, sf_instance_url, campaign_name)
        campaign_created = False
        
        if not campaign_id:
            try:
                campaign_id = create_campaign(access_token, sf_instance_url, campaign_name)
                campaign_created = True
            except Exception as e:
                return f"ERROR: Failed to create campaign - {str(e)}"
        
        if not campaign_id:
            return f"ERROR: Could not find or create campaign '{campaign_name}'"
        
        # Process each patient
        successful_patients = 0
        contact_creation_count = 0
        failed_patients = []
        
        for i, patient in enumerate(patients):
            try:
                patient_name = patient.get('name', f'Patient {i+1}')
                patient_id = patient.get('patient_id')
                patient_email = patient.get('email')
                
                # Find or create contact
                contact_id = find_contact_by_email(access_token, sf_instance_url, patient_email)
                contact_was_created = False
                
                if not contact_id:
                    contact_id = create_contact(access_token, sf_instance_url, patient_name, patient_id, patient_email)
                    contact_was_created = True
                    if contact_id:
                        contact_creation_count += 1
                        
                if not contact_id:
                    failed_patients.append(f"{patient_name}: Failed to find or create contact")
                    continue
                
                # Add contact to campaign
                member_id = add_contact_to_campaign(access_token, sf_instance_url, campaign_id, contact_id)
                if member_id:
                    successful_patients += 1
                else:
                    failed_patients.append(f"{patient_name}: Failed to add to campaign")
                    
            except Exception as e:
                failed_patients.append(f"{patient_name}: Processing error - {str(e)}")
        
        # Build comprehensive result message
        result_parts = [
            f"CAMPAIGN: {campaign_name}",
            f"CAMPAIGN_STATUS: {'CREATED' if campaign_created else 'EXISTING'}",
            f"PATIENTS_REQUESTED: {total_patients}",
            f"PATIENTS_SUCCESSFUL: {successful_patients}",
            f"CONTACTS_CREATED: {contact_creation_count}"
        ]
        
        if failed_patients:
            result_parts.append(f"PATIENTS_FAILED: {len(failed_patients)}")
            # Limit failed details to prevent overly long messages
            failed_summary = "; ".join(failed_patients[:5])
            if len(failed_patients) > 5:
                failed_summary += f"; ... and {len(failed_patients) - 5} more"
            result_parts.append(f"FAILURE_DETAILS: {failed_summary}")
        
        success_rate = round((successful_patients / total_patients) * 100, 1)
        result_parts.append(f"SUCCESS_RATE: {success_rate}%")
        
        return " | ".join(result_parts)
        
    except Exception as e:
        return f"ERROR: Unexpected error in procedure - {str(e)}"

$$;



-- Test 1: Test with new patients (should create new contacts)
SELECT 'Test 1: Creating new patients with unique patient IDs...' as test_status;

CALL SALESFORCE_CAMPAIGN_MANAGER(
    'Patient ID Test Campaign 2024',
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
