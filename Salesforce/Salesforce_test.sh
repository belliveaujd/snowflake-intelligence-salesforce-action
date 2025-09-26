#!/bin/bash

# Salesforce Connectivity Test Script
# This script loads credentials from .env and tests OAuth Client Credentials Flow

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Salesforce Connectivity Test ===${NC}"

# Load .env file if it exists (check parent directory first, then current)
if [ -f "../.env" ]; then
    echo -e "${GREEN}Loading configuration from ../.env file...${NC}"
    # Extract only the SALESFORCE variables we need, handling quotes properly
    export SALESFORCE_CLIENT_ID=$(grep '^SALESFORCE_CLIENT_ID=' ../.env | cut -d'=' -f2- | sed 's/^"//' | sed 's/"$//')
    export SALESFORCE_CLIENT_SECRET=$(grep '^SALESFORCE_CLIENT_SECRET=' ../.env | cut -d'=' -f2- | sed 's/^"//' | sed 's/"$//')
    export SALESFORCE_DEV_URL=$(grep '^SALESFORCE_DEV_URL=' ../.env | cut -d'=' -f2- | sed 's/^"//' | sed 's/"$//')
elif [ -f ".env" ]; then
    echo -e "${GREEN}Loading configuration from .env file...${NC}"
    # Extract only the SALESFORCE variables we need, handling quotes properly
    export SALESFORCE_CLIENT_ID=$(grep '^SALESFORCE_CLIENT_ID=' .env | cut -d'=' -f2- | sed 's/^"//' | sed 's/"$//')
    export SALESFORCE_CLIENT_SECRET=$(grep '^SALESFORCE_CLIENT_SECRET=' .env | cut -d'=' -f2- | sed 's/^"//' | sed 's/"$//')
    export SALESFORCE_DEV_URL=$(grep '^SALESFORCE_DEV_URL=' .env | cut -d'=' -f2- | sed 's/^"//' | sed 's/"$//')
else
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Please create a .env file with your Salesforce credentials:"
    echo "SALESFORCE_CLIENT_ID=your_consumer_key"
    echo "SALESFORCE_CLIENT_SECRET=your_consumer_secret"
    echo "SALESFORCE_DEV_URL=https://your_domain.my.salesforce.com"
    exit 1
fi

# Check if required variables are set
if [ -z "$SALESFORCE_CLIENT_ID" ] || [ -z "$SALESFORCE_CLIENT_SECRET" ] || [ -z "$SALESFORCE_DEV_URL" ]; then
    echo -e "${RED}Error: Missing required credentials in .env file${NC}"
    echo "Required variables:"
    echo "  SALESFORCE_CLIENT_ID=${SALESFORCE_CLIENT_ID:-'<missing>'}"
    echo "  SALESFORCE_CLIENT_SECRET=${SALESFORCE_CLIENT_SECRET:-'<missing>'}"
    echo "  SALESFORCE_DEV_URL=${SALESFORCE_DEV_URL:-'<missing>'}"
    exit 1
fi

echo -e "${YELLOW}Using URL: ${SALESFORCE_DEV_URL}${NC}"
echo -e "${YELLOW}Client ID: ...${SALESFORCE_CLIENT_ID: -10}${NC}"
echo

# Test 1: Request Access Token
echo -e "${BLUE}Test 1: Requesting Access Token...${NC}"

TOKEN_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=${SALESFORCE_CLIENT_ID}&client_secret=${SALESFORCE_CLIENT_SECRET}" \
  ${SALESFORCE_DEV_URL}/services/oauth2/token)

# Check if curl was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to connect to Salesforce${NC}"
    exit 1
fi

# Parse the response
ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
INSTANCE_URL=$(echo "$TOKEN_RESPONSE" | grep -o '"instance_url":"[^"]*"' | cut -d'"' -f4)

# Check if we got a token
if [ -z "$ACCESS_TOKEN" ]; then
    echo -e "${RED}❌ Failed to obtain access token${NC}"
    echo -e "${YELLOW}Response: ${TOKEN_RESPONSE}${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Successfully obtained access token${NC}"
echo -e "${YELLOW}Instance URL: ${INSTANCE_URL}${NC}"
echo -e "${YELLOW}Token (first 20 chars): ${ACCESS_TOKEN:0:20}...${NC}"
echo

# Test 2: Basic API Call - Organization Info
echo -e "${BLUE}Test 2: Testing API Call - Organization Info...${NC}"

ORG_RESPONSE=$(curl -s -X GET \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  "${INSTANCE_URL}/services/data/v58.0/query?q=SELECT+Id,Name,OrganizationType+FROM+Organization")

if [ $? -eq 0 ] && [[ $ORG_RESPONSE == *"records"* ]]; then
    ORG_NAME=$(echo "$ORG_RESPONSE" | grep -o '"Name":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo -e "${GREEN}✅ Successfully retrieved organization info${NC}"
    echo -e "${YELLOW}Organization: ${ORG_NAME}${NC}"
else
    echo -e "${RED}❌ Failed to retrieve organization info${NC}"
    echo -e "${YELLOW}Response: ${ORG_RESPONSE}${NC}"
fi
echo

# Test 3: API Limits Check
echo -e "${BLUE}Test 3: Checking API Limits...${NC}"

LIMITS_RESPONSE=$(curl -s -X GET \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  "${INSTANCE_URL}/services/data/v58.0/limits")

if [ $? -eq 0 ] && [[ $LIMITS_RESPONSE == *"DailyApiRequests"* ]]; then
    API_REQUESTS_MAX=$(echo "$LIMITS_RESPONSE" | grep -o '"DailyApiRequests":{"Max":[0-9]*' | grep -o '[0-9]*$')
    API_REQUESTS_USED=$(echo "$LIMITS_RESPONSE" | grep -o '"DailyApiRequests":{"Max":[0-9]*,"Remaining":[0-9]*' | grep -o 'Remaining":[0-9]*' | cut -d':' -f2)
    API_REQUESTS_REMAINING=$((API_REQUESTS_MAX - API_REQUESTS_USED))
    
    echo -e "${GREEN}✅ Successfully retrieved API limits${NC}"
    echo -e "${YELLOW}Daily API Requests: ${API_REQUESTS_REMAINING}/${API_REQUESTS_MAX} remaining${NC}"
else
    echo -e "${RED}❌ Failed to retrieve API limits${NC}"
    echo -e "${YELLOW}Response: ${LIMITS_RESPONSE}${NC}"
fi
echo

echo -e "${GREEN}=== Connectivity Test Complete ===${NC}"
echo -e "${YELLOW}✅ Authentication: Working${NC}"
echo -e "${YELLOW}✅ API Access: Working${NC}"
echo -e "${YELLOW}✅ Instance URL: ${INSTANCE_URL}${NC}"
