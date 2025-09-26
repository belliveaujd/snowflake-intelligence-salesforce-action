-- Snowflake Secrets Setup for Salesforce Integration
-- This script sets up secure credential management using Snowflake Secrets
-- Best practice for production Salesforce integrations

-- ===================================================================
-- STEP 1: Create Snowflake Secrets (One-time setup)
-- ===================================================================

-- Create secret for Salesforce Client ID (Consumer Key)
CREATE OR REPLACE SECRET salesforce_client_id
TYPE = GENERIC_STRING
SECRET_STRING = 'your_actual_salesforce_client_id_here';

-- Create secret for Salesforce Client Secret (Consumer Secret)  
CREATE OR REPLACE SECRET salesforce_client_secret
TYPE = GENERIC_STRING
SECRET_STRING = 'your_actual_salesforce_client_secret_here';

-- Create secret for Salesforce Instance URL
CREATE OR REPLACE SECRET salesforce_instance_url
TYPE = GENERIC_STRING
SECRET_STRING = 'https://your-actual-instance.salesforce.com';

-- ===================================================================
-- STEP 2: Grant Usage Rights on Secrets
-- ===================================================================

-- Grant usage to your role (replace 'YOUR_ROLE' with actual role)
GRANT USAGE ON SECRET salesforce_client_id TO ROLE sysadmin;
GRANT USAGE ON SECRET salesforce_client_secret TO ROLE sysadmin;
GRANT USAGE ON SECRET salesforce_instance_url TO ROLE sysadmin;

-- For production, grant to specific roles that need access
-- GRANT USAGE ON SECRET salesforce_client_id TO ROLE data_integration_role;
-- GRANT USAGE ON SECRET salesforce_client_secret TO ROLE data_integration_role;
-- GRANT USAGE ON SECRET salesforce_instance_url TO ROLE data_integration_role;

-- ===================================================================
-- STEP 3: Verify Secrets Creation
-- ===================================================================

-- List created secrets
SHOW SECRETS;

-- Check specific secrets (will not show values, only metadata)
DESC SECRET salesforce_client_id;
DESC SECRET salesforce_client_secret;
DESC SECRET salesforce_instance_url;

-- ===================================================================
-- STEP 4: Test Secret Access (Optional Validation)
-- ===================================================================

-- This is just for testing - DO NOT use in production code
-- SELECT SYSTEM$GET_SECRET_STRING('salesforce_client_id') as client_id_test;

-- ===================================================================
-- SECURITY NOTES
-- ===================================================================

/*
1. PRINCIPLE OF LEAST PRIVILEGE:
   - Only grant secret usage to roles that absolutely need it
   - Use specific integration roles rather than broad admin roles

2. SECRET ROTATION:
   - Regularly rotate Salesforce credentials
   - Update secrets when credentials change:
     ALTER SECRET salesforce_client_secret SET SECRET_STRING = 'new_secret';

3. AUDIT AND MONITORING:
   - Monitor secret access via Snowflake query history
   - Set up alerts for unusual secret access patterns
   - Review secret grants periodically

4. SEPARATION OF DUTIES:
   - Different roles for secret creation vs. usage
   - Separate secrets for different environments (dev/test/prod)

*/

-- ===================================================================
-- EXAMPLE: Environment-Specific Secrets
-- ===================================================================

-- For multiple environments, create separate secrets:

-- Development Environment
CREATE OR REPLACE SECRET salesforce_dev_client_id
TYPE = GENERIC_STRING
SECRET_STRING = 'dev_client_id_here';

CREATE OR REPLACE SECRET salesforce_dev_client_secret
TYPE = GENERIC_STRING
SECRET_STRING = 'dev_client_secret_here';

CREATE OR REPLACE SECRET salesforce_dev_instance_url
TYPE = GENERIC_STRING
SECRET_STRING = 'https://dev-instance.salesforce.com';

-- Production Environment
CREATE OR REPLACE SECRET salesforce_prod_client_id
TYPE = GENERIC_STRING
SECRET_STRING = 'prod_client_id_here';

CREATE OR REPLACE SECRET salesforce_prod_client_secret
TYPE = GENERIC_STRING
SECRET_STRING = 'prod_client_secret_here';

CREATE OR REPLACE SECRET salesforce_prod_instance_url
TYPE = GENERIC_STRING
SECRET_STRING = 'https://prod-instance.salesforce.com';

-- ===================================================================
-- CLEANUP COMMANDS (Use with caution!)
-- ===================================================================

-- To remove secrets (CAREFUL - this will delete the credentials!)
-- DROP SECRET IF EXISTS salesforce_client_id;
-- DROP SECRET IF EXISTS salesforce_client_secret; 
-- DROP SECRET IF EXISTS salesforce_instance_url;
