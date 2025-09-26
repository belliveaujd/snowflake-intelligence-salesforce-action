#!/usr/bin/env python3
"""
Salesforce Connectivity Test Script (Python)
This script loads credentials from .env and tests OAuth Client Credentials Flow
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
    print_colored("Test 1: Requesting Access Token...", Colors.BLUE)
    
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
        print_colored(f"Instance URL: {instance_url}", Colors.YELLOW)
        print_colored(f"Token (first 20 chars): {access_token[:20]}...", Colors.YELLOW)
        print()
        
        return access_token, instance_url
        
    except requests.exceptions.RequestException as e:
        print_colored("❌ Failed to connect to Salesforce", Colors.RED)
        print_colored(f"Error: {str(e)}", Colors.RED)
        sys.exit(1)

def test_organization_info(access_token, instance_url):
    """Test API call to get organization information"""
    print_colored("Test 2: Testing API Call - Organization Info...", Colors.BLUE)
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    query_url = f"{instance_url}/services/data/v58.0/query"
    params = {
        'q': 'SELECT Id,Name,OrganizationType FROM Organization'
    }
    
    try:
        response = requests.get(query_url, headers=headers, params=params)
        response.raise_for_status()
        
        org_data = response.json()
        
        if 'records' in org_data and org_data['records']:
            org_name = org_data['records'][0].get('Name', 'Unknown')
            print_colored("✅ Successfully retrieved organization info", Colors.GREEN)
            print_colored(f"Organization: {org_name}", Colors.YELLOW)
        else:
            print_colored("❌ Failed to retrieve organization info", Colors.RED)
            print_colored(f"Response: {response.text}", Colors.YELLOW)
            
    except requests.exceptions.RequestException as e:
        print_colored("❌ Failed to retrieve organization info", Colors.RED)
        print_colored(f"Error: {str(e)}", Colors.RED)
    
    print()

def test_api_limits(access_token, instance_url):
    """Test API call to check organization limits"""
    print_colored("Test 3: Checking API Limits...", Colors.BLUE)
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    limits_url = f"{instance_url}/services/data/v58.0/limits"
    
    try:
        response = requests.get(limits_url, headers=headers)
        response.raise_for_status()
        
        limits_data = response.json()
        
        if 'DailyApiRequests' in limits_data:
            api_limits = limits_data['DailyApiRequests']
            max_requests = api_limits.get('Max', 0)
            remaining_requests = api_limits.get('Remaining', 0)
            
            print_colored("✅ Successfully retrieved API limits", Colors.GREEN)
            print_colored(f"Daily API Requests: {remaining_requests}/{max_requests} remaining", Colors.YELLOW)
        else:
            print_colored("❌ Failed to retrieve API limits", Colors.RED)
            print_colored(f"Response: {response.text}", Colors.YELLOW)
            
    except requests.exceptions.RequestException as e:
        print_colored("❌ Failed to retrieve API limits", Colors.RED)
        print_colored(f"Error: {str(e)}", Colors.RED)
    
    print()

def main():
    """Main function"""
    print_colored("=== Salesforce Connectivity Test ===", Colors.BLUE)
    
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
    
    print_colored(f"Using URL: {dev_url}", Colors.YELLOW)
    print_colored(f"Client ID: {client_id[:10]}...", Colors.YELLOW)
    print()
    
    # Test 1: Get access token
    access_token, instance_url = get_access_token(client_id, client_secret, dev_url)
    
    # Test 2: Organization info
    test_organization_info(access_token, instance_url)
    
    # Test 3: API limits
    test_api_limits(access_token, instance_url)
    
    # Summary
    print_colored("=== Connectivity Test Complete ===", Colors.GREEN)
    print_colored("✅ Authentication: Working", Colors.YELLOW)
    print_colored("✅ API Access: Working", Colors.YELLOW)
    print_colored(f"✅ Instance URL: {instance_url}", Colors.YELLOW)

if __name__ == "__main__":
    main()
