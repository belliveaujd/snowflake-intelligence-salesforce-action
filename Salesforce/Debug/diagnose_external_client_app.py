#!/usr/bin/env python3
"""
External Client App Diagnostic Script
=====================================

This script helps diagnose CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY errors
by testing minimal Campaign creation with detailed error reporting.

Usage:
1. Set up your .env file with the FAILING External Client App credentials
2. Run: python diagnose_external_client_app.py
3. Compare results between working and failing apps

Author: Snowflake Healthcare Integration Team
"""

import requests
import json
import os
from datetime import datetime
import sys

# Color constants for output
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    PURPLE = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'

def print_colored(message, color=Colors.WHITE):
    """Print colored message"""
    print(f"{color}{message}{Colors.END}")

def load_environment():
    """Load environment variables from .env file"""
    env_vars = {}
    
    try:
        # Try to load from .env file
        if os.path.exists('.env'):
            with open('.env', 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        env_vars[key.strip()] = value.strip().strip('"\'')
        
        # Override with actual environment variables
        for key in ['SALESFORCE_CLIENT_ID', 'SALESFORCE_CLIENT_SECRET', 'SALESFORCE_INSTANCE_URL']:
            if key in os.environ:
                env_vars[key] = os.environ[key]
                
        return env_vars
        
    except Exception as e:
        print_colored(f"❌ Error loading environment: {e}", Colors.RED)
        return {}

def get_access_token(client_id, client_secret, instance_url):
    """Get Salesforce OAuth access token using Client Credentials Flow"""
    print_colored("🔑 Requesting OAuth access token...", Colors.BLUE)
    
    token_url = f"{instance_url}/services/oauth2/token"
    
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    data = {
        'grant_type': 'client_credentials',
        'client_id': client_id,
        'client_secret': client_secret
    }
    
    try:
        response = requests.post(token_url, headers=headers, data=data, timeout=30)
        
        print_colored(f"Token Request Status: {response.status_code}", Colors.CYAN)
        
        if response.status_code == 200:
            token_data = response.json()
            print_colored("✅ Access token obtained successfully", Colors.GREEN)
            return token_data.get('access_token'), None
        else:
            error_msg = f"Token request failed: {response.status_code} - {response.text}"
            print_colored(f"❌ {error_msg}", Colors.RED)
            return None, error_msg
            
    except requests.exceptions.RequestException as e:
        error_msg = f"Network error during token request: {e}"
        print_colored(f"❌ {error_msg}", Colors.RED)
        return None, error_msg

def test_minimal_campaign_creation(access_token, instance_url):
    """Test creating the most minimal Campaign possible"""
    print_colored("🧪 Testing minimal Campaign creation...", Colors.BLUE)
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    # Absolute minimal Campaign data
    test_campaign_name = f"DiagnosticTest_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    campaign_data = {
        "Name": test_campaign_name
    }
    
    print_colored("Campaign data being sent:", Colors.CYAN)
    print(json.dumps(campaign_data, indent=2))
    print()
    
    create_url = f"{instance_url}/services/data/v58.0/sobjects/Campaign"
    print_colored(f"API Endpoint: {create_url}", Colors.CYAN)
    
    try:
        response = requests.post(create_url, headers=headers, json=campaign_data, timeout=30)
        
        print_colored(f"Campaign Creation Status: {response.status_code}", Colors.CYAN)
        
        if response.status_code == 201:
            result = response.json()
            campaign_id = result.get('id')
            print_colored("✅ CAMPAIGN CREATION SUCCESSFUL!", Colors.GREEN)
            print_colored(f"Campaign ID: {campaign_id}", Colors.GREEN)
            return campaign_id, None
        else:
            error_details = response.text
            print_colored("❌ CAMPAIGN CREATION FAILED", Colors.RED)
            print_colored("Full error response:", Colors.YELLOW)
            
            try:
                error_json = response.json()
                print(json.dumps(error_json, indent=2))
                
                # Extract specific error information
                if isinstance(error_json, list) and len(error_json) > 0:
                    error = error_json[0]
                    error_code = error.get('errorCode', 'UNKNOWN')
                    error_message = error.get('message', 'No message')
                    
                    print_colored(f"\nError Code: {error_code}", Colors.RED)
                    print_colored(f"Error Message: {error_message}", Colors.RED)
                    
                    return None, f"{error_code}: {error_message}"
                    
            except json.JSONDecodeError:
                print(error_details)
                return None, error_details
                
    except requests.exceptions.RequestException as e:
        error_msg = f"Network error during Campaign creation: {e}"
        print_colored(f"❌ {error_msg}", Colors.RED)
        return None, error_msg

