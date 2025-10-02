# Snowflake-Salesforce Healthcare Integration

A comprehensive integration solution that enables **Snowflake Agents to manage Salesforce healthcare campaigns and patient contacts** directly through stored procedures with secure credential management.

## Table of Contents
1. [Project Overview](#-project-overview)
2. [Architecture](#️-architecture)
3. [Quick Start: Salesforce](#step-1-salesforce-setup-required-first)
4. [Quick Start: Snowflake](#step-2-snowflake-integration)


## 🎯 Project Overview

This project provides demo-ready tools to:
- ✅ **Connect Snowflake to Salesforce** using OAuth 2.0 Client Credentials Flow
- ✅ **Manage healthcare campaigns** - create campaigns if they don't exist
- ✅ **Manage patient contacts** - create contacts using patient_id as unique identifier  
- ✅ **Add patients to campaigns** with comprehensive error handling
- ✅ **Secure credential management** using Snowflake Secrets
- ✅ **Agent-compatible procedures** that work with Snowflake Agents

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│ Snowflake Agent │───▶│ Stored Procedure │───▶│ Salesforce REST API │
│                 │    │ (Python)         │    │                     │
├─────────────────┤    ├──────────────────┤    ├─────────────────────┤
│ • Campaign Name │    │ • OAuth Auth     │    │ • Campaign Objects  │
│ • Patient JSON  │    │ • Contact Mgmt   │    │ • Contact Objects   │
│                 │    │ • Campaign Mgmt  │    │ • CampaignMembers   │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
```

## 🚀 Quick Start

### Step 1: Salesforce Setup (Required First)

- Navigate to the Salesforce folder and complete setup: [Salesforce Setup](./Salesforce/README.md)


### Step 2: Snowflake Integration

- After completing Salesforce setup: [Snowflake Setup](./Snowflake/README.md)

### Step 3: Configure Snowflake Agents

1. **Configure Snowflake Agents** to use the `SALESFORCE_CAMPAIGN_MANAGER` procedure


**Ready to get started? Begin with the [Salesforce Setup Guide](Salesforce/README.md)! 🚀**


## 🚨 Important Notes

### ⚠️ **Setup Order Matters**
1. **Salesforce MUST be completed first** - Snowflake needs Salesforce credentials
2. **Test each step** before proceeding to the next
3. **Keep credentials secure** - use the provided secure storage methods

### 🔐 **Security Best Practices**
- ✅ Use Snowflake Secrets for credential storage
- ✅ Never commit `.env` files to version control
- ✅ Use minimal required OAuth scopes
- ✅ Regularly rotate credentials
- ✅ Monitor access logs

### 🏥 **Healthcare Considerations**
- Patient ID is used as the primary identifier (not email)
- Contacts are deduplicated by patient_id to prevent duplicates


## 🐛 Troubleshooting

### Quick Diagnostic Commands

```bash
# Quick Salesforce credential test (fastest)
cd Salesforce && ./Salesforce_test.sh

# Comprehensive Salesforce validation
cd Salesforce && python test_connection.py

# Test complete Snowflake setup and connectivity
cd Snowflake && ./test_snowflake_connection.sh
```

## 🤝 Support

### Resources
- [Salesforce Developer Documentation](https://developer.salesforce.com/docs)
- [Snowflake Documentation](https://docs.snowflake.com)
- [OAuth 2.0 Client Credentials Flow Guide](https://help.salesforce.com/s/articleView?id=sf.remoteaccess_oauth_client_credentials_flow.htm)

