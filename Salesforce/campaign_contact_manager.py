#!/usr/bin/env python3
"""
Salesforce Campaign Contact Manager
This script manages campaigns and contacts:
- Creates campaigns if they don't exist
- Creates contacts if they don't exist
- Adds contacts to campaigns as campaign members
"""

import os
import sys
import requests
import json
import random
from pathlib import Path
from datetime import datetime, date

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
        print("Please create a .env file with your Salesforce credentials.")
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
    print_colored("Step 1: Requesting Access Token...", Colors.BLUE)
    
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
        
        if not access_token:
            print_colored("❌ Failed to obtain access token", Colors.RED)
            sys.exit(1)
        
        print_colored("✅ Successfully obtained access token", Colors.GREEN)
        print_colored(f"Instance URL: {instance_url}", Colors.CYAN)
        print()
        
        return access_token, instance_url
        
    except requests.exceptions.RequestException as e:
        print_colored("❌ Failed to connect to Salesforce", Colors.RED)
        print_colored(f"Error: {str(e)}", Colors.RED)
        sys.exit(1)

def find_campaign_by_name(access_token, instance_url, campaign_name):
    """Find campaign by name"""
    print_colored(f"Checking if campaign '{campaign_name}' exists...", Colors.BLUE)
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    query_url = f"{instance_url}/services/data/v58.0/query"
    params = {
        'q': f"SELECT Id, Name, Status, Type FROM Campaign WHERE Name = '{campaign_name}' LIMIT 1"
    }
    
    try:
        response = requests.get(query_url, headers=headers, params=params)
        response.raise_for_status()
        
        result = response.json()
        
        if result.get('totalSize', 0) > 0:
            campaign = result['records'][0]
            print_colored(f"✅ Campaign found: {campaign['Name']} (ID: {campaign['Id']})", Colors.GREEN)
            return campaign['Id']
        else:
            print_colored(f"📋 Campaign '{campaign_name}' not found", Colors.YELLOW)
            return None
            
    except requests.exceptions.RequestException as e:
        print_colored(f"❌ Error searching for campaign: {str(e)}", Colors.RED)
        return None

def create_campaign(access_token, instance_url, campaign_name):
    """Create a new campaign"""
    print_colored(f"Creating campaign '{campaign_name}'...", Colors.BLUE)
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    # Campaign data with healthcare-appropriate defaults
    campaign_data = {
        "Name": campaign_name,
        "Status": "Planned",
        "Type": "Other",
        "Description": f"Test campaign created on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "StartDate": date.today().strftime('%Y-%m-%d'),
        "IsActive": True
    }
    
    print_colored("Campaign data to be created:", Colors.CYAN)
    for key, value in campaign_data.items():
        print(f"  {key}: {value}")
    print()
    
    create_url = f"{instance_url}/services/data/v58.0/sobjects/Campaign"
    
    try:
        response = requests.post(create_url, headers=headers, json=campaign_data)
        
        if response.status_code == 201:
            result = response.json()
            campaign_id = result.get('id')
            
            print_colored("✅ Campaign created successfully!", Colors.GREEN)
            print_colored(f"New Campaign ID: {campaign_id}", Colors.YELLOW)
            print_colored(f"Campaign Name: {campaign_name}", Colors.YELLOW)
            
            return campaign_id
            
        else:
            print_colored("❌ Failed to create campaign", Colors.RED)
            print_colored(f"Status Code: {response.status_code}", Colors.RED)
            
            try:
                error_data = response.json()
                print_colored("Error details:", Colors.YELLOW)
                if isinstance(error_data, list) and len(error_data) > 0:
                    for error in error_data:
                        print(f"  Error Code: {error.get('errorCode', 'Unknown')}")
                        print(f"  Message: {error.get('message', 'No message')}")
                else:
                    print(f"  {error_data}")
            except json.JSONDecodeError:
                print_colored(f"Raw response: {response.text}", Colors.YELLOW)
                
            return None
            
    except requests.exceptions.RequestException as e:
        print_colored("❌ Network error while creating campaign", Colors.RED)
        print_colored(f"Error: {str(e)}", Colors.RED)
        return None

def find_contact_by_email(access_token, instance_url, email):
    """Find contact by email"""
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    query_url = f"{instance_url}/services/data/v58.0/query"
    params = {
        'q': f"SELECT Id, FirstName, LastName, Email FROM Contact WHERE Email = '{email}' LIMIT 1"
    }
    
    try:
        response = requests.get(query_url, headers=headers, params=params)
        response.raise_for_status()
        
        result = response.json()
        
        if result.get('totalSize', 0) > 0:
            contact = result['records'][0]
            return contact['Id'], contact
        else:
            return None, None
            
    except requests.exceptions.RequestException as e:
        print_colored(f"❌ Error searching for contact: {str(e)}", Colors.RED)
        return None, None

