# Snowflake Salesforce Stored Procedure Setup and Configuration

This folder contains all tools and documentation for setting up Snowflake stored procedures that integrate with Salesforce, including secure credential management and agent-compatible procedures.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Setup Overview](#setup-overview)
3. [Salesforce Integration Setup](#salesforce-integration-setup)
4. [Procedure Deployment](#data-procedure-deployment-and-agent-setup)

## Prerequisites

- ✅ Snowflake account with appropriate permissions (ACCOUNTADMIN or equivalent)
- ✅ Completed Salesforce setup (see `../Salesforce/README.md`)
- ✅ Salesforce Consumer Key (Client ID), Consumer Secret (Client Secret), and Instance URL from your Salesforce Developer Account

## Setup Overview

### 🎯 Setup Flow Diagram

```
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ 
│   Step 1        │ │   Step 2        │ │   Step 3        │
│   🔒 Secrets    │ │   🌐 Network    │  │   🚀 Procedure  │
│   Management    │ │   Access        │ │   Deployment    │
│                 │ │                 │ │                 │
│ • Client ID     │ │ • Network Rules │ │ • DB Selected   │
│ • Client Secret │ │ • External      │ │ • Agent-Ready   │
│ • Instance URL  │ │   Integration   │ │ • Agent-Ready   │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```


## Salesforce Integration Setup
This section will walk through the `Secrets Creation`, `Network Rules`, and `External Network Integration` setup. 

- Step through [01_salesforce_integration_setup.sql](./01_salesforce_integration_setup.sql) in preferred editor.

## Data, Procedure Deployment, and Agent Setup
Select the demo data that you wish to deploy into and follow the steps in that Readme.md file

### Synthea
- [Synthea Provider Data](./Synthea-Synthetic-Provider-Data/Readme.md)

### HC_PAYER_DATA_PRODUCT_SAMPLE
- [HC Payer Data](./HC-Payer-Synthetic-Data/readme.md)
