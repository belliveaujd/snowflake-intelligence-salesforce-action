#!/usr/bin/env python3
"""
Salesforce Contact Creation Test Script
This script creates a new Contact record in Salesforce with fictitious data
"""

import os
import sys
import requests
import json
import random
from pathlib import Path
from datetime import datetime

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
        print("SALESFORCE_CLIENT_ID=your_consumer_key")
        print("SALESFORCE_CLIENT_SECRET=your_consumer_secret")
        print("SALESFORCE_DEV_URL=https://your_domain.my.salesforce.com")
        sys.exit(1)
    
    print_colored(f"Loading configuration from {env_file} file...", Colors.GREEN)
    
    # Parse .env file manually to handle quotes properly
    env_vars = {}
    with open(env_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                # Remove surrounding quotes if present
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
            print_colored(f"Response: {response.text}", Colors.YELLOW)
            sys.exit(1)
        
        print_colored("✅ Successfully obtained access token", Colors.GREEN)
        print_colored(f"Instance URL: {instance_url}", Colors.CYAN)
        print()
        
        return access_token, instance_url
        
    except requests.exceptions.RequestException as e:
        print_colored("❌ Failed to connect to Salesforce", Colors.RED)
        print_colored(f"Error: {str(e)}", Colors.RED)
        sys.exit(1)

def generate_fictitious_contact_data():
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
    
    # Generate random patient ID (6-digit number)
    patient_id = random.randint(100000, 999999)
    
    # Select random names
    first_name = random.choice(first_names)
    last_name = random.choice(last_names)
    
    # Generate email based on name
    email = f"{first_name.lower()}.{last_name.lower()}{random.randint(1, 999)}@healthcaretest.com"
    
    # Generate additional fictitious data that might be required
    phone = f"({random.randint(200, 999)}) {random.randint(200, 999)}-{random.randint(1000, 9999)}"
    
    contact_data = {
        "FirstName": first_name,
        "LastName": last_name,
        "Email": email,
        "patient_id__c": patient_id,  # Custom field (lowercase as found in org)
        "Phone": phone,
        "Title": random.choice(["Patient", "Healthcare Consumer", "Individual"]),
        "Description": f"Test contact created on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    }
    
    return contact_data

def create_contact(access_token, instance_url, contact_data):
    """Create a new Contact record in Salesforce"""
    print_colored("Step 2: Creating Contact Record...", Colors.BLUE)
    
    # Display the contact data that will be created
    print_colored("Contact data to be created:", Colors.CYAN)
    for key, value in contact_data.items():
        print(f"  {key}: {value}")
    print()
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    # Salesforce REST API endpoint for creating Contact
    create_url = f"{instance_url}/services/data/v58.0/sobjects/Contact"
    
    try:
        response = requests.post(create_url, headers=headers, json=contact_data)
        
        if response.status_code == 201:
            # Success - Contact created
            result = response.json()
            contact_id = result.get('id')
            
            print_colored("✅ Contact created successfully!", Colors.GREEN)
            print_colored(f"New Contact ID: {contact_id}", Colors.YELLOW)
            print_colored(f"Full Name: {contact_data['FirstName']} {contact_data['LastName']}", Colors.YELLOW)
            print_colored(f"Patient ID: {contact_data['patient_id__c']}", Colors.YELLOW)
            print_colored(f"Email: {contact_data['Email']}", Colors.YELLOW)
            
            return contact_id
            
        else:
            # Error creating contact
            print_colored("❌ Failed to create contact", Colors.RED)
            print_colored(f"Status Code: {response.status_code}", Colors.RED)
            
            try:
                error_data = response.json()
                print_colored("Error details:", Colors.YELLOW)
                
                if isinstance(error_data, list) and len(error_data) > 0:
                    for error in error_data:
                        error_code = error.get('errorCode', 'Unknown')
                        message = error.get('message', 'No message')
                        fields = error.get('fields', [])
                        
                        print(f"  Error Code: {error_code}")
                        print(f"  Message: {message}")
                        if fields:
                            print(f"  Fields: {', '.join(fields)}")
                else:
                    print(f"  {error_data}")
                    
            except json.JSONDecodeError:
                print_colored(f"Raw response: {response.text}", Colors.YELLOW)
                
            return None
            
    except requests.exceptions.RequestException as e:
        print_colored("❌ Network error while creating contact", Colors.RED)
        print_colored(f"Error: {str(e)}", Colors.RED)
        return None

def verify_contact(access_token, instance_url, contact_id):
    """Verify the created contact by querying it back"""
    if not contact_id:
        return
        
    print_colored("Step 3: Verifying Contact Creation...", Colors.BLUE)
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    # Query the contact back
    query_url = f"{instance_url}/services/data/v58.0/query"
    params = {
        'q': f"SELECT Id, FirstName, LastName, Email, patient_id__c, Phone, CreatedDate FROM Contact WHERE Id = '{contact_id}'"
    }
    
    try:
        response = requests.get(query_url, headers=headers, params=params)
        response.raise_for_status()
        
        result = response.json()
        
        if result.get('totalSize', 0) > 0:
            contact = result['records'][0]
            print_colored("✅ Contact verification successful!", Colors.GREEN)
            print_colored("Retrieved contact details:", Colors.CYAN)
            print(f"  ID: {contact.get('Id')}")
            print(f"  Name: {contact.get('FirstName')} {contact.get('LastName')}")
            print(f"  Email: {contact.get('Email')}")
            print(f"  Patient ID: {contact.get('patient_id__c')}")
            print(f"  Phone: {contact.get('Phone')}")
            print(f"  Created: {contact.get('CreatedDate')}")
        else:
            print_colored("⚠️  Contact not found in verification query", Colors.YELLOW)
            
    except requests.exceptions.RequestException as e:
        print_colored("❌ Error verifying contact", Colors.RED)
        print_colored(f"Error: {str(e)}", Colors.RED)

def main():
    """Main function"""
    print_colored("=== Salesforce Contact Creation Test ===", Colors.BLUE)
    print()
    
    # Load environment variables
    env_vars = load_env_file()
    
    # Extract required credentials
    client_id = env_vars.get('SALESFORCE_CLIENT_ID')
    client_secret = env_vars.get('SALESFORCE_CLIENT_SECRET')
    dev_url = env_vars.get('SALESFORCE_DEV_URL')
    
    # Check if required variables are set
    if not client_id or not client_secret or not dev_url:
        print_colored("Error: Missing required credentials in .env file", Colors.RED)
        print("Required variables:")
        print(f"  SALESFORCE_CLIENT_ID={client_id or '<missing>'}")
        print(f"  SALESFORCE_CLIENT_SECRET={client_secret or '<missing>'}")
        print(f"  SALESFORCE_DEV_URL={dev_url or '<missing>'}")
        sys.exit(1)
    
    print_colored(f"Using Salesforce URL: {dev_url}", Colors.CYAN)
    print()
    
    # Get access token
    access_token, instance_url = get_access_token(client_id, client_secret, dev_url)
    
    # Generate fictitious contact data
    contact_data = generate_fictitious_contact_data()
    
    # Create the contact
    contact_id = create_contact(access_token, instance_url, contact_data)
    
    print()
    
    # Verify the contact was created
    verify_contact(access_token, instance_url, contact_id)
    
    print()
    print_colored("=== Contact Creation Test Complete ===", Colors.GREEN)
    
    if contact_id:
        print_colored("✅ Test Result: SUCCESS", Colors.GREEN)
        print_colored(f"✅ New Contact ID: {contact_id}", Colors.YELLOW)
    else:
        print_colored("❌ Test Result: FAILED", Colors.RED)
        print_colored("Check the error messages above for details", Colors.YELLOW)

if __name__ == "__main__":
    main()