def generate_fictitious_contact_data(first_name=None, last_name=None, email=None):
    """Generate fictitious contact data"""
    
    # Lists of fictitious names
    first_names = [
        "Emma", "Liam", "Olivia", "Noah", "Ava", "William", "Sophia", "Mason",
        "Isabella", "James", "Charlotte", "Benjamin", "Amelia", "Lucas", "Mia",
        "Harper", "Ethan", "Evelyn", "Alexander", "Abigail", "Henry", "Emily",
        "Sebastian", "Elizabeth", "Jackson", "Sofia", "Aiden", "Avery", "Matthew"
    ]
    
    last_names = [
        "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
        "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson",
        "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson",
        "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson"
    ]
    
    # Use provided values or generate random ones
    if not first_name:
        first_name = random.choice(first_names)
    if not last_name:
        last_name = random.choice(last_names)
    if not email:
        email = f"{first_name.lower()}.{last_name.lower()}{random.randint(1, 999)}@healthcaretest.com"
    
    # Generate random patient ID
    patient_id = random.randint(100000, 999999)
    
    # Generate phone
    phone = f"({random.randint(200, 999)}) {random.randint(200, 999)}-{random.randint(1000, 9999)}"
    
    contact_data = {
        "FirstName": first_name,
        "LastName": last_name,
        "Email": email,
        "patient_id__c": patient_id,
        "Phone": phone,
        "Title": random.choice(["Patient", "Healthcare Consumer", "Individual"]),
        "Description": f"Test contact created on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    }
    
    return contact_data

def create_contact(access_token, instance_url, contact_data):
    """Create a new Contact record"""
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    create_url = f"{instance_url}/services/data/v58.0/sobjects/Contact"
    
    try:
        response = requests.post(create_url, headers=headers, json=contact_data)
        
        if response.status_code == 201:
            result = response.json()
            contact_id = result.get('id')
            
            print_colored(f"✅ Contact created: {contact_data['FirstName']} {contact_data['LastName']} (ID: {contact_id})", Colors.GREEN)
            
            return contact_id
            
        else:
            print_colored("❌ Failed to create contact", Colors.RED)
            print_colored(f"Status Code: {response.status_code}", Colors.RED)
            return None
            
    except requests.exceptions.RequestException as e:
        print_colored("❌ Network error while creating contact", Colors.RED)
        return None

def ensure_contact_exists(access_token, instance_url, contact_info):
    """Ensure contact exists, create if it doesn't"""
    
    # If contact_info is a dict with contact data, use email to check
    if isinstance(contact_info, dict):
        email = contact_info.get('Email')
        first_name = contact_info.get('FirstName')
        last_name = contact_info.get('LastName')
    else:
        # Assume it's an email string
        email = contact_info
        first_name = None
        last_name = None
    
    print_colored(f"Checking if contact with email '{email}' exists...", Colors.BLUE)
    
    # Check if contact exists
    contact_id, existing_contact = find_contact_by_email(access_token, instance_url, email)
    
    if contact_id:
        print_colored(f"✅ Contact found: {existing_contact['FirstName']} {existing_contact['LastName']} (ID: {contact_id})", Colors.GREEN)
        return contact_id
    else:
        print_colored(f"📋 Contact with email '{email}' not found, creating...", Colors.YELLOW)
        
        # Generate or use provided contact data
        if isinstance(contact_info, dict):
            contact_data = contact_info
        else:
            contact_data = generate_fictitious_contact_data(first_name, last_name, email)
        
        print_colored("Contact data to be created:", Colors.CYAN)
        for key, value in contact_data.items():
            print(f"  {key}: {value}")
        print()
        
        # Create the contact
        contact_id = create_contact(access_token, instance_url, contact_data)
        return contact_id

def add_contact_to_campaign(access_token, instance_url, campaign_id, contact_id, status="Sent"):
    """Add contact to campaign as campaign member"""
    print_colored(f"Adding contact {contact_id} to campaign {campaign_id}...", Colors.BLUE)
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    # Campaign Member data
    member_data = {
        "CampaignId": campaign_id,
        "ContactId": contact_id,
        "Status": status
    }
    
    create_url = f"{instance_url}/services/data/v58.0/sobjects/CampaignMember"
    
    try:
        response = requests.post(create_url, headers=headers, json=member_data)
        
        if response.status_code == 201:
            result = response.json()
            member_id = result.get('id')
            
            print_colored(f"✅ Contact added to campaign successfully! (Member ID: {member_id})", Colors.GREEN)
            return member_id
            
        else:
            print_colored("❌ Failed to add contact to campaign", Colors.RED)
            print_colored(f"Status Code: {response.status_code}", Colors.RED)
            
            try:
                error_data = response.json()
                print_colored("Error details:", Colors.YELLOW)
                if isinstance(error_data, list) and len(error_data) > 0:
                    for error in error_data:
                        print(f"  Error Code: {error.get('errorCode', 'Unknown')}")
                        print(f"  Message: {error.get('message', 'No message')}")
                else:
                    print(f"  {error_data}")
            except json.JSONDecodeError:
                print_colored(f"Raw response: {response.text}", Colors.YELLOW)
                
            return None
            
    except requests.exceptions.RequestException as e:
        print_colored("❌ Network error while adding contact to campaign", Colors.RED)
        print_colored(f"Error: {str(e)}", Colors.RED)
        return None

def verify_campaign_membership(access_token, instance_url, campaign_id):
    """Verify campaign membership by querying campaign members"""
    print_colored("Verifying campaign membership...", Colors.BLUE)
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    query_url = f"{instance_url}/services/data/v58.0/query"
    params = {
        'q': f"""SELECT Id, Contact.FirstName, Contact.LastName, Contact.Email, Status, CreatedDate 
                 FROM CampaignMember 
                 WHERE CampaignId = '{campaign_id}' 
                 ORDER BY CreatedDate DESC"""
    }
    
    try:
        response = requests.get(query_url, headers=headers, params=params)
        response.raise_for_status()
        
        result = response.json()
        members = result.get('records', [])
        
        if members:
            print_colored(f"✅ Campaign has {len(members)} member(s):", Colors.GREEN)
            for member in members:
                contact = member.get('Contact', {})
                name = f"{contact.get('FirstName', '')} {contact.get('LastName', '')}"
                email = contact.get('Email', 'N/A')
                status = member.get('Status', 'N/A')
                created = member.get('CreatedDate', 'N/A')
                print(f"  • {name} ({email}) - Status: {status} - Added: {created}")
        else:
            print_colored("⚠️  Campaign has no members", Colors.YELLOW)
            
    except requests.exceptions.RequestException as e:
        print_colored(f"❌ Error verifying campaign membership: {str(e)}", Colors.RED)

def process_campaign_contacts(campaign_name, contact_list):
    """Main function to process campaign and contacts"""
    print_colored("=== Salesforce Campaign Contact Manager ===", Colors.MAGENTA)
    print()
    
    # Load environment variables
    env_vars = load_env_file()
    
    # Extract required credentials
    client_id = env_vars.get('SALESFORCE_CLIENT_ID')
    client_secret = env_vars.get('SALESFORCE_CLIENT_SECRET')
    dev_url = env_vars.get('SALESFORCE_DEV_URL')
    
    if not client_id or not client_secret or not dev_url:
        print_colored("Error: Missing required credentials in .env file", Colors.RED)
        sys.exit(1)
    
    print_colored(f"Campaign: '{campaign_name}'", Colors.CYAN)
    print_colored(f"Contacts to process: {len(contact_list)}", Colors.CYAN)
    print()
    
    # Get access token
    access_token, instance_url = get_access_token(client_id, client_secret, dev_url)
    
    # Step 2: Ensure campaign exists
    print_colored("Step 2: Managing Campaign...", Colors.BLUE)
    campaign_id = find_campaign_by_name(access_token, instance_url, campaign_name)
    
    if not campaign_id:
        campaign_id = create_campaign(access_token, instance_url, campaign_name)
        if not campaign_id:
            print_colored("❌ Failed to create campaign. Exiting.", Colors.RED)
            sys.exit(1)
    
    print()
    
    # Step 3: Process each contact
    print_colored("Step 3: Managing Contacts and Campaign Membership...", Colors.BLUE)
    
    successful_additions = 0
    
    for i, contact_info in enumerate(contact_list, 1):
        print_colored(f"--- Processing Contact {i}/{len(contact_list)} ---", Colors.CYAN)
        
        # Ensure contact exists
        contact_id = ensure_contact_exists(access_token, instance_url, contact_info)
        
        if contact_id:
            # Add contact to campaign
            member_id = add_contact_to_campaign(access_token, instance_url, campaign_id, contact_id)
            if member_id:
                successful_additions += 1
        
        print()
    
    # Step 4: Verify results
    print_colored("Step 4: Verification...", Colors.BLUE)
    verify_campaign_membership(access_token, instance_url, campaign_id)
    
    print()
    print_colored("=== Campaign Contact Management Complete ===", Colors.GREEN)
    print_colored(f"✅ Campaign: {campaign_name} (ID: {campaign_id})", Colors.YELLOW)
    print_colored(f"✅ Successful additions: {successful_additions}/{len(contact_list)}", Colors.YELLOW)

def main():
    """Main function with example usage"""
    
    # Example campaign and contacts
    campaign_name = "Healthcare Outreach 2025"
    
    # Example contact list - mix of email strings and full contact data
    contact_list = [
        # Just email - will generate random contact data
        "john.doe@example.com",
        
        # Full contact data
        {
            "FirstName": "Sarah",
            "LastName": "Johnson",
            "Email": "sarah.johnson@healthcaretest.com",
            "Phone": "(555) 123-4567"
        },
        
        # Another email
        "mike.wilson@example.com",
        
        # Another full contact
        {
            "FirstName": "Lisa",
            "LastName": "Martinez",  
            "Email": "lisa.martinez@healthcaretest.com",
            "Phone": "(555) 987-6543"
        }
    ]
    
    # Process the campaign and contacts
    process_campaign_contacts(campaign_name, contact_list)

if __name__ == "__main__":
    main()
