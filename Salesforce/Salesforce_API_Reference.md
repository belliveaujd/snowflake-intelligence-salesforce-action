# Salesforce External Client API Reference

## Overview

This document provides a comprehensive reference for all available functions in the Salesforce External Client Demo Environment. The API provides functionality for connectivity testing, contact management, campaign management, and field metadata inspection.

## Table of Contents

1. [Authentication & Connectivity](#authentication--connectivity)
2. [Contact Management](#contact-management)  
3. [Campaign Management](#campaign-management)
4. [Field Metadata & Utilities](#field-metadata--utilities)
5. [Data Generation](#data-generation)
6. [Examples & Usage Patterns](#examples--usage-patterns)

---

## Authentication & Connectivity

### Environment Management

#### `load_env_file()`
**File:** `salesforce_test.py`, `create_contact.py`, `campaign_contact_manager.py`

**Description:** Loads Salesforce credentials from `.env` file.

**Parameters:** None

**Returns:** `dict` - Dictionary containing environment variables
```python
{
    'SALESFORCE_CLIENT_ID': 'your_client_id',
    'SALESFORCE_CLIENT_SECRET': 'your_client_secret', 
    'SALESFORCE_DEV_URL': 'https://your-instance.salesforce.com'
}
```

**Example:**
```python
env_vars = load_env_file()
client_id = env_vars.get('SALESFORCE_CLIENT_ID')
```

---

#### `get_access_token(client_id, client_secret, dev_url)`
**File:** `salesforce_test.py`, `create_contact.py`, `campaign_contact_manager.py`

**Description:** Obtains OAuth 2.0 access token using Client Credentials Flow.

**Parameters:**
- `client_id` (str): Salesforce Consumer Key
- `client_secret` (str): Salesforce Consumer Secret  
- `dev_url` (str): Salesforce instance URL

**Returns:** `tuple` - (access_token, instance_url)
```python
('00D...!AQEA...', 'https://instance.salesforce.com')
```

**Raises:** `SystemExit` on authentication failure

**Example:**
```python
access_token, instance_url = get_access_token(client_id, client_secret, dev_url)
```

---

### Connectivity Testing

#### `test_organization_info(access_token, instance_url)`
**File:** `salesforce_test.py`

**Description:** Tests API connectivity by querying organization information.

**Parameters:**
- `access_token` (str): Valid Salesforce access token
- `instance_url` (str): Salesforce instance URL

**Returns:** `None` (prints results to console)

**Example:**
```python
test_organization_info(access_token, instance_url)
```

---

#### `test_api_limits(access_token, instance_url)`
**File:** `salesforce_test.py`

**Description:** Tests API connectivity by checking organization limits.

**Parameters:**
- `access_token` (str): Valid Salesforce access token
- `instance_url` (str): Salesforce instance URL

**Returns:** `None` (prints API usage statistics to console)

**Example:**
```python
test_api_limits(access_token, instance_url)
```

---

## Contact Management

### Contact Creation

#### `create_contact(access_token, instance_url, contact_data)`
**File:** `create_contact.py`, `campaign_contact_manager.py`

**Description:** Creates a new Contact record in Salesforce.

**Parameters:**
- `access_token` (str): Valid Salesforce access token
- `instance_url` (str): Salesforce instance URL
- `contact_data` (dict): Contact field data

**Contact Data Structure:**
```python
{
    "FirstName": str,
    "LastName": str,           # Required
    "Email": str,
    "patient_id__c": int,      # Custom field
    "Phone": str,
    "Title": str,
    "Description": str
}
```

**Returns:** `str | None` - Contact ID if successful, None if failed
```python
'003fj00000IItScAAL'  # Contact ID on success
None                  # On failure
```

**Example:**
```python
contact_data = {
    "FirstName": "John",
    "LastName": "Doe", 
    "Email": "john.doe@example.com"
}
contact_id = create_contact(access_token, instance_url, contact_data)
```

---

#### `find_contact_by_email(access_token, instance_url, email)`
**File:** `campaign_contact_manager.py`

**Description:** Finds an existing contact by email address.

**Parameters:**
- `access_token` (str): Valid Salesforce access token
- `instance_url` (str): Salesforce instance URL  
- `email` (str): Contact email to search for

**Returns:** `tuple` - (contact_id, contact_data) or (None, None)
```python
('003fj00000IItScAAL', {
    'Id': '003fj00000IItScAAL',
    'FirstName': 'John',
    'LastName': 'Doe', 
    'Email': 'john.doe@example.com'
})
```

**Example:**
```python
contact_id, contact_data = find_contact_by_email(access_token, instance_url, "john@example.com")
```

---

#### `ensure_contact_exists(access_token, instance_url, contact_info)`
**File:** `campaign_contact_manager.py`

**Description:** Ensures a contact exists, creating it if necessary.

**Parameters:**
- `access_token` (str): Valid Salesforce access token
- `instance_url` (str): Salesforce instance URL
- `contact_info` (str | dict): Email string or contact data dictionary

**Returns:** `str | None` - Contact ID if successful
```python
'003fj00000IItScAAL'  # Existing or newly created Contact ID
```

**Example:**
```python
# With email only
contact_id = ensure_contact_exists(access_token, instance_url, "john@example.com")

# With full contact data
contact_data = {"FirstName": "John", "LastName": "Doe", "Email": "john@example.com"}
contact_id = ensure_contact_exists(access_token, instance_url, contact_data)
```

---

#### `verify_contact(access_token, instance_url, contact_id)`
**File:** `create_contact.py`

**Description:** Verifies contact creation by querying the contact back.

**Parameters:**
- `access_token` (str): Valid Salesforce access token
- `instance_url` (str): Salesforce instance URL
- `contact_id` (str): Contact ID to verify

**Returns:** `None` (prints verification results to console)

**Example:**
```python
verify_contact(access_token, instance_url, contact_id)
```

---

## Campaign Management

### Campaign Operations

#### `find_campaign_by_name(access_token, instance_url, campaign_name)`
**File:** `campaign_contact_manager.py`

**Description:** Finds an existing campaign by name.

**Parameters:**
- `access_token` (str): Valid Salesforce access token
- `instance_url` (str): Salesforce instance URL
- `campaign_name` (str): Campaign name to search for

**Returns:** `str | None` - Campaign ID if found, None if not found
```python
'701fj00000I5DTcAAN'  # Campaign ID if found
None                  # If not found
```

**Example:**
```python
campaign_id = find_campaign_by_name(access_token, instance_url, "Healthcare Outreach 2025")
```

---

#### `create_campaign(access_token, instance_url, campaign_name)`
**File:** `campaign_contact_manager.py`

**Description:** Creates a new Campaign record.

**Parameters:**
- `access_token` (str): Valid Salesforce access token
- `instance_url` (str): Salesforce instance URL
- `campaign_name` (str): Name for the new campaign

**Campaign Default Fields:**
```python
{
    "Name": campaign_name,
    "Status": "Planned",
    "Type": "Other", 
    "Description": "Test campaign created on YYYY-MM-DD HH:MM:SS",
    "StartDate": "YYYY-MM-DD",
    "IsActive": True
}
```

**Returns:** `str | None` - Campaign ID if successful, None if failed
```python
'701fj00000I5DTcAAN'  # Campaign ID on success
None                  # On failure
```

**Example:**
```python
campaign_id = create_campaign(access_token, instance_url, "Patient Outreach 2025")
```

---

### Campaign Membership

#### `add_contact_to_campaign(access_token, instance_url, campaign_id, contact_id, status="Sent")`
**File:** `campaign_contact_manager.py`

**Description:** Adds a contact to a campaign as a campaign member.

**Parameters:**
- `access_token` (str): Valid Salesforce access token
- `instance_url` (str): Salesforce instance URL
- `campaign_id` (str): Campaign ID
- `contact_id` (str): Contact ID
- `status` (str, optional): Campaign member status (default: "Sent")

**Returns:** `str | None` - CampaignMember ID if successful, None if failed
```python
'00vfj000004wUY6AAM'  # CampaignMember ID on success
None                  # On failure
```

**Example:**
```python
member_id = add_contact_to_campaign(access_token, instance_url, campaign_id, contact_id, "Responded")
```

---

#### `verify_campaign_membership(access_token, instance_url, campaign_id)`
**File:** `campaign_contact_manager.py`

**Description:** Verifies campaign membership by querying all campaign members.

**Parameters:**
- `access_token` (str): Valid Salesforce access token
- `instance_url` (str): Salesforce instance URL
- `campaign_id` (str): Campaign ID to verify

**Returns:** `None` (prints membership details to console)

**Console Output:**
```
✅ Campaign has 3 member(s):
  • John Doe (john.doe@example.com) - Status: Sent - Added: 2025-09-24T21:49:20.000+0000
  • Jane Smith (jane.smith@example.com) - Status: Responded - Added: 2025-09-24T21:49:21.000+0000
```

**Example:**
```python
verify_campaign_membership(access_token, instance_url, campaign_id)
```

---

### Complete Workflow

#### `process_campaign_contacts(campaign_name, contact_list)`
**File:** `campaign_contact_manager.py`

**Description:** Complete workflow to manage campaigns and contacts. Creates campaign if needed, creates contacts if needed, and adds all contacts to the campaign.

**Parameters:**
- `campaign_name` (str): Name of the campaign
- `contact_list` (list): List of contact information (emails or contact dicts)

**Contact List Format:**
```python
[
    "email@example.com",                    # Email only - generates random data
    {                                       # Full contact specification
        "FirstName": "John",
        "LastName": "Doe",
        "Email": "john.doe@example.com", 
        "Phone": "(555) 123-4567"
    }
]
```

**Returns:** `None` (prints workflow progress and results to console)

**Example:**
```python
campaign_name = "Healthcare Outreach 2025"
contact_list = [
    "patient1@healthcare.com",
    {
        "FirstName": "Sarah", 
        "LastName": "Johnson",
        "Email": "sarah.johnson@healthcare.com",
        "Phone": "(555) 123-4567"
    }
]

process_campaign_contacts(campaign_name, contact_list)
```

---

## Snowflake Stored Procedures

### Secure Campaign Management (Production Recommended)

#### `SALESFORCE_CAMPAIGN_MANAGER_WITH_SECRETS(campaign_name, patients)`
**File:** `snowflake_salesforce_campaign_proc_with_secrets.sql`

**Description:** Production-ready Snowflake stored procedure for complete Salesforce campaign management using secure credential storage. Uses Snowflake Secrets for credential management (no credential parameters needed).

**Parameters:**
- `campaign_name` (STRING): Name of the campaign to create/use
- `patients` (ARRAY): Array of patient objects with 'name', 'patient_id', and 'email' keys

**Patient Object Structure:**
```sql
{
    'name': 'John Doe',
    'patient_id': 100001,
    'email': 'john.doe@email.com'
}
```

**Returns:** `STRING` - Detailed result string with success/failure counts
```sql
"CAMPAIGN: Healthcare Outreach 2025 | CAMPAIGN_STATUS: CREATED | PATIENTS_REQUESTED: 3 | PATIENTS_SUCCESSFUL: 3 | CONTACTS_CREATED: 2 | SUCCESS_RATE: 100.0%"
```

**Prerequisites:** 
- Snowflake Secrets configured (see `snowflake_secrets_setup.sql`)
- External access integration configured for Salesforce

**Example:**
```sql
CALL SALESFORCE_CAMPAIGN_MANAGER_WITH_SECRETS(
    'Healthcare Outreach 2025',
    [
        {'name': 'John Doe', 'patient_id': 100001, 'email': 'john.doe@email.com'},
        {'name': 'Jane Smith', 'patient_id': 100002, 'email': 'jane.smith@email.com'}
    ]
);
```

**Security Features:**
- ✅ Credentials stored in Snowflake Secrets (never exposed)
- ✅ No credential parameters required
- ✅ Role-based access control
- ✅ Audit trail for credential access
- ✅ Easy credential rotation

### Legacy Campaign Management

#### `SALESFORCE_CAMPAIGN_MANAGER_SECURE(client_id, client_secret, instance_url, campaign_name, patients)`
**File:** `snowflake_salesforce_campaign_proc_secure.sql`

**Description:** Legacy version that accepts credentials as parameters. Use the secrets-based version for production.

**Parameters:**
- `salesforce_client_id` (STRING): Salesforce Consumer Key
- `salesforce_client_secret` (STRING): Salesforce Consumer Secret
- `salesforce_instance_url` (STRING): Salesforce instance URL
- `campaign_name` (STRING): Name of the campaign
- `patients` (ARRAY): Array of patient objects

**Returns:** `STRING` - Detailed result string

**⚠️ Note:** This version exposes credentials in query history. Use `SALESFORCE_CAMPAIGN_MANAGER_WITH_SECRETS` for production deployments.

---

## Field Metadata & Utilities

### Field Inspection

#### `check_contact_fields(access_token, instance_url)`
**File:** `check_contact_fields.py`

**Description:** Inspects Contact object metadata to identify available fields, required fields, and custom fields.

**Parameters:**
- `access_token` (str): Valid Salesforce access token
- `instance_url` (str): Salesforce instance URL

**Returns:** `bool` - True if patient_id__c field exists, False otherwise

**Console Output:**
```
✅ Found 67 fields on Contact object

📋 REQUIRED FIELDS:
  • LastName
  • Name

🔧 CUSTOM FIELDS:
  • patient_id__c
  • Languages__c
  • Level__c
  • member_id__c

📝 COMMON STANDARD FIELDS:
  ✅ FirstName
  ✅ LastName
  ✅ Email
```

**Example:**
```python
patient_id_exists = check_contact_fields(access_token, instance_url)
```

---

## Data Generation

### Fictitious Data Generation

#### `generate_fictitious_contact_data(first_name=None, last_name=None, email=None)`
**File:** `create_contact.py`, `campaign_contact_manager.py`

**Description:** Generates realistic fictitious contact data for testing purposes.

**Parameters:**
- `first_name` (str, optional): Override first name (uses random if None)
- `last_name` (str, optional): Override last name (uses random if None)  
- `email` (str, optional): Override email (generates from names if None)

**Returns:** `dict` - Complete contact data dictionary
```python
{
    "FirstName": "Emma",
    "LastName": "Johnson", 
    "Email": "emma.johnson423@healthcaretest.com",
    "patient_id__c": 234567,
    "Phone": "(555) 123-4567",
    "Title": "Patient",
    "Description": "Test contact created on 2025-09-24 17:15:25"
}
```

**Data Sources:**
- **First Names**: 29 common names (Emma, Liam, Olivia, etc.)
- **Last Names**: 30 common surnames (Smith, Johnson, Williams, etc.)
- **Patient IDs**: Random 6-digit numbers (100000-999999)
- **Phone Numbers**: Random US format: (XXX) XXX-XXXX
- **Titles**: ["Patient", "Healthcare Consumer", "Individual"]

**Example:**
```python
# Generate completely random contact
contact_data = generate_fictitious_contact_data()

# Generate with specific name
contact_data = generate_fictitious_contact_data("John", "Smith")

# Generate with specific email
contact_data = generate_fictitious_contact_data(email="custom@example.com")
```

---

## Examples & Usage Patterns

### Interactive Examples

#### `campaign_example.py`
**File:** `campaign_example.py`

**Description:** Provides interactive examples and templates for different campaign management scenarios.

**Available Examples:**
1. **Simple Email List** - Basic campaign with email addresses only
2. **Mixed Contact Information** - Campaign with emails and detailed contact data
3. **Healthcare-Specific Campaign** - Healthcare-focused campaign example
4. **Custom Campaign Template** - Customizable template

**Usage:**
```bash
python3 campaign_example.py
# Interactive menu will guide you through examples
```

---

### Complete Testing Scripts

#### Main Testing Scripts

| Script | Purpose | Key Functions |
|--------|---------|---------------|
| **`salesforce_test.py`** | Connectivity Testing | `main()`, `test_organization_info()`, `test_api_limits()` |
| **`Salesforce_test.sh`** | Bash Connectivity Testing | Bash equivalent of above |
| **`create_contact.py`** | Single Contact Creation | `main()`, `create_contact()`, `verify_contact()` |
| **`check_contact_fields.py`** | Field Metadata Analysis | `main()`, `check_contact_fields()` |
| **`campaign_contact_manager.py`** | Campaign Management | `main()`, `process_campaign_contacts()` |

---

## Error Handling

### Common Return Values

| Return Type | Success Value | Failure Value | Description |
|-------------|---------------|---------------|-------------|
| **Contact ID** | `'003fj00000IItScAAL'` | `None` | 18-character Salesforce ID |
| **Campaign ID** | `'701fj00000I5DTcAAN'` | `None` | 18-character Salesforce ID |
| **Member ID** | `'00vfj000004wUY6AAM'` | `None` | 18-character Salesforce ID |
| **Access Token** | `'00D...!AQEA...'` | `SystemExit` | OAuth token or program exit |
| **Field Check** | `True` | `False` | Boolean field existence |

### Error Handling Patterns

All functions include comprehensive error handling:
- **Network Errors**: Requests exceptions caught and logged
- **Authentication Errors**: Invalid credentials cause program exit
- **Field Validation**: Salesforce field errors displayed with details
- **Missing Data**: Graceful handling with informative messages

---

## Environment Requirements

### Required Files
- **`.env`** - Salesforce credentials (SALESFORCE_CLIENT_ID, SALESFORCE_CLIENT_SECRET, SALESFORCE_DEV_URL)
- **`requirements.txt`** - Python dependencies (requests>=2.25.0)

### Prerequisites
- Python 3.7+
- Salesforce External Client App with OAuth Client Credentials Flow enabled (Summer '25+)
- Valid Salesforce org with appropriate permissions

### Installation
```bash
pip3 install -r requirements.txt
chmod +x *.py
```

---

## Quick Reference

### Most Common Operations

```python
# Basic connectivity test
python3 salesforce_test.py

# Create a single contact  
python3 create_contact.py

# Full campaign workflow
from campaign_contact_manager import process_campaign_contacts
process_campaign_contacts("Campaign Name", ["email1@test.com", "email2@test.com"])

# Check available fields
python3 check_contact_fields.py
```

### Function Import Patterns

```python
# Import individual functions
from create_contact import create_contact, generate_fictitious_contact_data
from campaign_contact_manager import process_campaign_contacts, create_campaign
from check_contact_fields import check_contact_fields

# Use functions with your own authentication
env_vars = load_env_file()
access_token, instance_url = get_access_token(
    env_vars['SALESFORCE_CLIENT_ID'],
    env_vars['SALESFORCE_CLIENT_SECRET'], 
    env_vars['SALESFORCE_DEV_URL']
)

contact_id = create_contact(access_token, instance_url, contact_data)
```

---

*This API reference covers all available functions in the Salesforce External Client Demo Environment. All functions have been tested and verified to work with Salesforce orgs configured with OAuth Client Credentials Flow.*
