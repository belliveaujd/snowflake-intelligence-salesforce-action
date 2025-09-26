#!/usr/bin/env python3
"""
Comprehensive Salesforce Connection Test Script
Tests all aspects of Salesforce connectivity and API access
"""

import os
import sys
import requests
import json
from datetime import datetime

def load_env_variables():
    """Load environment variables from .env file"""
    # Check parent directory first, then current directory
    env_file = '../.env' if os.path.exists('../.env') else '.env'
    if not os.path.exists(env_file):
        print("❌ Error: .env file not found")
        print("📋 Please copy env_template.txt to .env and add your credentials")
        print("   Expected locations: ../.env or ./.env")
        return None
    
    env_vars = {}
    with open(env_file, 'r') as f:
        for line_number, line in enumerate(f, 1):
            line = line.strip()
            # Skip empty lines and comments
            if not line or line.startswith('#'):
                continue
            # Check if line contains an equals sign
            if '=' not in line:
                print(f"⚠️  Warning: Skipping malformed line {line_number}: '{line}'")
                continue
            # Split only on the first equals sign
            key, value = line.split('=', 1)
            key = key.strip()
            value = value.strip()
            # Skip if key is empty
            if not key:
                print(f"⚠️  Warning: Skipping line {line_number} with empty key")
                continue
            # Strip quotes if present
            value = value.strip('"\'')
            env_vars[key] = value
    
    required_vars = ['SALESFORCE_CLIENT_ID', 'SALESFORCE_CLIENT_SECRET', 'SALESFORCE_DEV_URL']
    missing_vars = [var for var in required_vars if var not in env_vars]
    
    if missing_vars:
        print(f"❌ Error: Missing required environment variables: {', '.join(missing_vars)}")
        return None
    
    return env_vars

def test_oauth_token(client_id, client_secret, instance_url):
    """Test OAuth token retrieval"""
    print("🔍 Testing OAuth 2.0 Token Retrieval...")
    
    token_url = f"{instance_url}/services/oauth2/token"
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    data = {
        'grant_type': 'client_credentials',
        'client_id': client_id,
        'client_secret': client_secret
    }
    
    try:
        response = requests.post(token_url, headers=headers, data=data)
        if response.status_code == 200:
            token_data = response.json()
            print("✅ OAuth token retrieved successfully")
            print(f"   Token Type: {token_data.get('token_type', 'N/A')}")
            print(f"   Scope: {token_data.get('scope', 'N/A')}")
            return token_data['access_token']
        else:
            print(f"❌ OAuth token retrieval failed")
            print(f"   Status Code: {response.status_code}")
            print(f"   Error: {response.text}")
            return None
    except Exception as e:
        print(f"❌ OAuth token retrieval exception: {str(e)}")
        return None

def test_api_connectivity(access_token, instance_url):
    """Test basic API connectivity"""
    print("\n🔍 Testing Salesforce API Connectivity...")
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    # Test 1: Get organization info
    try:
        org_url = f"{instance_url}/services/data/v58.0/query"
        params = {'q': 'SELECT Id, Name, OrganizationType FROM Organization LIMIT 1'}
        
        response = requests.get(org_url, headers=headers, params=params)
        if response.status_code == 200:
            org_data = response.json()
            if org_data['records']:
                org_info = org_data['records'][0]
                print("✅ API connectivity successful")
                print(f"   Organization: {org_info.get('Name', 'N/A')}")
                print(f"   Org Type: {org_info.get('OrganizationType', 'N/A')}")
                print(f"   Org ID: {org_info.get('Id', 'N/A')}")
                return True
        
        print(f"❌ API connectivity failed")
        print(f"   Status Code: {response.status_code}")
        print(f"   Error: {response.text}")
        return False
        
    except Exception as e:
        print(f"❌ API connectivity exception: {str(e)}")
        return False