def test_user_permissions(access_token, instance_url):
    """Test user permissions and context"""
    print_colored("👤 Testing user permissions and context...", Colors.BLUE)
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    # Test 1: User Info
    try:
        user_url = f"{instance_url}/services/oauth2/userinfo"
        response = requests.get(user_url, headers=headers, timeout=30)
        
        if response.status_code == 200:
            user_info = response.json()
            print_colored("User Information:", Colors.CYAN)
            print(f"  User ID: {user_info.get('user_id')}")
            print(f"  Username: {user_info.get('preferred_username')}")
            print(f"  Email: {user_info.get('email')}")
            print(f"  Organization: {user_info.get('organization_id')}")
            print()
        
    except Exception as e:
        print_colored(f"⚠️  Could not retrieve user info: {e}", Colors.YELLOW)
    
    # Test 2: Check Campaign object permissions via query
    try:
        query = "SELECT Id FROM Campaign LIMIT 1"
        query_url = f"{instance_url}/services/data/v58.0/query"
        params = {'q': query}
        
        response = requests.get(query_url, headers=headers, params=params, timeout=30)
        
        if response.status_code == 200:
            print_colored("✅ User can query Campaign objects", Colors.GREEN)
        else:
            print_colored(f"❌ User cannot query Campaign objects: {response.status_code}", Colors.RED)
            
    except Exception as e:
        print_colored(f"⚠️  Could not test Campaign query: {e}", Colors.YELLOW)

def cleanup_test_campaign(access_token, instance_url, campaign_id):
    """Clean up test campaign if created successfully"""
    if not campaign_id:
        return
        
    print_colored("🧹 Cleaning up test campaign...", Colors.BLUE)
    
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    delete_url = f"{instance_url}/services/data/v58.0/sobjects/Campaign/{campaign_id}"
    
    try:
        response = requests.delete(delete_url, headers=headers, timeout=30)
        
        if response.status_code == 204:
            print_colored("✅ Test campaign cleaned up successfully", Colors.GREEN)
        else:
            print_colored(f"⚠️  Could not delete test campaign: {response.status_code}", Colors.YELLOW)
            print_colored("Manual cleanup may be required in Salesforce", Colors.YELLOW)
            
    except Exception as e:
        print_colored(f"⚠️  Error during cleanup: {e}", Colors.YELLOW)

def main():
    """Main diagnostic function"""
    print_colored("="*60, Colors.BOLD)
    print_colored("🔍 EXTERNAL CLIENT APP DIAGNOSTIC TOOL", Colors.BOLD)
    print_colored("="*60, Colors.BOLD)
    print()
    
    # Load environment
    env_vars = load_environment()
    
    required_vars = ['SALESFORCE_CLIENT_ID', 'SALESFORCE_CLIENT_SECRET', 'SALESFORCE_INSTANCE_URL']
    missing_vars = [var for var in required_vars if not env_vars.get(var)]
    
    if missing_vars:
        print_colored("❌ Missing required environment variables:", Colors.RED)
        for var in missing_vars:
            print_colored(f"   - {var}", Colors.RED)
        print_colored("\nPlease set these in your .env file or environment variables.", Colors.YELLOW)
        sys.exit(1)
    
    client_id = env_vars['SALESFORCE_CLIENT_ID']
    client_secret = env_vars['SALESFORCE_CLIENT_SECRET']
    instance_url = env_vars['SALESFORCE_INSTANCE_URL']
    
    print_colored("Configuration:", Colors.CYAN)
    print(f"  Client ID: {client_id[:8]}...{client_id[-4:]}")
    print(f"  Instance URL: {instance_url}")
    print()
    
    # Step 1: Get Access Token
    access_token, error = get_access_token(client_id, client_secret, instance_url)
    
    if not access_token:
        print_colored("🛑 Cannot proceed without valid access token", Colors.RED)
        print_colored(f"Error: {error}", Colors.RED)
        print_colored("\nCheck your External Client App configuration:", Colors.YELLOW)
        print_colored("  1. OAuth Scopes: Must include 'Full access (full)'", Colors.YELLOW)
        print_colored("  2. Client Credentials Flow: Must be enabled", Colors.YELLOW)
        print_colored("  3. IP Restrictions: Should be disabled for testing", Colors.YELLOW)
        sys.exit(1)
    
    # Step 2: Test user permissions
    test_user_permissions(access_token, instance_url)
    
    # Step 3: Test Campaign creation
    campaign_id, error = test_minimal_campaign_creation(access_token, instance_url)
    
    print_colored("="*60, Colors.BOLD)
    
    if campaign_id:
        print_colored("🎉 DIAGNOSTIC RESULT: SUCCESS", Colors.GREEN)
        print_colored("Your External Client App is configured correctly!", Colors.GREEN)
        
        # Clean up
        cleanup_test_campaign(access_token, instance_url, campaign_id)
        
    else:
        print_colored("❌ DIAGNOSTIC RESULT: FAILURE", Colors.RED)
        print_colored(f"Campaign creation failed: {error}", Colors.RED)
        print()
        print_colored("Next steps:", Colors.YELLOW)
        print_colored("1. Compare this failing app with your working External Client App", Colors.YELLOW)
        print_colored("2. Focus on OAuth Scopes - must be 'Full access (full)'", Colors.YELLOW) 
        print_colored("3. Verify same System Administrator user in Client Credentials Flow", Colors.YELLOW)
        print_colored("4. Check IP Restrictions in OAuth Policies", Colors.YELLOW)
        print_colored("5. Enable debug logs for detailed error analysis", Colors.YELLOW)
    
    print_colored("="*60, Colors.BOLD)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print_colored("\n\nDiagnostic interrupted by user", Colors.YELLOW)
    except Exception as e:
        print_colored(f"\nUnexpected error: {e}", Colors.RED)
        sys.exit(1)
