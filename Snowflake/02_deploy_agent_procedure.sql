-- Deploy Agent-Compatible Salesforce Campaign Manager
-- Uses patient_id as unique identifier for contact lookup (not email)
-- Fixed version with proper secret references and Python formatting

USE DATABASE CUR_SYNTHETIC_HEALTHCARE;
USE SCHEMA DEMO_ASSETS;
USE WAREHOUSE CURWH_HEALTHCARE_DEMO_SMALL;

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
    'salesforce_client_id' = CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.SALESFORCE_CLIENT_ID,
    'salesforce_client_secret' = CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.SALESFORCE_CLIENT_SECRET,
    'salesforce_instance_url' = CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS.SALESFORCE_INSTANCE_URL
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
    """Retrieve Salesforce credentials from Snowflake Secrets"""
    try:
        client_id = _snowflake.get_generic_secret_string('salesforce_client_id')
        client_secret = _snowflake.get_generic_secret_string('salesforce_client_secret')
        instance_url = _snowflake.get_generic_secret_string('salesforce_instance_url')
        
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
    
    query = f"SELECT Id, Name FROM Campaign WHERE Name = '{campaign_name}' LIMIT 1"
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

def find_contact_by_patient_id(access_token, instance_url, patient_id):
    """Find contact by patient_id__c in Salesforce"""
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    query = f"SELECT Id FROM Contact WHERE patient_id__c = {patient_id} LIMIT 1"
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
    
    name_parts = str(patient_name).strip().split(' ', 1)
    first_name = name_parts[0] if len(name_parts) > 0 else 'Unknown'
    last_name = name_parts[1] if len(name_parts) > 1 else 'Patient'
    
    contact_data = {
        "FirstName": first_name,
        "LastName": last_name,
        "Email": str(email),
        "patient_id__c": float(patient_id),
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
    """Parse the JSON string into a list of patient dictionaries"""
    try:
        if isinstance(patients_json, str):
            patients = json.loads(patients_json)
        else:
            patients = patients_json
            
        if not isinstance(patients, list):
            raise ValueError("Patient data must be a JSON array")
            
        validated_patients = []
        for i, patient in enumerate(patients):
            if not isinstance(patient, dict):
                raise ValueError(f"Patient {i+1} must be a JSON object")
                
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
    """Main procedure handler for Salesforce Campaign Management (Agent-Compatible)
    Uses patient_id as unique identifier for contact lookup."""
    try:
        if not campaign_name or not isinstance(campaign_name, str):
            return "ERROR: Campaign name is required and must be a string"
        
        if not patients_json or not isinstance(patients_json, str):
            return "ERROR: Patients JSON is required and must be a string"
        
        try:
            patients = parse_patients_json(patients_json)
        except ValueError as e:
            return f"ERROR: {str(e)}"
            
        total_patients = len(patients)
        if total_patients == 0:
            return "ERROR: No patients provided in JSON"
            
        try:
            client_id, client_secret, sf_instance_url = get_salesforce_credentials()
        except Exception as e:
            return f"ERROR: Credential retrieval failed - {str(e)}"
        
        try:
            access_token = get_access_token(client_id, client_secret, sf_instance_url)
        except Exception as e:
            return f"ERROR: Authentication failed - {str(e)}"
        
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
        
        successful_patients = 0
        contact_creation_count = 0
        failed_patients = []
        
        for i, patient in enumerate(patients):
            try:
                patient_name = patient.get('name', f'Patient {i+1}')
                patient_id = patient.get('patient_id')
                patient_email = patient.get('email')
                
                contact_id = find_contact_by_patient_id(access_token, sf_instance_url, patient_id)
                
                if not contact_id:
                    contact_id = create_contact(access_token, sf_instance_url, patient_name, patient_id, patient_email)
                    if contact_id:
                        contact_creation_count += 1
                        
                if not contact_id:
                    failed_patients.append(f"{patient_name}: Failed to find or create contact")
                    continue
                
                member_id = add_contact_to_campaign(access_token, sf_instance_url, campaign_id, contact_id)
                if member_id:
                    successful_patients += 1
                else:
                    failed_patients.append(f"{patient_name}: Failed to add to campaign")
                    
            except Exception as e:
                failed_patients.append(f"{patient_name}: Processing error - {str(e)}")
        
        result_parts = [
            f"CAMPAIGN: {campaign_name}",
            f"CAMPAIGN_STATUS: {'CREATED' if campaign_created else 'EXISTING'}",
            f"PATIENTS_REQUESTED: {total_patients}",
            f"PATIENTS_SUCCESSFUL: {successful_patients}",
            f"CONTACTS_CREATED: {contact_creation_count}"
        ]
        
        if failed_patients:
            result_parts.append(f"PATIENTS_FAILED: {len(failed_patients)}")
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
