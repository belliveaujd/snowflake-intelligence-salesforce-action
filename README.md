# Snowflake-Salesforce Healthcare Integration

A comprehensive integration solution that enables **Snowflake Agents to manage Salesforce healthcare campaigns and patient contacts** directly through stored procedures with secure credential management.

## Table of Contents
1. [Project Overview](#-project-overview)
2. [Architecture](#️-architecture)
3. [Data Setup](./README.md)
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


**Ready to get started? Begin with the [Salesforce Setup Guide](Salesforce/README.md)! 🚀**