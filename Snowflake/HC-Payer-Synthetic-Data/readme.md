# HC Payer Setup
Demo Creator: Jeevan Rag, Josh Belliveau

## Initial Setup
- [010-HC_PAYER_DATA_PRODUCT_SETUP_Phase1.sql](010-HC_PAYER_DATA_PRODUCT_SETUP_Phase1.sql)
- Get the [HC Payer Data Share](https://app.snowflake.com/us-east-1/shb51184/#/data/shared/listing/private/GZTYZV3BWPG?originTab=databases&database=HC_PAYER_DATA_PRODUCT_SAMPLE)

## Agent Config
Salesforce(developer edition) URL and Demo credentials

- URL  : https://snowflake4-dev-ed.develop.lightning.force.com/lightning/o/Care_Plan__c/list?filterName=__Recent
- User Name :  <EMAIL>
- Password : <CREDENTIALS>

The above URL takes you to the Care Plans section, which is where the Care Plans pushed by Snowflake Intelligence would be visible.



## Cortex Agent Setup:

Add the below tools to the agent

### Analyst Semantic View
**Payer Data Product Analyst Tool referring semantic view :**  `PREP_DB_HC_PAYER_DATA_PROD.PREP_OBJECTS.HC_PAYER_DATA_PRODUCT_SEMANTIC_VIEW`

### Search Tools 
**Pubmed Search Tool :** 
- Please install the CKE and refer to that one -  [https://app.snowflake.com/marketplace/listing/GZSTZ67BY9OQW/snowflake-pubmed-biomedical-research-corpus?search=pubmed](https://app.snowflake.com/marketplace/listing/GZSTZ67BY9OQW/snowflake-pubmed-biomedical-research-corpus?search=pubmed)
- **Add as a Cortex Search:** `PUBMED_BIOMEDICAL_RESEARCH_CORPUS.OA_COMM.PUBMED_OA_CKE_SEARCH_SERVICE`
- **ID:** `Article_URL`
- **Title:** `Article_URL`


**Care Manager Calls(Audio) Search Tool**  referring cortex search :  `HC_PAYER_DATA_PRODUCT_SAMPLE.HC_PAYER_DATA_PRODUCT.CARE_MANAGER_CALLS_SEARCH_SERVICE`
- **ID Column**: `SOURCE_URL`
- **Title Column**: `AUDIO_FILE_NAME`
- **Name**: `Care_Manager_Call_Search`
- **Description**: 

**Care Plan Templates(PDF) search Tool referring cortex search:** `HC_PAYER_DATA_PRODUCT_SAMPLE.HC_PAYER_DATA_PRODUCT.CARE_PLAN_TEMPLATES_SEARCH_SERVICE`
- **ID Column**: `SOURCE_URL`
- **Title Column**: `TEMPLATE_NAME`
- **Name**: `CARE_PLAN_TEMPLATES_SEARCH_SERVICE`
- **Description**: 

### Functions
**Web Search Tool referring function:** `PREP_DB_HC_PAYER_DATA_PRODUCT.PREP_OBJECTS."WEB_SEARCH"`

**PUBLISH_CARE_PLAN_TO_SALESFORCE Tool referring function :**   `PREP_DB_HC_PAYER_DATA_PRODUCT.PREP_OBJECTS.create_care_plan`

### Procedures
**Send Email Tool referring procedure:** `PREP_DB_HC_PAYER_DATA_PRODUCT.PREP_OBJECTS."SEND_EMAIL_NOTIFICATION"`



Add the below questions for the demo flow:-

- Find the top 10 high cost claimants for Q1 2025 and evaluate their demographics and clinical information. Then, search PubMed for recent evidence-based clinical practice guidelines and research on effective preventative and proactive measures for the most prominent clinical patterns and conditions identified in this high-cost cohort. Finally, share the recommended proactive measures to curb related rising risk members, supported by the PubMed findings
- I am interested in your findings around  Respiratory challenges. Before that can you also check for any provider facility patterns across the related the related high cost claimants for this category.
- I recollect seeing a lawsuit related to high cost claims on Dell Seton Medical Center, can you perform a websearch and help me locate more information on it  and share  a contextual summary.
- Can you share me an email summarizing this crucial finding on  Dell Seton Medical Center?
- Can you identify the best fit member to launch a pilot Respiratory Care Management Program. Am looking  for  a Austin-based member active as of September 1, 2025 .Who should have respiratory-related conditions  use j% on diag code but haven't yet had  ventilation episodes use proc code  94002.
- Can you create a draft respiratory care plan referring the related care plan template. Populate the content using all available information including contact details on this member.Also take into account any additional insights available from any recent care manager interactions they had(if any)
- Looks great, now can you publish this care plan to Salesforce


After successful confirmation show the Care Plan pushed post the interactions within Snowflake Intelligence reflected within Salesforce here -  https://snowflake4-dev-ed.develop.lightning.force.com/lightning/o/Care_Plan__c/list?filterName=__Recent


Detailed Talk track with commentary : WIP


## Pending Fixes
- [ ] Remove MFA
- [ ] Semantic View with Data Share