def test_contact_object_access(access_token, instance_url):
    """Test Contact object access and custom fields"""
    print("\n🔍 Testing Contact Object Access...")
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    try:
        # Test Contact object describe
        describe_url = f"{instance_url}/services/data/v58.0/sobjects/Contact/describe"
        response = requests.get(describe_url, headers=headers)
        
        if response.status_code == 200:
            contact_desc = response.json()
            print("✅ Contact object access successful")
            
            # Check for patient_id__c field
            fields = {field['name']: field for field in contact_desc['fields']}
            
            if 'patient_id__c' in fields:
                patient_field = fields['patient_id__c']
                print("✅ patient_id__c custom field found")
                print(f"   Type: {patient_field.get('type', 'N/A')}")
                print(f"   Required: {patient_field.get('nillable', True) == False}")
                print(f"   Unique: {patient_field.get('unique', False)}")
            else:
                print("⚠️  patient_id__c custom field NOT found")
                print("   This field is required for the integration")
                print("   Please create it following the setup guide")
            
            return True
        else:
            print(f"❌ Contact object access failed")
            print(f"   Status Code: {response.status_code}")
            print(f"   Error: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Contact object access exception: {str(e)}")
        return False

def test_campaign_object_access(access_token, instance_url):
    """Test Campaign object access"""
    print("\n🔍 Testing Campaign Object Access...")
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    try:
        # Test Campaign object describe
        describe_url = f"{instance_url}/services/data/v58.0/sobjects/Campaign/describe"
        response = requests.get(describe_url, headers=headers)
        
        if response.status_code == 200:
            campaign_desc = response.json()
            print("✅ Campaign object access successful")
            print(f"   Creatable: {campaign_desc.get('createable', False)}")
            print(f"   Updateable: {campaign_desc.get('updateable', False)}")
            return True
        else:
            print(f"❌ Campaign object access failed")
            print(f"   Status Code: {response.status_code}")
            print(f"   Error: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Campaign object access exception: {str(e)}")
        return False

def test_create_sample_data(access_token, instance_url):
    """Test creating sample contact and campaign"""
    print("\n🔍 Testing Sample Data Creation...")
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    test_results = []
    
    # Test 1: Create test contact
    try:
        test_patient_id = 999999  # Use high number to avoid conflicts
        contact_data = {
            "FirstName": "Test",
            "LastName": "ConnectionPatient",
            "Email": f"test.connection.{datetime.now().strftime('%Y%m%d%H%M%S')}@healthcaretest.com",
            "patient_id__c": test_patient_id,
            "Title": "Test Patient",
            "Description": f"Test contact created by connection test on {datetime.now()}"
        }
        
        create_url = f"{instance_url}/services/data/v58.0/sobjects/Contact"
        response = requests.post(create_url, headers=headers, json=contact_data)
        
        if response.status_code == 201:
            contact_result = response.json()
            contact_id = contact_result['id']
            print("✅ Test contact created successfully")
            print(f"   Contact ID: {contact_id}")
            test_results.append(('contact', contact_id))
        else:
            print(f"⚠️  Test contact creation failed")
            print(f"   Status Code: {response.status_code}")
            print(f"   Error: {response.text}")
            
    except Exception as e:
        print(f"❌ Test contact creation exception: {str(e)}")
    
    # Test 2: Create test campaign
    try:
        campaign_data = {
            "Name": f"Connection Test Campaign {datetime.now().strftime('%Y%m%d%H%M%S')}",
            "IsActive": True,
            "Status": "In Progress",
            "Type": "Other",
            "Description": f"Test campaign created by connection test on {datetime.now()}"
        }
        
        create_url = f"{instance_url}/services/data/v58.0/sobjects/Campaign"
        response = requests.post(create_url, headers=headers, json=campaign_data)
        
        if response.status_code == 201:
            campaign_result = response.json()
            campaign_id = campaign_result['id']
            print("✅ Test campaign created successfully")
            print(f"   Campaign ID: {campaign_id}")
            test_results.append(('campaign', campaign_id))
        else:
            print(f"⚠️  Test campaign creation failed")
            print(f"   Status Code: {response.status_code}")
            print(f"   Error: {response.text}")
            
    except Exception as e:
        print(f"❌ Test campaign creation exception: {str(e)}")
    
    return test_results

