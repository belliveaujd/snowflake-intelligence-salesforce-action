# Snowflake Setup and Configuration

This folder contains all tools and documentation for setting up Snowflake stored procedures that integrate with Salesforce, including secure credential management and agent-compatible procedures.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Setup Overview](#quick-setup-overview)
3. [Complete Setup Process](#complete-setup-process)
4. [Testing and Validation](#testing-and-validation)
5. [Snowflake Agent Configuration](#snowflake-agent-configuration)
6. [Agent Compatibility Notes](#agent-compatibility-notes)
7. [Debugging](#debugging)
8. [File Directory](#file-directory)

## Prerequisites

- ✅ Snowflake account with appropriate permissions (ACCOUNTADMIN or equivalent)
- ✅ Completed Salesforce setup (see `../Salesforce/README.md`)
- ✅ Salesforce Consumer Key (Client ID), Consumer Secret (Client Secret), and Instance URL from your Salesforce Developer Account

## Quick Setup Overview

The entire Snowflake integration can be deployed using a **single SQL file** that you run directly in Snowflake. No CLI required!

### 🎯 Setup Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                    00_snowflake_salesforce_e2e_setup.sql            │
│                         (Single File Setup)                         │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   Step 1        │ │   Step 2        │ │   Step 3        │
│   🔒 Secrets    │ │   🌐 Network    │ │   🚀 Procedure  │
│   Management    │ │   Access        │ │   Deployment    │
│                 │ │                 │ │                 │
│ • Client ID     │ │ • Network Rules │ │ • Main Proc     │
│ • Client Secret │ │ • External      │ │ • Agent-Ready   │
│ • Instance URL  │ │   Integration   │ │ • Test Cases    │
└─────────────────┘ └─────────────────┘ └─────────────────┘
          │               │               │
          └───────────────┼───────────────┘
                          ▼
              ✅ Ready for Production Use
              ✅ Compatible with Snowflake Agents
```

## Complete Setup Process

### Step 1: Update Credentials in the SQL File

1. **Open `00_snowflake_salesforce_e2e_setup.sql` in Snowflake or your preferred editor**

2. **Find the secrets section (lines 6-18) and update with your Salesforce credentials:**

```sql
-- Update these lines with your actual Salesforce credentials
CREATE OR REPLACE SECRET salesforce_client_id
TYPE = GENERIC_STRING
SECRET_STRING = "YOUR_ACTUAL_CLIENT_ID_HERE";  -- ← Replace this

CREATE OR REPLACE SECRET salesforce_client_secret
TYPE = GENERIC_STRING
SECRET_STRING = "YOUR_ACTUAL_CLIENT_SECRET_HERE";  -- ← Replace this

CREATE OR REPLACE SECRET salesforce_instance_url
TYPE = GENERIC_STRING
SECRET_STRING = "https://your-instance.my.salesforce.com";  -- ← Replace this
```

### Step 2: Execute the Complete Setup

1. **In Snowflake Web UI:**
   - Navigate to **Worksheets**
   - Copy and paste the entire `00_snowflake_salesforce_e2e_setup.sql` file
   - Update the 
   - Execute the script

2. **The script will automatically:**
   - ✅ Create secure credential storage (Secrets)
   - ✅ Configure network access rules for Salesforce
   - ✅ Deploy the `SALESFORCE_CAMPAIGN_MANAGER` procedure
   - ✅ Run test cases to validate everything works

### Step 3: Verify Installation

The script includes built-in test cases at the end. You should see successful results like:

```
CAMPAIGN: Patient ID Test Campaign 2024 | CAMPAIGN_STATUS: CREATED | 
PATIENTS_REQUESTED: 2 | PATIENTS_SUCCESSFUL: 2 | CONTACTS_CREATED: 2 | 
SUCCESS_RATE: 100.0%
```

**🎉 That's it! Your integration is ready for production use.**

## Testing and Validation

### Built-in Test Cases

The `00_snowflake_salesforce_e2e_setup.sql` file includes comprehensive test cases that automatically run when you execute the setup script. These tests validate:

**Test Scenarios Included:**
- ✅ **New Patient Creation** - Creates contacts with unique patient IDs
- ✅ **Existing Patient Lookup** - Finds existing contacts by patient_id (not email)
- ✅ **Mixed Scenarios** - Handles both new and existing patients in one campaign
- ✅ **Campaign Management** - Creates new campaigns or reuses existing ones

**Expected Test Results:**
```
Test 1: Creating new patients with unique patient IDs...
CAMPAIGN: Patient ID Test Campaign 2024 | CAMPAIGN_STATUS: CREATED | 
PATIENTS_REQUESTED: 2 | PATIENTS_SUCCESSFUL: 2 | CONTACTS_CREATED: 2 | 
SUCCESS_RATE: 100.0%

Test 2: Using same patient IDs with different emails (should find existing)...
PATIENTS_REQUESTED: 2 | PATIENTS_SUCCESSFUL: 2 | CONTACTS_CREATED: 0 | 
SUCCESS_RATE: 100.0%
```

### Additional Testing (Optional)

If you need to run additional tests, you can use the dedicated test files:

```sql
-- In Snowflake, you can also run these separate test files:
-- test_agent_compatible_procedure.sql
-- test_patient_id_lookup.sql
```

### Manual Test Call

```sql
CALL SALESFORCE_CAMPAIGN_MANAGER(
    'Manual Test Campaign',
    '[
        {
            "name": "Test Patient",
            "patient_id": 999001,
            "email": "test.patient@example.com"
        }
    ]'
);
```

## Snowflake Agent Configuration

### Setting Up the Procedure as a Custom Tool

Once your Snowflake integration is deployed, you can configure Snowflake Agents to use the `SALESFORCE_CAMPAIGN_MANAGER` procedure as a custom tool.

### Step 1: Agent Custom Tool Configuration

In your Snowflake Agent setup, configure the custom tool with these parameters:

```yaml
custom_tools:
  - name: "salesforce_campaign_manager"
    function_name: "SALESFORCE_CAMPAIGN_MANAGER"
    database: "CUR_SYNTHETIC_HEALTHCARE"
    schema: "DEMO_ASSETS"
    description: "Create Salesforce campaigns and add patient contacts automatically"
    parameters:
      - name: "campaign_name"
        type: "string"
        description: "Name of the Salesforce campaign to create or use"
        required: true
      - name: "patients_json"
        type: "string" 
        description: "JSON string array of patient objects with name, patient_id, and email"
        required: true
```

### Step 2: JSON Format for Patient Data

When the agent calls this tool, the `patients_json` parameter should be a JSON string in this format:

```json
"[
  {
    \"name\": \"John Doe\",
    \"patient_id\": 123456,
    \"email\": \"john.doe@healthcare.com\"
  },
  {
    \"name\": \"Jane Smith\", 
    \"patient_id\": 123457,
    \"email\": \"jane.smith@healthcare.com\"
  }
]"
```

### Step 3: Agent Usage Example

Your agent can now use natural language to invoke the tool:

**User:** *"Create a campaign called 'Diabetes Screening 2024' and add these patients: John Doe (ID: 300001, email: john@test.com) and Mary Johnson (ID: 300002, email: mary@test.com)"*

**Agent Response:** *"I'll create the Diabetes Screening 2024 campaign and add those patients to Salesforce."*

The agent will automatically format the request and call:
```sql
CALL SALESFORCE_CAMPAIGN_MANAGER(
  'Diabetes Screening 2024', 
  '[{"name":"John Doe","patient_id":300001,"email":"john@test.com"},{"name":"Mary Johnson","patient_id":300002,"email":"mary@test.com"}]'
)
```

## Agent Compatibility Notes

### Key Difference: Parameter Types

| **Feature** | **Agent-Compatible** | **Array-Based** |
|-------------|---------------------|------------------|
| **Parameters** | `(STRING, STRING)` | `(STRING, ARRAY)` |
| **Agent Support** | ✅ Yes | ❌ No |
| **Input Format** | JSON string | Snowflake ARRAY |
| **Functionality** | Identical | Identical |

### JSON Format for Agent-Compatible Procedure

```json
[
    {
        "name": "Patient Full Name",
        "patient_id": 123456,
        "email": "patient@email.com"
    }
]
```

### Agent Tool Configuration

When configuring Snowflake Agents, use the following for the tool description:
```yaml
function_name: SALESFORCE_CAMPAIGN_MANAGER
  - description: 

  PROCEDURE/FUNCTION DETAILS:
- Type: Custom Python Stored Procedure
- Language: Python 3.11
- Signature: (CAMPAIGN_NAME VARCHAR, PATIENTS_JSON VARCHAR)
- Returns: VARCHAR
- Execution: CALLER with CALLED ON NULL INPUT
- Volatility: VOLATILE
- Primary Function: Salesforce Campaign Management and Patient Contact Integration
- Target: Salesforce CRM campaigns and contact records
- Error Handling: Comprehensive exception handling with detailed status reporting

SAMPLE USAGE:
CALL SALESFORCE_CAMPAIGN_MANAGER(
    'Mixed Patient ID Test Campaign',
    '[
        {
            "name": "Alex Thompson",
            "patient_id": 300001,
            "email": "alex.third@healthcaretest.com"
        },
        {
            "name": "Charlie Wilson",
            "patient_id": 300003,
            "email": "charlie.wilson.pid@healthcaretest.com"
        }
    ]'
);

DESCRIPTION:
This procedure automates the creation and management of Salesforce marketing campaigns by integrating patient data from Snowflake with Salesforce CRM. It accepts a campaign name and JSON array of patient records (containing name, patient_id, and email), then either finds an existing campaign or creates a new one in Salesforce. The procedure automatically creates Contact records for patients who don't exist in Salesforce (using patient_id as the unique identifier) and adds all patients as campaign members. It provides detailed execution results including success rates, contact creation counts, and failure details, making it ideal for healthcare organizations running patient outreach campaigns. The procedure requires proper Salesforce API credentials stored in Snowflake secrets and uses OAuth2 client credentials authentication for secure integration.

USAGE SCENARIOS:
- Patient Outreach Campaigns: Launch targeted marketing campaigns for specific patient populations, such as wellness reminders, appointment scheduling, or health education initiatives
- Care Coordination: Create campaigns for care management programs, medication adherence tracking, or follow-up communications after medical procedures
- Data Synchronization: Maintain synchronized patient contact information between Snowflake analytics databases and Salesforce CRM for comprehensive patient relationship management

parameters:
  - name: CAMPAIGN_NAME
    type: string
    description: Name of the Salesforce campaign
  - name: PATIENTS_JSON  
    type: string
    description: JSON array string of patient objects
```

#### Connection Testing

```bash
# Test individual components
./test_snowflake_connection.sh

# Test specific SQL
snow sql --connection demo_admin_keypair -q "SELECT CURRENT_TIMESTAMP;"
```


### Support Resources

- [Snowflake External Functions Documentation](https://docs.snowflake.com/en/sql-reference/external-functions)
- [Snowflake Secrets Management](https://docs.snowflake.com/en/sql-reference/sql/create-secret)
- [Python UDFs in Snowflake](https://docs.snowflake.com/en/developer-guide/udf/python/udf-python)

---

## 📂 File Directory & Setup Options

### 🎯 Primary Setup Method (Recommended)

#### **Single File Setup - `00_snowflake_salesforce_e2e_setup.sql`**
```sql
-- Simply run this file in Snowflake Web UI
-- Everything is included: secrets, network rules, procedure, and tests
```
*The `00_` prefix indicates this is the complete end-to-end setup that includes all components.*

### 🔧 Alternative: Step-by-Step Setup (Advanced Users)

For users who prefer granular control, you can use the individual numbered files:

```sql
-- Step 1: Create secrets only
-- 01_snowflake_secrets_setup.sql

-- Step 2: Deploy procedure only  
-- 02_deploy_agent_procedure.sql
```

### 📁 Complete File Directory

| **File** | **Purpose** | **When to Use** |
|----------|-------------|-----------------|
| **🎯 Primary Setup** | | |
| `00_snowflake_salesforce_e2e_setup.sql` | **Complete end-to-end setup** - Secrets + Network + Procedure + Tests | **Use this for setup** ⭐ |
| **🔧 Advanced Options** | | |
| `01_snowflake_secrets_setup.sql` | **Step 1: Secrets only** - Create Snowflake secrets for credentials | Advanced users only |
| `02_deploy_agent_procedure.sql` | **Step 2: Procedure only** - Deploy SALESFORCE_CAMPAIGN_MANAGER | Advanced users only |
| **Testing Scripts** | | |
| `test_basic_connection.sh` | **Quick Snowflake CLI connectivity test** | `./test_basic_connection.sh` |
| `test_snowflake_connection.sh` | **Complete setup and integration validation** | `./test_snowflake_connection.sh` |
| `test_agent_compatible_procedure.sql` | End-to-end procedure test | Run to test |
| `test_patient_id_lookup.sql` | Test patient_id uniqueness behavior | Run to test |
| **Documentation** | | |
| `README.md` | Complete Snowflake setup guide | Reference |
| `Snowflake_Salesforce_Integration_Summary.md` | **Complete integration overview** | Reference |

## 🧪 Final Integration Validation

### ✅ Automatic Validation (Built-in)

The `00_snowflake_salesforce_e2e_setup.sql` file includes **automatic validation** at the end of execution:

**What's Automatically Validated:**
- ✅ Secrets creation and access
- ✅ External access integration setup
- ✅ Network rules configuration  
- ✅ Procedure deployment success
- ✅ End-to-end Salesforce connectivity
- ✅ Campaign and contact creation workflow

**Success Indicators to Look For:**
```sql
-- At the end of your script execution, you should see:

✅ SHOW SECRETS; -- Should list your 3 Salesforce secrets
✅ SHOW INTEGRATIONS; -- Should show SALESFORCE_SYNTHEA_INTEGRATION_JDB

-- Test results should show:
CAMPAIGN: Patient ID Test Campaign 2024 | CAMPAIGN_STATUS: CREATED | 
PATIENTS_REQUESTED: 2 | PATIENTS_SUCCESSFUL: 2 | CONTACTS_CREATED: 2 | 
SUCCESS_RATE: 100.0%
```

### 🔧 Optional CLI Validation

For advanced users who want additional CLI-based validation:

```bash
# Optional: Test CLI connectivity and environment
./test_snowflake_connection.sh
```

## Next Steps

1. ✅ **Verify test results** show 100% success rates
2. 🎯 **Configure Snowflake Agents** with the custom tool (see [Agent Configuration](#snowflake-agent-configuration))

**🚀 Your integration is ready for production use with Snowflake Agents!**
