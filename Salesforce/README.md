# Salesforce Setup and Testing

This folder contains all tools and documentation for setting up and testing Salesforce connectivity, including API testing, contact management, and campaign management.


## Table of Contents
[Return to Project Home](../Readme.md)

1. [Prerequisites](#prerequisites)
2. [Salesforce Developer Instance Setup](#salesforce-developer-instance-setup)
3. [Environment Configuration](#local-environment-configuration)
4. [Custom Field Configuration](#custom-field-configuration)



## Prerequisites
- Python 3.11+
- `requests` library (`pip install requests`)
- Salesforce Developer Account
- Basic understanding of OAuth 2.0 Client Credentials Flow

## Salesforce Developer Instance Setup
_[Back to: Table of Contents](#table-of-contents)_

### Step 1: Create Developer Instance

1. **Visit Salesforce Developer Portal**
   - Go to [developer.salesforce.com](https://developer.salesforce.com)
   - Click "Sign up" in the top right corner

2. **Fill Registration Form**
   - Complete all required fields
   - Use a valid email address (you'll need to verify it)
   - Choose appropriate country/role
   - Accept terms and conditions

3. **Verify Email**
   - Check your email for verification link
   - Click the verification link
   - Set your password when prompted

4. **Access Your Developer Instance**
   - Your instance URL will be in format: `https://[domain].develop.my.salesforce.com`
   - Log in with your credentials
   - Note your instance URL for later use
   - NOTE: you do not have to enable MFA.  If it asks for your phone number, hit the skip option

5. **Update your Profile for Marketing Campaigns**
   - Click the gear icon in the top-right corner and go to Setup.
   - In the 'Quick Find' box on the left, type Users and select Users.
   - Find your user record in the list and click Edit next to your name.
   - On the user edit page, find the checkbox labeled Marketing User (likely right column).
   - Check the box ✅.
   - Click Save.


### Step 2: External Client App Configuration (Summer '25+)

#### Step 2a: Enable External Client Apps

1. **Navigate to External Client Apps Settings**
   - Gear Icon in the upper right → Setup → Quick Find (search on the left) → "External Client Apps"
   - Click on "Settings" tab
   - ✅ **Enable External Client Apps** (if not already enabled)

#### Step 2b: Create External Client App

1. **Navigate to External Client Apps**
   - Setup → Quick Find → "External Client Apps Manager"
   - Click "New External Client App"

2. **Basic Information**
   - **External Client App Name:** Snowflake Healthcare Integration
   - **Description:** Integration between Snowflake and Salesforce for healthcare campaigns
   - **Contact Email:** [your email]
   
3. **API (Enable OAuth Settings)**
   - **Enable OAuth**
   - **Callback URL**: `https://login.salesforce.com/services/oauth2/success`
   - **Selected OAuth Scopes**: 
     - Full access (full) - **IMPORTANT**
   - **Enable Client Credentials Flow** (accept the warning)
   - Uncheck **Require PKCE for Authorization Code Flow** 
   - **Create** button



#### Step 2c: OAuth Policies (post creation)
1. **OAuth Policies**
   - **Edit** button
   - **Enable Client Credentials Flow** (e.g. josh.belliveau831@agentforce.com - seen in Profile | settings, if needed)
   - **Refresh Token Policy**: "Refresh token is valid until revoked"
   - **IP Restrictions**: Remove/disable IP restrictions
   - **Save**



#### Step 2d: Retrieve Credentials

1. **Get Client ID and Secret**
   - Click the `Settings` tab
   - Click `Consumer Key and Secret` button/link
   - Check your email and paste the verification code
   - Copy the **Consumer Key** (Client ID) and **Consumer Secret** (Client Secret)
   - **IMPORTANT**: Store these securely as you'll need them in your .env and/or Snowflake


## Local Environment Configuration

### Create Environment File

1. **Copy Template**
Create a `.env` file at the root of this project.
   ```bash
   cp .env_template.txt .env
   ```

2. **Update .env File**
   ```bash
   SALESFORCE_CLIENT_ID=your_consumer_key_here
   SALESFORCE_CLIENT_SECRET=your_consumer_secret_here
   SALESFORCE_DEV_URL=https://your-domain.develop.my.salesforce.com
   ```

```markdown
> [!WARNING]
> **Never commit the `.env` file to version control!** This file contains sensitive credentials and should remain local. It is already included in `.gitignore` to help prevent this.
```

### Connection Testing

For a **quick credential validation**, use the shell script:
```bash
cd Salesforce

./Salesforce_test.sh
```
**Use this script when:**
- ✅ You want to quickly verify Salesforce credentials are working
- ✅ You've just updated your `.env` file
- ✅ You need a fast connectivity check
- ✅ You're troubleshooting authentication issues


**Expected Output:**
```
✅ Salesforce connectivity test passed
📋 Configuration loaded from .env file
🔍 Testing OAuth Token Request...
✅ OAuth token retrieved successfully
🔍 Testing API connectivity...
✅ API connectivity successful
⏱️  Test completed in under 5 seconds
```


## Custom Field Configuration

### Create the Patient ID Field

1. **Navigate to Contact Object**
   - Setup → Object Manager → Contact

2. **Create Custom Field (if not exists)**
   - Fields & Relationships → New
   - Data Type: Number
   - Field Label: `Patient ID`
   - Field Name: `patient_id` (case sensitive)
   - Length: 18 digits (default should be fine)
   - Decimal Places: 0
   - **External ID** - checked (useful for upserts)
   - **Required** - (I left unchecked, but you can use it)
   - **Unique** - (I left unchecked, but you can use it)
 
### Adding patient_id__c to Contact Page Layouts

1. **Add to Contact Page Layout** (for contact details page)
   - Setup → Object Manager → Contact → Page Layouts (or just click **Page Layouts** if directly from last step)
   - Edit "Contact Layout" (or your custom layout)
   - Drag "Patient ID" field to desired section (it might already be there)
   - Save layout

2. **Add to Contact List Views** (for Contacts tab list view)
   - Use the App Launcher to go to Contacts (9 circle box in the upper left under the Salesforce logo)
   - Click the drop-down from the Menu bar (same horizontal plane as the 9 circle app launcher)
   - Select `All Contacts` ()
   - Click the gear icon → "Select Fields to Display"
   - Add `Patient ID` to "Visible Fields" (move to wherever you desire)
   - Add `Created Date` to "Visible Fields" (move to wherever you desire)
   - Save the list view (I think the change saves immediately)

3. **Add to Campaign Member List** (for campaign member views)\
   - Setup → Object Manager → Campaign Member → Fields & Relationships
   - New → Formula
   - Field Details:
     - Field Label: `Patient ID`
     - Field Name: `Campaign_Contact_Patient_ID`
     - Data Type: `Number`
     - Decimal Places: `0`
     - Formula: `Contact.patient_id__c`
   - Save

4. **Add Formula Field to Campaign Members Related List** (Campaign Page):
   - Setup → Object Manager → **Campaign** → Page Layouts
   - Edit "Campaign Layout" (the main campaign page layout)
   - Scroll down to the bottom to find the "Campaign Members" related list section
   - Click the **wrench/gear icon** on the "Campaign Members" related list
   - In the popup window:
     - **Available Fields** (left side): Look for your new field "Patient ID"
     - **Selected Fields** (right side): This shows what currently appears in the list
     - **Drag** "Patient ID" from Available Fields to Selected Fields
     - **Arrange** the field order as desired (drag up/down in Selected Fields)
   - Click **OK** to close the popup
   - Click **Save** on the page layout


**Salesforce Setup Complete ✅**
You have successfully completed the Salesforce setup! Now let's run some tests.


## Salesforce Testing
**NOTE:** The developer instance has an API limit of 15,000 calls per day.  Keep this in mind for your demos!

### Table of Contents for Tests
- [Basic Connectivity Check](#basic-connectivity-check)
- [Check for Contact Fields](#check-contact-fields)
- [Full Test of Salesforce](#salesforce-full-test)
- [Full Campaign Manager Test](#full-campaign-manager)
- [Optional: Contact Creation](#contact-creation)
- [Optional: Find Duplicate Patient IDs](#find-duplicate-patient-ids)


### Basic Connectivity Check
For a **quick credential validation**, use the shell script:
```bash
cd Salesforce

./Salesforce_test.sh
```
**Use this script when:**
- ✅ You want to quickly verify Salesforce credentials are working
- ✅ You've just updated your `.env` file
- ✅ You need a fast connectivity check
- ✅ You're troubleshooting authentication issues


**Expected Output:**
```
✅ Salesforce connectivity test passed
📋 Configuration loaded from .env file
🔍 Testing OAuth Token Request...
✅ OAuth token retrieved successfully
🔍 Testing API connectivity...
✅ API connectivity successful
⏱️  Test completed in under 5 seconds
```

### Check Contact Fields

**Check Required Fields**
```bash
python check_contact_fields.py
```
**Expected Output** 

The most important part is that the new custom field exists `patient_id__c`
```
=== Salesforce Contact Fields Checker ===
Loading configuration from ../.env file...
Checking Contact object fields...
✅ Found 67 fields on Contact object

📋 REQUIRED FIELDS:
• LastName
• Name

🔧 CUSTOM FIELDS:
• Languages__c
• Level__c
• member_id__c
• patient_id__c

🔍 patient_id__c Field Status:
✅ patient_id__c field EXISTS
   Type: double
   Label: Patient ID
   Required: False
   Updateable: True

📝 COMMON STANDARD FIELDS:
✅ FirstName
✅ LastName
✅ Email
✅ Phone
✅ Title
✅ Description
✅ AccountId

=== Field Check Complete ===
```

### Salesforce Full Test
For **detailed testing and validation**, use the comprehensive Python test:
```bash
python test_connection.py
```

**Expected Output**
```
(.venv) jbelliveau@LHJQ7C0D4J Salesforce % python ./test_connection.py 
🚀 SALESFORCE CONNECTION TEST STARTING
============================================================
Test Time: 2025-10-02 09:49:17

✅ Environment variables loaded
   Instance URL: https://orgfarm-6359004976-dev-ed.develop.my.salesforce.com
   Client ID: 3MVG9HtWXc...
🔍 Testing OAuth 2.0 Token Retrieval...
✅ OAuth token retrieved successfully
   Token Type: Bearer
   Scope: lightning visualforce cdp_query_api sfap_api cdp_ingest_api custom_permissions openid cdp_segment_api cdp_profile_api content cdp_api interaction_api cdp_identityresolution_api chatbot_api wave_api einstein_gpt_api cdp_calculated_insight_api pwdless_login_api chatter_api api id eclair_api pardot_api forgot_password

🔍 Testing Salesforce API Connectivity...
✅ API connectivity successful
   Organization: Synthea
   Org Type: Developer Edition
   Org ID: 00Dfj000008gBtjEAE

🔍 Testing Contact Object Access...
✅ Contact object access successful
✅ patient_id__c custom field found
   Type: double
   Required: False
   Unique: False

🔍 Testing Campaign Object Access...
✅ Campaign object access successful
   Creatable: True
   Updateable: True

🔍 Testing Sample Data Creation...
✅ Test contact created successfully
   Contact ID: 003fj00000JJz1dAAD
✅ Test campaign created successfully
   Campaign ID: 701fj00000JPHHJAA5

🧹 Cleaning up test data...
✅ Cleaned up test contact: 003fj00000JJz1dAAD
✅ Cleaned up test campaign: 701fj00000JPHHJAA5

============================================================
📊 SALESFORCE CONNECTION TEST SUMMARY
============================================================
✅ PASS     OAuth Token Retrieval
✅ PASS     API Connectivity
✅ PASS     Contact Object Access
✅ PASS     Campaign Object Access
✅ PASS     Sample Data Creation
------------------------------------------------------------
📈 Results: 5/5 tests passed

🎉 ALL TESTS PASSED! Salesforce connection is ready.
   You can now proceed to Snowflake setup.
```


### Full Campaign Manager

```bash
python campaign_contact_manager.py
```
_NOTE: failure messages might indicate they're already a member of the campaign you can go into Salesforce and verify/remove them to test again_

**Full Capabilities:**
- Create campaigns if they don't exist
- Create contacts if they don't exist (using patient_id as unique identifier)
- Add contacts to campaigns 
- Comprehensive error handling


**Expected Output from this Test**
```
=== Salesforce Campaign Contact Manager ===

Loading configuration from ../.env file...
Campaign: 'Healthcare Outreach 2025'
Contacts to process: 4

Step 1: Requesting Access Token...
✅ Successfully obtained access token
Instance URL: https://orgfarm-6359004976-dev-ed.develop.my.salesforce.com

Step 2: Managing Campaign...
Checking if campaign 'Healthcare Outreach 2025' exists...
✅ Campaign found: Healthcare Outreach 2025 (ID: 701fj00000I5DTcAAN)

Step 3: Managing Contacts and Campaign Membership...
--- Processing Contact 1/4 ---
Checking if contact with email 'john.doe@example.com' exists...
✅ Contact found: Henry Johnson (ID: 003fj00000IJXYzAAP)
Adding contact 003fj00000IJXYzAAP to campaign 701fj00000I5DTcAAN...
✅ Contact added to campaign successfully! (Member ID: 00vfj000005JS54AAG)

--- Processing Contact 2/4 ---
Checking if contact with email 'sarah.johnson@healthcaretest.com' exists...
✅ Contact found: Sarah Johnson (ID: 003fj00000Is42fAAB)
Adding contact 003fj00000Is42fAAB to campaign 701fj00000I5DTcAAN...
✅ Contact added to campaign successfully! (Member ID: 00vfj000005JZFJAA4)

--- Processing Contact 3/4 ---
Checking if contact with email 'mike.wilson@example.com' exists...
✅ Contact found: Evelyn Lee (ID: 003fj00000IJXdpAAH)
Adding contact 003fj00000IJXdpAAH to campaign 701fj00000I5DTcAAN...
✅ Contact added to campaign successfully! (Member ID: 00vfj000005JNfaAAG)

--- Processing Contact 4/4 ---
Checking if contact with email 'lisa.martinez@healthcaretest.com' exists...
✅ Contact found: Lisa Martinez (ID: 003fj00000Is3wEAAR)
Adding contact 003fj00000Is3wEAAR to campaign 701fj00000I5DTcAAN...
✅ Contact added to campaign successfully! (Member ID: 00vfj000005JTJcAAO)

Step 4: Verification...
Verifying campaign membership...
✅ Campaign has 4 member(s):
  • Lisa Martinez (lisa.martinez@healthcaretest.com) - Status: Sent - Added: 2025-10-02T13:57:00.000+0000
  • Evelyn Lee (mike.wilson@example.com) - Status: Sent - Added: 2025-10-02T13:56:59.000+0000
  • Sarah Johnson (sarah.johnson@healthcaretest.com) - Status: Sent - Added: 2025-10-02T13:56:58.000+0000
  • Henry Johnson (john.doe@example.com) - Status: Sent - Added: 2025-10-02T13:56:57.000+0000

=== Campaign Contact Management Complete ===
✅ Campaign: Healthcare Outreach 2025 (ID: 701fj00000I5DTcAAN)
✅ Successful additions: 4/4

```


## Optional Salesforce Tests
### Contact Creation
```bash
python create_contact.py
```

### Find Duplicate Patient IDs

Use `find_duplicate_patient_ids.py` to identify data quality issues:

```bash
python find_duplicate_patient_ids.py
```

**Features:**
- ✅ Finds all contacts with duplicate patient_id__c values
- ✅ Shows detailed information for each duplicate record  
- ✅ Provides summary statistics and recommendations
- ✅ Color-coded output for easy identification

**Sample Output:**
```
📊 SUMMARY STATISTICS:
   Total Contacts with patient_id__c: 25
   Unique patient_id__c values: 24  
   Duplicate patient_id__c values: 1
   Contacts involved in duplicates: 2

🚨 patient_id__c: 1331092.0 (2 duplicates)
   1. Name: Wendell Swift (ID: 003fj00000IM0AHAA1)
   2. Name: Wendell Swift (ID: 003fj00000INnLuAAL)
```

**Use Cases:**
- Pre-deployment data validation
- Ongoing data quality monitoring  
- Duplicate cleanup preparation
- Patient ID uniqueness verification



## Troubleshooting
_[Back to Table of Contents](#table-of-contents)_


**Verify in Salesforce**
- Navigate to Contacts tab
- Click into the `Details` view

### **Authentication Issues**

**Problem**: "invalid_client_id" or "invalid_client_secret"
**Solution**:
- Verify Consumer Key/Secret are correct
- Ensure no extra spaces in `.env` file
- Regenerate Consumer Secret if needed

**Problem**: "unsupported_grant_type"
**Solution**:
- Verify Client Credentials Flow is enabled in External Client App
- Check OAuth settings in External Client App
- Ensure "Allow Access to External App via REST API" is enabled

### **API Access Issues**

**Problem**: "insufficient_access" errors
**Solution**:
- Verify all OAuth scopes are granted
- Ensure user has appropriate Salesforce permissions
- Check IP restrictions are disabled

**Problem**: "INVALID_FIELD" errors
**Solution**:
- Verify custom fields exist (`patient_id__c`) and is appropriate case
- Check field permissions
- Ensure field API names are correct

### **Network/Connectivity Issues**

**Problem**: Connection timeouts
**Solution**:
- Check internet connectivity
- Verify Salesforce instance URL is correct
- Check if instance is in maintenance mode


### Salesforce Debug Logs

1. Setup → Debug Logs
2. Add traced entity (your user)
3. Set appropriate log levels
4. Review logs for API calls

### CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY Error Resolution
You likely missed the step for assigning your user account as a `Marketing User`.  Go back to Step 1 and ensure you didn't miss a step.


### Seeing Login History
Can see the login history in Setup | Users (scroll down).  This is helpful for debugging if the API calls are logging into Salesforce as the user.