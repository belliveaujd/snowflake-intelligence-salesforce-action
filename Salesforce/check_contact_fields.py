#!/usr/bin/env python3
"""
Salesforce Contact Fields Checker
This script checks what fields are available on the Contact object
"""

import os
import sys
import requests
import json
from pathlib import Path

# Colors for terminal output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'  # No Color

def print_colored(message, color):
    """Print colored message to terminal"""
    print(f"{color}{message}{Colors.NC}")

def load_env_file():
    """Load environment variables from .env file"""
    # Check parent directory first, then current directory
    env_file = Path('../.env') if Path('../.env').exists() else Path('.env')
    if not env_file.exists():
        print_colored("Error: .env file not found", Colors.RED)
        print("Please create a .env file with your Salesforce credentials:")
        print("Expected locations: ../.env or ./.env")
        sys.exit(1)
    
    print_colored(f"Loading configuration from {env_file} file...", Colors.GREEN)
    
    # Parse .env file manually to handle quotes properly
    env_vars = {}
    with open(env_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                value = value.strip('"\'')
                env_vars[key] = value
    
    return env_vars

def get_access_token(client_id, client_secret, dev_url):
    """Request access token using OAuth Client Credentials Flow"""
    token_url = f"{dev_url}/services/oauth2/token"
    
    headers = {
        'Content-Type': 'application/x-www-form-urlencoded'
    }
    
    data = {
        'grant_type': 'client_credentials',
        'client_id': client_id,
        'client_secret': client_secret
    }
    
    try:
        response = requests.post(token_url, headers=headers, data=data)
        response.raise_for_status()
        
        token_data = response.json()
        access_token = token_data.get('access_token')
        instance_url = token_data.get('instance_url')
        
        return access_token, instance_url
        
    except requests.exceptions.RequestException as e:
        print_colored(f"❌ Failed to get access token: {str(e)}", Colors.RED)
        sys.exit(1)

def check_contact_fields(access_token, instance_url):
    """Check Contact object fields"""
    print_colored("Checking Contact object fields...", Colors.BLUE)
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    # Get Contact object metadata
    describe_url = f"{instance_url}/services/data/v58.0/sobjects/Contact/describe"
    
    try:
        response = requests.get(describe_url, headers=headers)
        response.raise_for_status()
        
        contact_metadata = response.json()
        fields = contact_metadata.get('fields', [])
        
        print_colored(f"✅ Found {len(fields)} fields on Contact object", Colors.GREEN)
        print()
        
        # Check for required fields
        required_fields = []
        custom_fields = []
        standard_fields = []
        
        # Check for the patient_id__c field specifically
        patient_id_field = None
        
        for field in fields:
            field_name = field.get('name')
            is_required = not field.get('nillable', True) and not field.get('defaultedOnCreate', False)
            is_custom = field_name.endswith('__c')
            field_type = field.get('type')
            
            if is_required:
                required_fields.append(field_name)
            
            if is_custom:
                custom_fields.append(field_name)
            else:
                standard_fields.append(field_name)
            
            # Check if this is our patient_id__c field
            if field_name == 'patient_id__c':
                patient_id_field = field
        
        print_colored("📋 REQUIRED FIELDS:", Colors.RED)
        if required_fields:
            for field in sorted(required_fields):
                print(f"  • {field}")
        else:
            print("  • No required fields found")
        print()
        
        print_colored("🔧 CUSTOM FIELDS:", Colors.CYAN)
        if custom_fields:
            for field in sorted(custom_fields):
                print(f"  • {field}")
        else:
            print("  • No custom fields found")
        print()
        
        print_colored("🔍 patient_id__c Field Status:", Colors.YELLOW)
        if patient_id_field:
            print_colored("  ✅ patient_id__c field EXISTS", Colors.GREEN)
            print(f"     Type: {patient_id_field.get('type')}")
            print(f"     Label: {patient_id_field.get('label')}")
            print(f"     Required: {not patient_id_field.get('nillable', True)}")
            print(f"     Updateable: {patient_id_field.get('updateable', False)}")
        else:
            print_colored("  ❌ patient_id__c field NOT FOUND", Colors.RED)
            print("     This explains why it wasn't saved in the contact creation test")
        print()
        
        print_colored("📝 COMMON STANDARD FIELDS:", Colors.BLUE)
        common_fields = ['FirstName', 'LastName', 'Email', 'Phone', 'Title', 'Description', 'AccountId']
        for field in common_fields:
            if field in standard_fields:
                print(f"  ✅ {field}")
            else:
                print(f"  ❌ {field}")
        
        return patient_id_field is not None
        
    except requests.exceptions.RequestException as e:
        print_colored(f"❌ Error checking fields: {str(e)}", Colors.RED)
        return False

def main():
    """Main function"""
    print_colored("=== Salesforce Contact Fields Checker ===", Colors.BLUE)
    print()
    
    # Load environment variables
    env_vars = load_env_file()
    
    # Extract required credentials
    client_id = env_vars.get('SALESFORCE_CLIENT_ID')
    client_secret = env_vars.get('SALESFORCE_CLIENT_SECRET')
    dev_url = env_vars.get('SALESFORCE_DEV_URL')
    
    if not client_id or not client_secret or not dev_url:
        print_colored("Error: Missing credentials in .env file", Colors.RED)
        sys.exit(1)
    
    # Get access token
    access_token, instance_url = get_access_token(client_id, client_secret, dev_url)
    
    # Check fields
    patient_id_exists = check_contact_fields(access_token, instance_url)
    
    print()
    print_colored("=== Field Check Complete ===", Colors.GREEN)
    
    if not patient_id_exists:
        print_colored("💡 RECOMMENDATION:", Colors.YELLOW)
        print("   To use patient_id__c, you need to:")
        print("   1. Create a custom field named 'patient_id__c' on the Contact object")
        print("   2. Set the field type to Number or Text")
        print("   3. Grant appropriate permissions to your connected app user")

if __name__ == "__main__":
    main()
