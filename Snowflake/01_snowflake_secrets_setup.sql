-- Setup for Salesforce Integration
-- This script sets up secure credential management using Snowflake Secrets, Network Rule, and External Access Integration

USE ROLE accountadmin;


-- ===================================================================
-- STEP 0: Create an Admin Tools Database and Schema to store secrets
-- ===================================================================
-- Best practice: Create a dedicated database for admin data
CREATE DATABASE IF NOT EXISTS ADMIN;

-- Best practice: Create a dedicated schema for secrets
CREATE SCHEMA IF NOT EXISTS admin.tools;


-- ===================================================================
-- STEP 1: Create Snowflake Secrets (One-time setup)
-- ===================================================================
USE DATABASE ADMIN;
USE SCHEMA admin.tools;


-- Create secret for Salesforce Client ID (Consumer Key)
CREATE OR REPLACE SECRET admin.tools.salesforce_client_id
TYPE = GENERIC_STRING
SECRET_STRING = 'your_actual_salesforce_client_id_here';

-- Create secret for Salesforce Client Secret (Consumer Secret)  
CREATE OR REPLACE SECRET admin.tools.salesforce_client_secret
TYPE = GENERIC_STRING
SECRET_STRING = 'your_actual_salesforce_client_secret_here';

-- Create secret for Salesforce Instance URL
CREATE OR REPLACE SECRET admin.tools.salesforce_instance_url
TYPE = GENERIC_STRING
SECRET_STRING = 'https://your-actual-instance.salesforce.com';

-- Verify creation
SHOW SECRETS;

-- ===================================================================
-- STEP 2: Grant Usage Rights on Secrets
-- ===================================================================

-- Grant usage to your role (replace 'YOUR_ROLE' with actual role)
GRANT USAGE ON SECRET admin.tools.salesforce_client_id TO ROLE sysadmin;
GRANT USAGE ON SECRET admin.tools.salesforce_client_secret TO ROLE sysadmin;
GRANT USAGE ON SECRET admin.tools.salesforce_instance_url TO ROLE sysadmin;

GRANT USAGE ON SECRET admin.tools.salesforce_client_id TO ROLE accountadmin;
GRANT USAGE ON SECRET admin.tools.salesforce_client_secret TO ROLE accountadmin;
GRANT USAGE ON SECRET admin.tools.salesforce_instance_url TO ROLE accountadmin;


-- ===================================================================
-- STEP 3: Create Network Rule for Salesforce Domains
-- ===================================================================

-- Create network rule for Salesforce domains
CREATE OR REPLACE NETWORK RULE salesforce_network_rule
MODE = EGRESS
TYPE = HOST_PORT
VALUE_LIST = (
    '*.salesforce.com:443', 
    '*.force.com:443', 
    'login.salesforce.com:443',
    '*.develop.my.salesforce.com:443',
    '*.my.salesforce.com:443'
);


-- ===================================================================
-- STEP 4: Create External Access Integration
-- ===================================================================

-- Create external access integration
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION salesforce_integration
ALLOWED_NETWORK_RULES = (salesforce_network_rule)
ENABLED = true;

ALTER EXTERNAL ACCESS INTEGRATION salesforce_integration
SET ALLOWED_AUTHENTICATION_SECRETS = (
    'admin.tools.salesforce_client_id',
    'admin.tools.salesforce_client_secret',
    'admin.tools.salesforce_instance_url'
);

-- Grant usage to appropriate roles
GRANT USAGE ON INTEGRATION salesforce_integration TO ROLE sysadmin;
GRANT USAGE ON INTEGRATION salesforce_integration TO ROLE accountadmin;



-- ===================================================================
-- STEP 5: Verify Setup
-- ===================================================================
-- List Secrets
SHOW SECRETS;

SHOW EXTERNAL ACCESS INTEGRATIONS LIKE 'SALESFORCE%';

-- List Integrations
SHOW INTEGRATIONS LIKE 'SALESFORCE%';
DESCRIBE INTEGRATION SALESFORCE_INTEGRATION;
-- Note the 'owner' column in the result.

-- List all secrets

-- Check specific secret metadata (does not show actual values)
DESC SECRET admin.tools.salesforce_client_id;
DESC SECRET admin.tools.salesforce_client_secret;
DESC SECRET admin.tools.salesforce_instance_url;
