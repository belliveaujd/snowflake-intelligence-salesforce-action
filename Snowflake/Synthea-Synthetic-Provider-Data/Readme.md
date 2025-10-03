# Setup the Synthea Synthetic Dataset
These steps will walk you through how to get an instance of the Synthea Synthentic data in your account

## Table of Contents

1. [Infrastructure Setup](#infrastructure-setup)
2. [Synthea Dataset](#synthea-dataset)
3. [Deploy Functions & Procedures](#deploy-functions--procedures)
4. [Create Cortex Analyst](#create-cortex-analyst)
5. [Create Cortex Search (Optional)](#create-cortex-search-optional)
6. [Create Cortex Agent](#create-cortex-agent)
7. [Agent: Analyst Config](#tool-cortex-analyst)
8. [Agent: Cortex Search (optional)](#tool-cortex-search-optional)
9. [Agent: Custom Functions (optional)](#tool-custom-functions-optional)
10. [Agent: Custom Procedures](#tool-custom-procedures)
11. [Test the Agent](#testing-the-agent)


## Infrastructure Setup
Create the `database`, `schema`, and `warehouse` for the demo 
- Run the [01_infrastructure_setup.sql](./01_infrastructure_setup.sql)

## Synthea Dataset
The Synthea dataset is required for this demonstration.  If you already have the data, you may skip this step, but ensure you have the same database name.
- Get the [Synthentic Data](https://app.snowflake.com/marketplace/listing/GZSTZL7M0Q6/snowflake-virtual-hands-on-labs-synthetic-healthcare-data-clinical-and-claims?sortBy=popular)
- Install with the name: `SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS`


## Deploy Functions & Procedures

### Functions
- Add the Custom Functions [06_custom_functions.sql](./06_custom_functions.sql)

### Proc: SALESFORCE_CAMPAIGN_MANAGER
- Deploy the [Salesforce Campaign Procedure](./20_proc__salesforce_campaign_manager.sql)
- Test a campaign addition **_NOTE_**: Failure to add to a campaign can mean simply that the person is already in the campaign (if running for a 2nd+ time)

```SQL
CALL SALESFORCE_CAMPAIGN_MANAGER(
    'Patient ID Test Campaign 20250930-1657',
    '[
        {
            "name": "Alex Thompson",
            "patient_id": 300001,
            "email": "alex.thompson.pid@healthcaretest.com"
        },
        {
            "name": "Beth Rodriguez",
            "patient_id": 300002,
            "email": "beth.rodriguez.pid@healthcaretest.com"
        }
    ]'
);
```

**Success Example**:
```
CAMPAIGN: Patient ID Test Campaign 2024 | CAMPAIGN_STATUS: CREATED | 
PATIENTS_REQUESTED: 2 | PATIENTS_SUCCESSFUL: 2 | CONTACTS_CREATED: 2 | 
SUCCESS_RATE: 100.0%
```

**Success, but Members Already in Campaign**:
```
CAMPAIGN: Patient ID Test Campaign 20250930-1657 | CAMPAIGN_STATUS: EXISTING | PATIENTS_REQUESTED: 2 | PATIENTS_SUCCESSFUL: 0 | CONTACTS_CREATED: 0 | PATIENTS_FAILED: 2 | FAILURE_DETAILS: Alex Thompson: Failed to add to campaign; Beth Rodriguez: Failed to add to campaign | SUCCESS_RATE: 0.0%
```


## Create Cortex Analyst

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


## Create Cortex Search (Optional)

- [05_cortex_search_setup_fixed.sql](./05_cortex_search_setup_fixed.sql)


## Create Cortex Agent
_NOTE: this assumes you have setup Snowflake Intelligence according to the [Snowflake Intelligence](https://docs.snowflake.com/en/user-guide/snowflake-cortex/snowflake-intelligence)_   

Example:

```sql
-- Create official Snowflake Intelligence infrastructure
CREATE DATABASE IF NOT EXISTS snowflake_intelligence;
CREATE SCHEMA IF NOT EXISTS snowflake_intelligence.agents;
GRANT CREATE AGENT ON SCHEMA snowflake_intelligence.agents TO ROLE ACCOUNTADMIN;
```

- AI/ML > Agents > Create Agent
- **Check the box**: `Create this agent for snowflake intelligence`
- **Database and Schema**: `Snowflake_Intelligence.agents`
- **Name**: `CUR_COC_SYNTHETIC`
- **Display Name**: `Cost of Care (Synthea)`
- **Description**: `Cost of Care against the Synthea Synthetic Healthcare Dataset`
- **Sample Question 1**: `Can you show me the top 20 patients by total healthcare spending`
- **Sample Question 2**: `Can you create a chart showing how costs are distributed? I want to see if we follow the typical 80/20 rule`
- **Sample Question 3**: `Can you add Wendell Smith to a Salesforce Campaigned titled "High Cost Patients"?`

### Tool: Cortex Analyst
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

### Tool: Cortex Search (Optional)
Add the Search

- **Schema**: `CUR_SYNTHETIC_HEALTHCARE.DEMO_ASSETS`
- **Search**: `PATIENT_SEARCH_MAXIMUM_SCALE`
- **Max Results** `4`
- **ID Column**: `PATIENT_ID`
- **Title Column**: `FULL_NAME`
- **Name**: `SYNTHEA_COC_PATIENT_SEARCH`
- **Description**: `Search all 1.42M patients for comprehensive healthcare analysis with full demographic and cost data across all risk levels`

### Tool: Custom Functions (Optional)
- Add the Custom Functions [06_custom_functions.sql](./06_custom_functions.sql)

#### GENERATE_PATIENT_INSIGHTS

- **NAME:** `GENERATE_PATIENT_INSIGHTS`
- **Description**: 
```
PROCEDURE/FUNCTION DETAILS:
- Type: Custom Function
- Language: SQL
- Signature: (PATIENT_ID NUMBER)
- Returns: VARCHAR
- Execution: Caller context with standard null handling
- Volatility: Volatile (calls external AI service)
- Primary Function: AI-powered healthcare analytics and care management recommendations
- Target: Individual patient records in healthcare database
- Error Handling: Relies on Snowflake Cortex error handling and data validation

DESCRIPTION:
This custom function leverages Snowflake's Cortex AI capabilities to generate personalized care management insights and cost reduction recommendations for healthcare patients. The function takes a patient ID as input, retrieves comprehensive patient data including demographics, age, and total healthcare expenses, then uses the Snowflake Arctic AI model to analyze this information and provide three specific care management recommendations. This tool is designed for healthcare administrators, care coordinators, and clinical decision-makers who need AI-powered insights to optimize patient care while reducing costs. Users should ensure they have appropriate permissions to access patient data and be aware that the function makes external calls to Snowflake's AI services, which may impact performance and incur additional costs. The function returns AI-generated text recommendations that should be reviewed by qualified healthcare professionals before implementation.

USAGE SCENARIOS:
- Care Management Reviews: Generate personalized care recommendations during routine patient assessments or care plan updates to identify opportunities for improved outcomes and cost savings
- Population Health Analysis: Systematically analyze high-cost patients to develop targeted intervention strategies and resource allocation plans across healthcare populations
- Clinical Decision Support: Provide AI-assisted insights to healthcare providers during patient consultations to supplement clinical judgment with data-driven care management suggestions
```

#### GET_PATIENT_SUMMARY
```
PROCEDURE/FUNCTION DETAILS:
- Type: Custom Function
- Language: SQL
- Signature: (INPUT_PATIENT_ID NUMBER)
- Returns: VARCHAR
- Execution: Caller context with standard null handling
- Volatility: Stable (results consistent for same input)
- Primary Function: Patient profile report generation
- Target: Individual patient records and related healthcare data
- Error Handling: Standard SQL error propagation

DESCRIPTION:
This SQL function generates a comprehensive, formatted patient profile report by retrieving and consolidating healthcare data from multiple tables including patient demographics, encounters, and conditions. The function takes a single patient ID as input and returns a structured text report containing essential patient information such as name, age, gender, location, total healthcare costs breakdown, encounter history, active conditions count, and a calculated risk level based on total healthcare expenses. This function is designed for healthcare administrators, case managers, and clinical staff who need quick access to a patient's complete healthcare summary in a readable format. The function requires read access to the SYNTHETIC_HEALTHCARE_DATA__CLINICAL_AND_CLAIMS.SILVER schema and will return null or incomplete data if the patient ID doesn't exist or if the user lacks proper permissions. The risk level calculation automatically categorizes patients into MODERATE, HIGH, CRITICAL, or MILLION+ tiers based on their total healthcare costs, making it valuable for resource allocation and care management decisions.

USAGE SCENARIOS:
- Clinical consultations where healthcare providers need a quick overview of a patient's complete healthcare profile including costs, conditions, and encounter history
- Administrative reporting and case management workflows where staff need formatted patient summaries for insurance reviews, care coordination, or resource planning
- Healthcare analytics and auditing processes where standardized patient profiles are needed for compliance reporting, quality assessments, or population health management
```


#### GET_PATIENT_CONDITIONS
```
PROCEDURE/FUNCTION DETAILS:
- Type: Custom Function
- Language: SQL
- Signature: (PATIENT_ID NUMBER)
- Returns: VARCHAR
- Execution: Caller context with standard null handling
- Volatility: Stable (results depend on current data state)
- Primary Function: Data aggregation and concatenation
- Target: Patient condition records in clinical database
- Error Handling: Standard SQL exception handling

DESCRIPTION:
This SQL function retrieves and consolidates all medical conditions associated with a specific patient into a single, semicolon-delimited string format. The function queries the SYNTHETIC_HEALTHCARE_DATA clinical conditions table, aggregates all distinct condition descriptions for the specified patient ID, and returns them as an ordered, concatenated VARCHAR string. This is particularly useful for generating patient summary reports, creating consolidated medical histories, or preparing data for external system integrations where a compact representation of all patient conditions is required. Users should ensure they have appropriate read permissions on the underlying SILVER.CONDITIONS table and be aware that the function will return NULL if no conditions exist for the specified patient. The function is designed for read-only operations and poses no risk to data integrity, making it safe for use in reporting and analytical contexts.

USAGE SCENARIOS:
- Patient Summary Reports: Generate comprehensive medical condition summaries for clinical documentation, discharge summaries, or referral letters where all conditions need to be displayed in a compact format
- Data Export Operations: Prepare patient data for external system integrations, insurance claims processing, or research databases that require condition information in a single field
- Clinical Dashboard Development: Support real-time patient monitoring dashboards and electronic health record systems that need to display complete condition histories in limited screen space
```



### Tool: Custom Procedures
#### SALESFORCE_CAMPAIGN_MANAGER
- **Function Name:** `SALESFORCE_CAMPAIGN_MANAGER`
- **Description:** 
NOTE: _this is important for the agent's orchestration_

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
```


``` 
parameters:
  - name: CAMPAIGN_NAME
    type: string
    description: Name of the Salesforce campaign
  - name: PATIENTS_JSON  
    type: string
    description: JSON array string of patient objects
```

##### Agent Compatibility Notes
Parameter types currently have a limit.  One cannot use Array or Object types with the Cortex Agents API, hence the JSON string as a paramter for this demo.

| **Feature** | **Agent-Compatible** | **Array-Based** |
|-------------|---------------------|------------------|
| **Parameters** | `(STRING, STRING)` | `(STRING, ARRAY)` |
| **Agent Support** | ✅ Yes | ❌ No |
| **Input Format** | JSON string | Snowflake ARRAY |
| **Functionality** | Identical | Identical |






### Testing the Agent
Your agent can now use natural language to invoke the tool:

**User:** 
```
please add this member to a new campaign titled 'Test Thurs Night 2' Refugio Olson (Patient ID: 1992826)
```

**Agent Response:** 
```
I'd be happy to add Refugio Olson to the new Salesforce campaign 'Test Thurs Night 2'. However, I need his email address to create the campaign, as the Salesforce integration requires an email for each patient contact.  Could you please provide Refugio Olson's email address so I can proceed with adding him to the campaign?.
```

You can enter any test email you would like

**Agent Final Response**: 
```
Perfect! I've successfully added Refugio Olson to the new Salesforce campaign "Test Thurs Night 2".

Campaign Summary:

Campaign Name: Test Thurs Night 2
Campaign Status: Created
Patients Requested: 1
Patients Successfully Added: 1
New Contacts Created: 0 (contact already existed)
Success Rate: 100%
Refugio Olson (Patient ID: 1992826) with email testrefugio@test.com has been successfully added as a campaign member to the new campaign.

```
