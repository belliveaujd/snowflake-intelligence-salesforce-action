# Salesforce Setup and Testing

This folder contains all tools and documentation for setting up and testing Salesforce connectivity, including API testing, contact management, and campaign management.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Salesforce Developer Instance Setup](#salesforce-developer-instance-setup)
3. [External Client App Configuration (Summer '25+)](#external-client-app-configuration-summer-25)
4. [Environment Configuration](#environment-configuration)
5. [Connection Testing](#connection-testing)
6. [Contact Management](#contact-management)
7. [Campaign Management](#campaign-management)
8. [Data Quality Analysis](#data-quality-analysis)
9. [API Reference](#api-reference)
10. [Custom Field Configuration](#custom-field-configuration)
11. [Debugging](#debugging)

## Prerequisites

- Python 3.11+
- `requests` library (`pip install requests`)
- Salesforce Developer Account
- Basic understanding of OAuth 2.0 Client Credentials Flow

## Salesforce Developer Instance Setup

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


## External Client App Configuration (Summer '25+)

### Step 1: Enable External Client Apps

1. **Navigate to External Client Apps Settings**
   - Gear Icon in the upper right → Setup → Quick Find (search on the left) → "External Client Apps"
   - Click on "Settings" tab
   - ✅ **Enable External Client Apps** (if not already enabled)

### Step 2: Create External Client App

1. **Navigate to External Client Apps**
   - Setup → Quick Find → "External Client Apps Manager"
   - Click "New External Client App"

2. **Basic Information**
   ```
   External Client App Name: Snowflake Healthcare Integration
   Description: Integration between Snowflake and Salesforce for healthcare campaigns
   Contact Email: [your email]
   Distribution State: Local
   Description: Integration between Snowflake and Salesforce for healthcare patient campaigns
   ```

3. **API (Enable OAuth Settings)**
   - **Enable OAuth**
   - **Callback URL**: `https://login.salesforce.com/services/oauth2/success`
   - **Selected OAuth Scopes**: 
     - Full access (full) - **IMPORTANT**
   - **Enable Client Credentials Flow** (accept the warning)
   - Uncheck **Require PKCE for Authorization Code Flow** 
   - **Create** button



### Step 3: OAuth Policies (post creation)
1. **OAuth Policies**
   - **Edit** button
   - **Enable Client Credentials Flow** (e.g. josh.belliveau831@agentforce.com - seen in Profile | settings, if needed)
   - **Refresh Token Policy**: "Refresh token is valid until revoked"
   - **IP Restrictions**: Remove/disable IP restrictions
   - **Save**



### Step 4: Retrieve Credentials

1. **Get Client ID and Secret**
   - Click the `Settings` tab
   - Click `Consumer Key and Secret` button/link
   - Check your email and paste the verification code
   - Copy the **Consumer Key** (Client ID) and **Consumer Secret** (Client Secret)
   - **IMPORTANT**: Store these securely as you'll need them in your .env and/or Snowflake

## Environment Configuration

### Step 1: Create Environment File

1. **Copy Template**
   ```bash
   cp env_template.txt .env
   ```

2. **Update .env File**
   ```bash
   SALESFORCE_CLIENT_ID=your_consumer_key_here
   SALESFORCE_CLIENT_SECRET=your_consumer_secret_here
   SALESFORCE_DEV_URL=https://your-domain.develop.my.salesforce.com
   ```

3. **Security Note**
   - Never commit `.env` file to version control
   - File is already in `.gitignore`

   example:
```
.env

# Logs
*.log

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# Temporary files
*.tmp
*.temp
```

## Connection Testing

### Quick Credential Test (Fastest)

For a **quick credential validation**, use the shell script:
```bash
./Salesforce_test.sh
```

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

**Use this script when:**
- ✅ You want to quickly verify credentials are working
- ✅ You've just updated your `.env` file
- ✅ You need a fast connectivity check
- ✅ You're troubleshooting authentication issues

### Comprehensive Python Test

For **detailed testing and validation**, use the comprehensive Python test:
```bash
python test_connection.py
```

**Expected Output:**
```
🚀 SALESFORCE CONNECTION TEST STARTING
✅ Environment variables loaded
✅ OAuth token retrieved successfully  
✅ API connectivity successful
✅ Contact object access successful
✅ patient_id__c custom field found
✅ Campaign object access successful
✅ Sample data creation successful
📊 Results: 6/6 tests passed
🎉 ALL TESTS PASSED! Salesforce connection is ready.
```

**Use this script when:**
- 🔧 Setting up Salesforce for the first time
- 🔧 Validating custom field configuration
- 🔧 Testing object permissions
- 🔧 Debugging integration issues

### Legacy Python Test (Simple)

For a **basic Python connectivity test**:
```bash
python salesforce_test.py
```

**Expected Output:**
```
✅ Successfully connected to Salesforce
✅ OAuth token retrieved
✅ API test successful
Current User: [Your Name]
Organization: [Your Org Name]
```

## Contact Management

### Test Contact Creation

1. **Check Required Fields**
   ```bash
   python check_contact_fields.py
   ```

2. **Create Test Contact**
   ```bash
   python create_contact.py
   ```

3. **Verify in Salesforce**
   - Navigate to Contacts tab
   - Click into the `Details` view
   
### Custom Fields

The integration uses a custom field: `patient_id__c`

**To create this field:**
1. Setup → Object Manager → Contact
2. Fields & Relationships → New
3. Field Type: Number
4. Field Label: Patient ID
5. Field Name: patient_id (will become `patient_id__c`)
6. Make field required and unique

## Campaign Management

### Test Campaign Management

```bash
python campaign_example.py
```

**Features Tested:**
- Campaign creation
- Contact creation with patient IDs
- Adding contacts to campaigns
- Batch processing

### Full Campaign Manager

```bash
python campaign_contact_manager.py
```

**Capabilities:**
- Create campaigns if they don't exist
- Create contacts if they don't exist (using patient_id as unique identifier)
- Add contacts to campaigns
- Comprehensive error handling

## Data Quality Analysis

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

## API Reference

See `Salesforce_API_Reference.md` for detailed documentation of all functions including:
- Authentication functions
- Contact management functions
- Campaign management functions
- Utility functions
- Error handling patterns

## Custom Field Configuration

### Adding patient_id__c to Contact Page Layouts

1. **Navigate to Contact Object**
   - Setup → Object Manager → Contact

2. **Create Custom Field (if not exists)**
   - Fields & Relationships → New
   - Data Type: Number
   - Field Label: Patient ID
   - Length: 10 digits
   - Decimal Places: 0
   - **External ID** - checked (useful for upserts)
   - **Required** - (I left unchecked, but you can use it)
   - **Unique** - (I left unchecked, but you can use it)
 

3. **Add to Contact Page Layout** (for contact details page)
   - Setup → Object Manager → Contact → Page Layouts (or just click **Page Layouts** if directly from last step)
   - Edit "Contact Layout" (or your custom layout)
   - Drag "Patient ID" field to desired section
   - Save layout

4. **Add to Contact List Views** (for Contacts tab list view)
   - Go to Contacts tab
   - Click the gear icon → "Select Fields to Display"
   - Add "Patient ID" to "Visible Fields"
   - Save the list view (I think the change saves immediately)
   
   OR for default list views:
   - Setup → Object Manager → Contact → List View Button Links
   - Edit the list views you want (e.g., "All Contacts", "My Contacts")
   - Add "Patient ID" field to Selected Fields

5. **Add to Campaign Member List** (for campaign member views)\
   - Setup → Object Manager → Campaign Member → Fields & Relationships
   - New → Formula
   - Field Details:
     - Field Label: `Patient ID`
     - Field Name: `Campaign_Contact_Patient_ID`
     - Data Type: `Number` (or Text if your patient_id__c is text)
     - Formula: `Contact.patient_id__c`
   - Save

6. **Add Formula Field to Campaign Members Related List** (Campaign Page):
   - Setup → Object Manager → **Campaign** → Page Layouts
   - Edit "Campaign Layout" (the main campaign page layout)
   - Scroll down to find the "Campaign Members" related list section
   - Click the **wrench/gear icon** on the "Campaign Members" related list
   - In the popup window:
     - **Available Fields** (left side): Look for your new field "Patient ID"
     - **Selected Fields** (right side): This shows what currently appears in the list
     - **Drag** "Patient ID" from Available Fields to Selected Fields
     - **Arrange** the field order as desired (drag up/down in Selected Fields)
     - **Decimal Places** 0.  (this might be on another screen)
   - Click **OK** to close the popup
   - Click **Save** on the page layout

   **Visual Guide for Campaign Members Related List**:
   ```
   Campaign Page Layout Editor:
   ┌─────────────────────────────────────┐
   │ Campaign Information Section        │
   │ ┌─── Campaign Members ──────────┐   │
   │ │ 📋 Campaign Members        🔧  │   │  ← Click the wrench icon here
   │ │ • Contact Name                 │   │
   │ │ • Status                       │   │
   │ │ • Member Type                  │   │
   │ └────────────────────────────────┘   │
   └─────────────────────────────────────┘
   
   Related List Properties Popup:
   Available Fields          Selected Fields  
   ┌─────────────────┐     ┌──────────────────┐
   │ □ Contact Patient ID │ -->  │ ✓ Contact Name      │
   │ □ Contact Email     │     │ ✓ Status           │
   │ □ Contact Phone     │     │ ✓ Contact Patient ID│ ← Drag here
   │ □ Date Created      │     │ ✓ Member Type      │
   └─────────────────┘     └──────────────────┘
   ```


## Final Result: Campaign Members List with Patient ID

After completing the setup, when you view a Campaign page, the Campaign Members section will show:

| Contact Name | Status | Contact Patient ID | Member Type |
|--------------|--------|-------------------|-------------|
| John Doe     | Sent   | 12345            | Contact     |
| Jane Smith   | Responded | 12346         | Contact     |
| Bob Johnson  | Sent   | 12347            | Contact     |

**Navigation Path to See Results**:
1. Go to Campaigns tab
2. Click on any Campaign  
3. Scroll down to "Campaign Members" related list
4. Your new "Contact Patient ID" column will be visible


## Summary: Where Patient ID Will Appear

| **Location** | **Configuration Needed** | **Result** |
|--------------|--------------------------|------------|
| **Contact Details Page** | Contact Page Layout | Patient ID shows when viewing a contact record |
| **Contacts Tab List** | Contact List Views | Patient ID appears as a column in contact lists |
| **Campaign Members List** | Campaign Member related list OR Campaign Member Page Layout | Patient ID shows in campaign member views |

**Quick Checklist:**
- ✅ Contact Page Layout (for detail page)
- ✅ Contact List Views (for Contacts tab)  
- ✅ Campaign Member related list (for campaign member views)
- ✅ Field-Level Security (for user access)


## Salesforce Setup Complete ✅

You have successfully completed the Salesforce setup! 

**Next Step**: Proceed to Snowflake integration setup:
```bash
cd ../Snowflake
open README.md
```

Or view the Snowflake setup guide: `../Snowflake/README.md`

### Troubleshooting: Patient ID Not Showing in Campaign Members

**Issue**: Contact's patient_id__c field not appearing in Campaign Member layouts/lists

**Common Solutions**:

1. **Check Field-Level Security**:
   - Ensure patient_id__c field is visible to your profile
   - Setup → Contact → Fields → patient_id__c → Set Field-Level Security

2. **Create Formula Field on Campaign Member** (Recommended Solution):
   ```
   Setup → Object Manager → Campaign Member → Fields & Relationships → New
   Field Type: Formula
   Field Label: Contact Patient ID
   Field Name: Contact_Patient_ID  
   Data Type: Number (match your patient_id__c type)
   Formula: Contact.patient_id__c
   ```
   
   **Benefits of Formula Field Approach**:
   - ✅ Always available in Campaign Member layouts
   - ✅ Works in list views, reports, and related lists  
   - ✅ Updates automatically when Contact patient_id__c changes
   - ✅ Same pattern as ContactId lookup behavior

3. **Try Different Field References** (if not using formula):
   - Look for: `Contact: Patient ID`
   - Look for: `Patient ID` 
   - Look for: `Contact.patient_id__c`
   - Look for: `Contact > Patient ID`

4. **Alternative Approach - Reports**:
   - Create a Report with Campaign Member as primary object
   - Add Contact fields including Patient ID
   - This often works when layouts don't

5. **Verify Field Exists**:
   - Go to a Contact record
   - Confirm patient_id__c field is visible and populated
   - If not visible, check Contact page layout first

### Contact List View Configuration

1. **Create Custom List View**
   - Contacts → List View dropdown → New
   - View Name: "Patients with IDs"
   - Filters: Patient ID is not blank
   - Columns: Name, Email, Patient ID, Phone, Created Date

## Debugging

### Common Issues and Solutions

#### 🔍 **Authentication Issues**

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

#### 🔍 **API Access Issues**

**Problem**: "insufficient_access" errors
**Solution**:
- Verify all OAuth scopes are granted
- Ensure user has appropriate Salesforce permissions
- Check IP restrictions are disabled

**Problem**: "INVALID_FIELD" errors
**Solution**:
- Verify custom fields exist (`patient_id__c`)
- Check field permissions
- Ensure field API names are correct

#### 🔍 **Network/Connectivity Issues**

**Problem**: Connection timeouts
**Solution**:
- Check internet connectivity
- Verify Salesforce instance URL is correct
- Check if instance is in maintenance mode

**Problem**: SSL certificate errors
**Solution**:
- Update Python `requests` library
- Check system SSL certificates
- Verify Salesforce URL uses HTTPS

#### 🔍 **Data Issues**

**Problem**: Duplicate contacts created
**Solution**:
- Verify patient_id__c field is set as unique
- Check contact lookup logic in code
- Review matching criteria

**Problem**: "REQUIRED_FIELD_MISSING" errors
**Solution**:
- Review Contact object required fields
- Update contact creation payload
- Check field-level security settings

### Debugging Tools

#### Enable Verbose Logging

Add to your Python scripts:
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

#### Test Individual Functions

Use Python interactive shell:
```python
from campaign_contact_manager import *
# Test individual functions with sample data
```

#### Salesforce Debug Logs

1. Setup → Debug Logs
2. Add traced entity (your user)
3. Set appropriate log levels
4. Review logs for API calls

### Support Resources

- [Salesforce Developer Documentation](https://developer.salesforce.com/docs)
- [REST API Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/)
- [OAuth 2.0 Client Credentials Flow](https://help.salesforce.com/s/articleView?id=sf.remoteaccess_oauth_client_credentials_flow.htm)
- [External Client Apps Documentation](https://help.salesforce.com/s/articleView?id=sf.external_client_apps_intro.htm)

---

## File Directory

| **File** | **Purpose** | **Usage** |
|----------|-------------|-----------|
| **Testing Scripts** | | |
| `Salesforce_test.sh` | **Quick credential test** - Fastest validation | `./Salesforce_test.sh` |
| `test_connection.py` | **Comprehensive test** - Full validation suite | `python test_connection.py` |
| `salesforce_test.py` | Legacy basic connection test | `python salesforce_test.py` |
| **Development Tools** | | |
| `create_contact.py` | Create test contacts with patient IDs | `python create_contact.py` |
| `check_contact_fields.py` | Inspect Contact object metadata | `python check_contact_fields.py` |
| `find_duplicate_patient_ids.py` | **Find duplicate patient_id__c records** | `python find_duplicate_patient_ids.py` |
| `campaign_contact_manager.py` | Full campaign and contact management library | `python campaign_contact_manager.py` |
| **Configuration** | | |
| `env_template.txt` | Environment variables template | Copy to `.env` |
| **Documentation** | | |
| `README.md` | Complete Salesforce setup guide | Reference |
| `Salesforce_Contact_Layout_Configuration.md` | Custom field and layout setup | Reference |
| `Salesforce_API_Reference.md` | Complete API function reference | Reference |

For integration with Snowflake, proceed to the `../Snowflake/` folder after completing Salesforce setup.
