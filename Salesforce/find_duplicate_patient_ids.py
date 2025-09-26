#!/usr/bin/env python3
"""
Salesforce Duplicate Patient ID Finder
This script finds duplicate patient_id__c records and displays their information
"""

import os
import sys
import requests
import json
from pathlib import Path
from collections import defaultdict

# Colors for terminal output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    MAGENTA = '\033[0;35m'
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
        print("SALESFORCE_CLIENT_ID=your_client_id")
        print("SALESFORCE_CLIENT_SECRET=your_client_secret")
        print("SALESFORCE_DEV_URL=https://your_domain.my.salesforce.com")
        sys.exit(1)
    
    print_colored(f"Loading configuration from {env_file} file...", Colors.GREEN)
    
    # Parse .env file manually to handle quotes properly
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
        print_colored(f"Error: Missing required environment variables: {', '.join(missing_vars)}", Colors.RED)
        sys.exit(1)
    
    return env_vars

def get_access_token(client_id, client_secret, instance_url):
    """Get OAuth access token"""
    token_url = f"{instance_url}/services/oauth2/token"
    
    data = {
        'grant_type': 'client_credentials',
        'client_id': client_id,
        'client_secret': client_secret
    }
    
    try:
        response = requests.post(token_url, data=data, timeout=30)
        response.raise_for_status()
        
        token_data = response.json()
        return token_data['access_token']
        
    except requests.exceptions.RequestException as e:
        print_colored(f"❌ Error getting access token: {e}", Colors.RED)
        sys.exit(1)
    except KeyError:
        print_colored(f"❌ Error: Invalid response format from token endpoint", Colors.RED)
        sys.exit(1)

def find_duplicate_patient_ids(access_token, instance_url):
    """Find contacts with duplicate patient_id__c values"""
    print_colored("🔍 Searching for contacts with patient_id__c values...", Colors.BLUE)
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    # Query all contacts that have a patient_id__c value
    query = """
    SELECT Id, Name, FirstName, LastName, Email, patient_id__c 
    FROM Contact 
    WHERE patient_id__c != null 
    ORDER BY patient_id__c, Name
    """
    
    query_url = f"{instance_url}/services/data/v58.0/query"
    params = {'q': query}
    
    try:
        response = requests.get(query_url, headers=headers, params=params, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        contacts = data['records']
        
        print_colored(f"✅ Found {len(contacts)} contacts with patient_id__c values", Colors.GREEN)
        
        return contacts
        
    except requests.exceptions.RequestException as e:
        print_colored(f"❌ Error querying contacts: {e}", Colors.RED)
        sys.exit(1)

def analyze_duplicates(contacts):
    """Analyze contacts to find duplicates by patient_id__c"""
    print_colored("🧮 Analyzing for duplicates...", Colors.BLUE)
    
    # Group contacts by patient_id__c
    patient_id_groups = defaultdict(list)
    
    for contact in contacts:
        patient_id = contact.get('patient_id__c')
        if patient_id:
            patient_id_groups[patient_id].append(contact)
    
    # Find groups with more than one contact (duplicates)
    duplicates = {pid: contacts for pid, contacts in patient_id_groups.items() if len(contacts) > 1}
    
    return duplicates, patient_id_groups

def display_results(duplicates, patient_id_groups):
    """Display the duplicate analysis results"""
    print()
    print_colored("=" * 70, Colors.CYAN)
    print_colored("🔍 DUPLICATE PATIENT ID ANALYSIS RESULTS", Colors.CYAN)
    print_colored("=" * 70, Colors.CYAN)
    print()
    
    total_contacts = sum(len(contacts) for contacts in patient_id_groups.values())
    unique_patient_ids = len(patient_id_groups)
    duplicate_patient_ids = len(duplicates)
    contacts_in_duplicates = sum(len(contacts) for contacts in duplicates.values())
    
    # Summary statistics
    print_colored("📊 SUMMARY STATISTICS:", Colors.YELLOW)
    print(f"   Total Contacts with patient_id__c: {total_contacts}")
    print(f"   Unique patient_id__c values: {unique_patient_ids}")
    print(f"   Duplicate patient_id__c values: {duplicate_patient_ids}")
    print(f"   Contacts involved in duplicates: {contacts_in_duplicates}")
    print()
    
    if not duplicates:
        print_colored("✅ NO DUPLICATES FOUND!", Colors.GREEN)
        print_colored("All patient_id__c values are unique.", Colors.GREEN)
        return
    
    # Display duplicate details
    print_colored("⚠️  DUPLICATE PATIENT_ID__C RECORDS FOUND:", Colors.RED)
    print()
    
    for patient_id, duplicate_contacts in duplicates.items():
        print_colored(f"🚨 patient_id__c: {patient_id} ({len(duplicate_contacts)} duplicates)", Colors.MAGENTA)
        print_colored("-" * 50, Colors.CYAN)
        
        for i, contact in enumerate(duplicate_contacts, 1):
            print(f"   {i}. Name: {contact.get('Name', 'N/A')}")
            print(f"      ID: {contact.get('Id')}")
            print(f"      Email: {contact.get('Email', 'N/A')}")
            print(f"      First Name: {contact.get('FirstName', 'N/A')}")
            print(f"      Last Name: {contact.get('LastName', 'N/A')}")
            print()
        
        print_colored("-" * 50, Colors.CYAN)
        print()
    
    # Recommendations
    print_colored("💡 RECOMMENDATIONS:", Colors.YELLOW)
    print("   1. Review duplicate records for data quality issues")
    print("   2. Determine which records should be merged or deleted")
    print("   3. Consider implementing duplicate prevention rules")
    print("   4. Update patient_id__c to be unique if appropriate")
    print()

def main():
    """Main function"""
    print_colored("=" * 70, Colors.BLUE)
    print_colored("🔍 SALESFORCE DUPLICATE PATIENT ID FINDER", Colors.BLUE)
    print_colored("=" * 70, Colors.BLUE)
    print()
    
    # Load environment variables
    try:
        env_vars = load_env_file()
    except Exception as e:
        print_colored(f"Error loading environment variables: {e}", Colors.RED)
        sys.exit(1)
    
    client_id = env_vars['SALESFORCE_CLIENT_ID']
    client_secret = env_vars['SALESFORCE_CLIENT_SECRET']
    instance_url = env_vars['SALESFORCE_DEV_URL'].rstrip('/')
    
    print_colored(f"Using Salesforce URL: {instance_url}", Colors.CYAN)
    print_colored(f"Client ID: ...{client_id[-10:]}", Colors.CYAN)
    print()
    
    # Get access token
    print_colored("🔐 Getting access token...", Colors.BLUE)
    access_token = get_access_token(client_id, client_secret, instance_url)
    print_colored("✅ Access token obtained", Colors.GREEN)
    print()
    
    # Find contacts with patient_id__c
    contacts = find_duplicate_patient_ids(access_token, instance_url)
    
    # Analyze for duplicates
    duplicates, patient_id_groups = analyze_duplicates(contacts)
    
    # Display results
    display_results(duplicates, patient_id_groups)
    
    print_colored("=" * 70, Colors.GREEN)
    print_colored("🏁 DUPLICATE ANALYSIS COMPLETE", Colors.GREEN)
    print_colored("=" * 70, Colors.GREEN)

if __name__ == "__main__":
    main()
