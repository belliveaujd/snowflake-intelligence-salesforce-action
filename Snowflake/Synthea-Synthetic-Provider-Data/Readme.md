# Setup the Synthea Synthetic Dataset
These steps will walk you through how to get an instance of the Synthea Synthentic data in your account


## Infrastructure Setup
Create the `database`, `schema`, and `warehouse` for the demo 
- Run the [01_infrastructure_setup.sql](./01_infrastructure_setup.sql)

## Synthea Dataset
The Synthea dataset is required for this demonstration.  If you already have the data, you may skip this step, but ensure you have the same database name.
- Get the [Synthentic Data](https://app.snowflake.com/marketplace/listing/GZSTZL7M0Q6/snowflake-virtual-hands-on-labs-synthetic-healthcare-data-clinical-and-claims?sortBy=popular)
- Install with the name: `SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS`


## Cortex Analyst

### Semantic Model

1. Create stage for YAML and configuration files

```sql
USE DATABASE CUR_SYNTHENTIC_HEALTHCARE;
USE SCHEMA DEMO_ASSETS;

CREATE STAGE IF NOT EXISTS HEALTHCARE_DEMO_STAGE
  COMMENT = 'Stage for healthcare demo YAML files and configurations';
```

2.  Verify stage creation
```sql
SHOW STAGES;
```

3. List any existing files in the stage
```sql
LIST @HEALTHCARE_DEMO_STAGE;
```

4. Upload the YAML manually with Snowsight
- Navigate to Data > Databases > CUR_SYNTHETIC_HEALTHCARE > DEMO_ASSETS
- Click on Stages > HEALTHCARE_DEMO_STAGE  
- Use "Upload Files" button to upload [Enhanced_Synthea_Healthcare.yaml](./Enhanced_Synthea_Healthcare.yaml)


### Configure the Analyst
- AI & ML | Cortex Analyst 
- **Database:** `CUR_SYNTHENTIC_HEALTHCARE.DEMO_ASSETS`
- **Stage**: `HEALTHCARE_DEMO_STAGE`
- Create New button dropdown (upload your YAML) 


## Cortex Search
_Optional_

- [05_cortex_search_setup_fixed.sql](./05_cortex_search_setup_fixed.sql)

## Cortex Agent Creation
### Cortex Analyst
Add the Analyst
- **Database:** `CUR_SYNTHENTIC_HEALTHCARE.DEMO_ASSETS`
- **Stage**: `HEALTHCARE_DEMO_STAGE`
- **Name:** `CUR_Synthea_COC_Analyst`
- **Description:**
```
PATIENTS:
- Database: SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS, Schema: SILVER
- Contains core patient demographics and lifetime healthcare cost information for comprehensive patient profiling. Serves as the central hub connecting all healthcare activities and financial data across the system.
- Critical for identifying high-cost patients and understanding demographic patterns that drive healthcare expenses and utilization.
- LIST OF COLUMNS: PATIENT_ID (unique patient identifier), FIRST (first name), LAST (last name), GENDER (M/F), RACE (racial/ethnic background), CITY (residence city), STATE (residence state), MARITAL (marital status M/S), INCOME (annual income), BIRTHDATE (date of birth), DEATHDATE (date of death if applicable), HEALTHCARE_EXPENSES (total lifetime out-of-pocket costs), HEALTHCARE_COVERAGE (total lifetime insurance covered amounts)

CLAIMS:
- Database: SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS, Schema: SILVER
- Captures healthcare claims data with patient, provider, and insurance details for billing and reimbursement tracking. Links patients to specific medical services and associated costs.
- Essential for analyzing claim patterns, outstanding balances, and identifying high-cost episodes of care.
- LIST OF COLUMNS: CLAIM_ID (unique claim identifier), PATIENT_ID (links to PATIENTS table), PROVIDER_ID (links to PROVIDERS table), ENCOUNTER_ID (links to ENCOUNTERS table), PRIMARY_PATIENT_INSURANCE_ID (links to PAYERS table), SECONDARY_PATIENT_INSURANCE_ID (secondary insurance link to PAYERS), DIAGNOSIS1 (primary diagnosis SNOMED code), DIAGNOSIS2 (secondary diagnosis code), STATUS1 (claim status BILLED/CLOSED), SERVICEDATE (date of medical service), OUTSTANDING1 (primary outstanding amount), OUTSTANDING_2 (secondary outstanding amount)

CLAIMS_TX:
- Database: SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS, Schema: SILVER
- Detailed financial transactions for claims including payments, adjustments, and billing details. Provides granular view of claim financial processing and payment flows.
- Crucial for understanding payment patterns, transaction volumes, and financial reconciliation across providers and payers.
- LIST OF COLUMNS: CLAIMS_TX_ID (unique transaction identifier), CLAIM_ID (links to CLAIMS table), PATIENT_ID (links to PATIENTS table), PROVIDER_ID (links to PROVIDERS table), TYPE (transaction type PAYMENT/CHARGE/TRANSFERIN), METHOD (payment method CASH/CHECK), PROCEDURECODE (medical procedure code), FROMDATE (transaction date), AMOUNT (total transaction amount), PAYMENTS (payment amount), ADJUSTMENTS (billing adjustments), OUTSTANDING (remaining balance), UNITAMOUNT (cost per unit), UNITS (quantity billed)

ENCOUNTERS:
- Database: SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS, Schema: SILVER
- Patient encounter data including visit details, costs, and care settings. Represents individual healthcare visits and associated financial information.
- Key for analyzing utilization patterns, encounter costs, and care delivery across different settings and providers.
- LIST OF COLUMNS: ENCOUNTER_ID (unique encounter identifier), PATIENT_ID (links to PATIENTS table), PROVIDER_ID (links to PROVIDERS table), PAYER_ID (links to PAYERS table), ENCOUNTERCLASS (visit type wellness/inpatient/outpatient/emergency), CODE (encounter type code), DESCRIPTION (encounter description), REASONCODE (medical reason code), REASONDESCRIPTION (reason description), ENCOUNTER_START (visit start datetime), ENCOUNTER_STOP (visit end datetime), BASE_ENCOUNTER_COST (base encounter fee), TOTAL_CLAIM_COST (total encounter cost), PAYER_COVERAGE (insurance covered amount)

CONDITIONS:
- Database: SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS, Schema: SILVER
- Patient medical conditions and diagnoses critical for understanding cost drivers and identifying high-risk patients. Contains standardized medical coding for conditions.
- Essential for risk stratification, care management, and identifying patients requiring proactive interventions based on chronic conditions.
- LIST OF COLUMNS: CONDITION_ID (unique condition identifier), PATIENT_ID (links to PATIENTS table), ENCOUNTER_ID (links to ENCOUNTERS table), CODE (SNOMED-CT condition code), DESCRIPTION (condition name/details), SYSTEM (coding system used), CONDITION_START (diagnosis/onset date), CONDITION_STOP (resolution date if applicable)

PAYERS:
- Database: SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS, Schema: SILVER
- Insurance payer information including coverage amounts and financial performance metrics. Represents health plans and insurance companies.
- Important for understanding payer mix, reimbursement patterns, and financial relationships between providers and insurers.
- LIST OF COLUMNS: PAYER_ID (unique payer identifier), NAME (insurance/health plan name), CITY (headquarters city), STATE_HEADQUARTERED (headquarters state), AMOUNT_COVERED (total covered expenses), AMOUNT_UNCOVERED (uncovered/denied amounts), REVENUE (payer total revenue), MEMBER_MONTHS (total enrollment duration)

PROVIDERS:
- Database: SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS, Schema: SILVER
- Healthcare provider information including specialties and performance metrics. Contains physician and practitioner details with practice information.
- Critical for analyzing provider cost patterns, utilization, and quality metrics across different medical specialties and geographic regions.
- LIST OF COLUMNS: PROVIDER_ID (unique provider identifier), NAME (provider full name), SPECIALITY (medical specialty), CITY (practice city), STATE (practice state), ORGANIZATION_ID (affiliated facility/hospital), ENCOUNTERS (total patient visits), PROCEDURES (total procedures performed)

CARE_PLANS:
- Database: SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS, Schema: SILVER
- Patient care plans and treatment programs crucial for care management and intervention tracking. Documents structured care approaches for specific conditions.
- Essential for managing high-cost patients through coordinated care programs and tracking effectiveness of care interventions.
- LIST OF COLUMNS: CARE_PLAN_ID (unique care plan identifier), PATIENT_ID (links to PATIENTS table), ENCOUNTER_ID (links to ENCOUNTERS table), CODE (care plan type code), DESCRIPTION (plan/treatment description), REASONCODE (medical indication code), REASONDESCRIPTION (indication description), CAREPLAN_START (plan initiation date), CAREPLAN_STOP (plan completion date)

REASONING:
This semantic model supports comprehensive high-cost claimant analysis by integrating patient demographics, medical conditions, healthcare encounters, financial claims, and care management data. The model enables identification of cost drivers through relationships between patient characteristics, medical conditions, provider interactions, and financial outcomes. Key relationships include patients linked to their claims, encounters, conditions, and care plans, while claims connect to providers and payers for complete financial tracking. This interconnected structure allows for sophisticated analysis of healthcare utilization patterns, cost trends, risk stratification, and care management effectiveness.

DESCRIPTION:
The HIGH_COST_CLAIMANTS_HEALTHCARE_ANALYTICS semantic model provides comprehensive healthcare analytics capabilities using synthetic clinical and claims data from the SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS database. It integrates patient demographics with lifetime healthcare costs, medical conditions, provider encounters, insurance claims, financial transactions, payer information, and care management plans. The model enables sophisticated analysis of high-cost patients through interconnected relationships between patient characteristics, medical diagnoses, healthcare utilization, and financial outcomes. Key analytical capabilities include identifying cost drivers, tracking care management effectiveness, analyzing provider and payer performance, and supporting proactive care interventions for high-risk patient populations. This integrated approach supports both operational healthcare management and strategic decision-making for cost containment and quality improvement initiatives.
```

- **Warehouse:** `CURWH_HEALTHCARE_DEMO_SMALL`
- **Query Timeout:** `300`
- **Save**

### Cortex Search
Add the Search

- **Schema**: `CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS`
- **Search**: `PATIENT_SEARCH_MAXIMUM_SCALE`
- **Max Results** `4`
- **ID Column**: `PATIENT_ID`
- **Title Column**: `FULL_NAME`
- **Name**: `SYNTHEA_COC_PATIENT_SEARCH`
- **Description**: `Search all 1.42M patients for comprehensive healthcare analysis with full demographic and cost data across all risk levels`

### Custom Functions
- Add the Custom Functions [06_custom_functions.sql](./06_custom_functions.sql)
- Deploy the Salesforce Campaign Procedure





### OLD ./Snowflake/Readme.md

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

## Snowflake Agent Configuration
_NOTE: this assumes you have setup Snowflake Intelligence according to the [Snowflake Intelligence](https://docs.snowflake.com/en/user-guide/snowflake-cortex/snowflake-intelligence)_ 

#### Setup Cortex Analyst & Search
Steps take in other project... WIP on integrating docs here

#### Setting Up the Procedure as a Custom Tool

Once your Snowflake integration is deployed, you can configure Snowflake Agents to use the `SALESFORCE_CAMPAIGN_MANAGER` procedure as a custom tool.

#### Agent Custom Tool Configuration

In your Snowflake Agent setup, configure the custom tool with these parameters:

- **Function Name:** `SALESFORCE_CAMPAIGN_MANAGER`
- **Description:** _this is important for the agent's orchestration_

```
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

```
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