def cleanup_test_data(access_token, instance_url, test_results):
    """Clean up test data created during testing"""
    if not test_results:
        return
    
    print("\n🧹 Cleaning up test data...")
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    for object_type, record_id in test_results:
        try:
            if object_type == 'contact':
                delete_url = f"{instance_url}/services/data/v58.0/sobjects/Contact/{record_id}"
            elif object_type == 'campaign':
                delete_url = f"{instance_url}/services/data/v58.0/sobjects/Campaign/{record_id}"
            else:
                continue
            
            response = requests.delete(delete_url, headers=headers)
            if response.status_code == 204:
                print(f"✅ Cleaned up test {object_type}: {record_id}")
            else:
                print(f"⚠️  Failed to clean up test {object_type}: {record_id}")
                
        except Exception as e:
            print(f"❌ Cleanup exception for {object_type} {record_id}: {str(e)}")

def print_summary(results):
    """Print test summary"""
    print("\n" + "="*60)
    print("📊 SALESFORCE CONNECTION TEST SUMMARY")
    print("="*60)
    
    total_tests = len(results)
    passed_tests = sum(1 for result in results if result[1])
    failed_tests = total_tests - passed_tests
    
    for test_name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status:<10} {test_name}")
    
    print("-" * 60)
    print(f"📈 Results: {passed_tests}/{total_tests} tests passed")
    
    if failed_tests == 0:
        print("\n🎉 ALL TESTS PASSED! Salesforce connection is ready.")
        print("   You can now proceed to Snowflake setup.")
    else:
        print(f"\n⚠️  {failed_tests} test(s) failed. Please review the issues above.")
        print("   Check the debugging section in README.md for solutions.")

def main():
    """Main test execution"""
    print("🚀 SALESFORCE CONNECTION TEST STARTING")
    print("="*60)
    print(f"Test Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    results = []
    test_results = []
    
    # Load environment variables
    env_vars = load_env_variables()
    if not env_vars:
        sys.exit(1)
    
    print("✅ Environment variables loaded")
    print(f"   Instance URL: {env_vars['SALESFORCE_DEV_URL']}")
    print(f"   Client ID: {env_vars['SALESFORCE_CLIENT_ID'][:10]}...")
    
    # Test OAuth token
    access_token = test_oauth_token(
        env_vars['SALESFORCE_CLIENT_ID'],
        env_vars['SALESFORCE_CLIENT_SECRET'],
        env_vars['SALESFORCE_DEV_URL']
    )
    results.append(("OAuth Token Retrieval", access_token is not None))
    
    if not access_token:
        print_summary(results)
        sys.exit(1)
    
    # Test API connectivity
    api_success = test_api_connectivity(access_token, env_vars['SALESFORCE_DEV_URL'])
    results.append(("API Connectivity", api_success))
    
    if api_success:
        # Test Contact object access
        contact_success = test_contact_object_access(access_token, env_vars['SALESFORCE_DEV_URL'])
        results.append(("Contact Object Access", contact_success))
        
        # Test Campaign object access
        campaign_success = test_campaign_object_access(access_token, env_vars['SALESFORCE_DEV_URL'])
        results.append(("Campaign Object Access", campaign_success))
        
        # Test sample data creation
        if contact_success and campaign_success:
            test_results = test_create_sample_data(access_token, env_vars['SALESFORCE_DEV_URL'])
            data_creation_success = len(test_results) > 0
            results.append(("Sample Data Creation", data_creation_success))
            
            # Cleanup test data
            if test_results:
                cleanup_test_data(access_token, env_vars['SALESFORCE_DEV_URL'], test_results)
    
    print_summary(results)

if __name__ == "__main__":
    main()
