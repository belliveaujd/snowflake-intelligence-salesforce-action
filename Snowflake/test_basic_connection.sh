#!/bin/bash

# Simple Snowflake CLI Connectivity Test
# This script only tests basic CLI connection - nothing more

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔍 BASIC SNOWFLAKE CLI CONNECTIVITY TEST${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# Check if snow CLI is installed
echo -e "${YELLOW}Checking Snow CLI installation...${NC}"
if ! command -v snow &> /dev/null; then
    echo -e "${RED}❌ Snow CLI not found${NC}"
    echo "Please install Snowflake CLI: https://docs.snowflake.com/en/user-guide/snowsql-install-config"
    exit 1
fi
echo -e "${GREEN}✅ Snow CLI found${NC}"

# Check if connection exists
echo -e "${YELLOW}Checking demo_admin_keypair connection...${NC}"
if ! snow connection list 2>/dev/null | grep -q "demo_admin_keypair"; then
    echo -e "${RED}❌ Connection 'demo_admin_keypair' not found${NC}"
    echo "Please configure your Snowflake CLI connection:"
    echo "  snow connection add --connection-name demo_admin_keypair"
    exit 1
fi
echo -e "${GREEN}✅ Connection 'demo_admin_keypair' exists${NC}"

# Test basic connection
echo -e "${YELLOW}Testing basic connectivity...${NC}"
RESULT=$(snow sql --connection demo_admin_keypair -q "SELECT 'Connection Success' as status;" 2>&1)

if echo "$RESULT" | grep -q "Connection Success"; then
    echo -e "${GREEN}✅ BASIC CONNECTION SUCCESSFUL${NC}"
    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}🎉 SNOWFLAKE CLI CONNECTIVITY: WORKING${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo "You can now proceed with Snowflake setup and configuration."
    exit 0
else
    echo -e "${RED}❌ BASIC CONNECTION FAILED${NC}"
    echo
    echo "Error details:"
    echo "$RESULT"
    echo
    echo -e "${YELLOW}Common solutions:${NC}"
    echo "1. Check your connection configuration:"
    echo "   snow connection list"
    echo "2. Test connection parameters:"
    echo "   snow connection test --connection demo_admin_keypair"
    echo "3. Verify account credentials and network access"
    exit 1
fi
