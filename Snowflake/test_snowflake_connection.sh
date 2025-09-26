#!/bin/bash

# Test Snowflake Connection Script
# This script tests your Snowflake connectivity and checks your current setup

echo "🔍 Testing Snowflake Connection..."

# Check if snow CLI is available
if ! command -v snow &> /dev/null; then
    echo "❌ Snowflake CLI not found. Please install it first."
    exit 1
fi

echo "✅ Snowflake CLI found"
echo

# List available connections
echo "📋 Available Snowflake connections:"
snow connection list

echo
echo "🔍 Testing connection with demo_admin_keypair..."

# Test basic connectivity
echo "1. Testing basic connectivity..."
snow sql --connection demo_admin_keypair -q "SELECT CURRENT_TIMESTAMP, CURRENT_USER(), CURRENT_ROLE(), CURRENT_WAREHOUSE(), CURRENT_DATABASE(), CURRENT_SCHEMA();"

echo
echo "2. Checking databases..."
snow sql --connection demo_admin_keypair -q "SHOW DATABASES;"

echo
echo "3. Checking your current context..."
snow sql --connection demo_admin_keypair -q "SELECT CURRENT_DATABASE() as current_db, CURRENT_SCHEMA() as current_schema, CURRENT_ROLE() as current_role;"

echo
echo "4. Checking if CUR_SYNTHETIC_HEALTHCARE database exists..."
snow sql --connection demo_admin_keypair -q "SHOW DATABASES LIKE 'CUR_SYNTHETIC_HEALTHCARE';"

echo
echo "5. Checking schemas in CUR_SYNTHETIC_HEALTHCARE..."
snow sql --connection demo_admin_keypair -q "USE DATABASE CUR_SYNTHETIC_HEALTHCARE; SHOW SCHEMAS;"

echo
echo "6. Checking secrets in DEMO_ASSETS schema..."
snow sql --connection demo_admin_keypair -q "USE DATABASE CUR_SYNTHETIC_HEALTHCARE; USE SCHEMA DEMO_ASSETS; SHOW SECRETS;"

echo
echo "7. Checking external access integrations..."
snow sql --connection demo_admin_keypair -q "SHOW INTEGRATIONS;"

echo
echo "✅ Snowflake connection test complete!"
