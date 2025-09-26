# Salesforce Contact Layout Configuration

This guide explains how to configure Salesforce Contact page layouts to display custom fields, specifically the `patient_id__c` field used by the Snowflake integration.

## Table of Contents

1. [Custom Field Creation](#custom-field-creation)
2. [Page Layout Configuration](#page-layout-configuration)
3. [Field-Level Security](#field-level-security)
4. [List View Configuration](#list-view-configuration)
5. [Record Types and Layouts](#record-types-and-layouts)
6. [Mobile Layout Considerations](#mobile-layout-considerations)
7. [Lightning vs Classic](#lightning-vs-classic)
8. [Testing and Validation](#testing-and-validation)

## Custom Field Creation

### Step 1: Navigate to Contact Object

1. **Setup → Object Manager**
2. **Search for "Contact"** and click on it
3. **Click "Fields & Relationships"** in the left sidebar

### Step 2: Create Patient ID Field

1. **Click "New"** button
2. **Select Field Type**: Number
   - **Field Label**: `Patient ID`
   - **Field Name**: `patient_id` (automatically becomes `patient_id__c`)
   - **Data Type**: Number
   - **Length**: 18 digits (Salesforce standard)
   - **Decimal Places**: 0

3. **Field Properties**:
   - ✅ **Required**: Check this box
   - ✅ **Unique**: Check this box  
   - ✅ **External ID**: Check this box
   - ❌ **Case Sensitive**: Leave unchecked (not applicable for numbers)

4. **Default Value**: Leave blank

5. **Help Text**: 
   ```
   Unique identifier for patient records. Used for integration with external healthcare systems.
   ```

### Step 3: Field Creation Completion

1. **Click "Next"** to proceed to field-level security
2. **Set appropriate visibility** for profiles (covered in next section)
3. **Click "Next"** to add to page layouts
4. **Click "Save"** to complete field creation

## Page Layout Configuration

### Step 1: Access Page Layouts

1. **Setup → Object Manager → Contact**
2. **Page Layouts** (in left sidebar)
3. **Click "Contact Layout"** (or the layout you want to modify)

### Step 2: Add Patient ID Field

1. **Drag Patient ID field** from the field palette
2. **Drop in desired section** (recommended: "Contact Information" section)
3. **Position appropriately** (e.g., after Email field)

### Recommended Field Placement

```
Contact Information Section:
├── Name (Full Name)
├── Account Name
├── Title
├── Email
├── Patient ID        ← Add here
├── Phone
└── Mobile
```

### Step 3: Field Properties on Layout

1. **Double-click the Patient ID field** on the layout
2. **Configure display options**:
   - **Required**: ✅ Checked (since field is required)
   - **Read Only**: ❌ Unchecked (allow editing)

### Step 4: Save Layout Changes

1. **Click "Save"** to apply changes
2. **Test the layout** by creating a new contact

## Field-Level Security

### Step 1: Set Field Permissions

1. **Setup → Object Manager → Contact → Fields & Relationships**
2. **Click "Patient ID"**
3. **Click "Set Field-Level Security"**

### Step 2: Profile Permissions

Configure permissions for each profile:

| **Profile** | **Visible** | **Read Only** | **Notes** |
|-------------|-------------|---------------|-----------|
| **System Administrator** | ✅ Yes | ❌ No | Full access |
| **Standard User** | ✅ Yes | ✅ Yes | View only |
| **Healthcare Staff** | ✅ Yes | ❌ No | Edit access |
| **Integration User** | ✅ Yes | ❌ No | API access |

### Step 3: Permission Set (Optional)

Create dedicated permission set for Patient ID management:

1. **Setup → Permission Sets → New**
2. **Label**: `Patient ID Management`
3. **API Name**: `Patient_ID_Management`
4. **Object Settings → Contact**:
   - **Read**: ✅ Enabled
   - **Edit**: ✅ Enabled
5. **Field Permissions → Patient ID**:
   - **Read Access**: ✅ Enabled
   - **Edit Access**: ✅ Enabled

## List View Configuration

### Step 1: Create Patient List View

1. **Navigate to Contacts tab**
2. **List View dropdown → New**
3. **View Name**: `Patients with IDs`
4. **API Name**: `Patients_with_IDs`

### Step 2: Configure List Columns

**Recommended columns:**
```
1. Name (Contact Name)
2. Patient ID
3. Email
4. Phone
5. Account Name
6. Created Date
7. Last Modified Date
```

### Step 3: Set Filters

**Filter Criteria:**
- **Field**: Patient ID
- **Operator**: not equal to
- **Value**: (blank)

**Additional Filters (Optional):**
- **Record Type**: equals Patient (if using record types)
- **Created Date**: Last 90 Days (or relevant timeframe)

### Step 4: Sharing Settings

- **Visible to**: All Users
- **Default**: Consider making this the default view for patient management

## Record Types and Layouts

### If Using Record Types

1. **Create Patient Record Type**:
   - **Setup → Object Manager → Contact → Record Types**
   - **Name**: Patient
   - **API Name**: Patient

2. **Assign Patient Layout**:
   - Create dedicated layout: "Patient Contact Layout"
   - Include Patient ID prominently
   - Remove non-relevant fields for patients

3. **Page Layout Assignment**:
   - **Record Type → Patient** = Patient Contact Layout
   - **Record Type → Default** = Standard Contact Layout

## Mobile Layout Considerations

### Lightning Mobile Configuration

1. **Setup → Object Manager → Contact**
2. **Compact Layouts**
3. **Edit "Contact Compact Layout"**
4. **Add Patient ID** to the compact layout fields

**Recommended Compact Layout Fields:**
```
1. Name
2. Patient ID
3. Email  
4. Phone
```

### Mobile Cards

Configure mobile cards to display Patient ID prominently:
1. **Setup → Mobile Apps → Salesforce Mobile App**
2. **Mobile Navigation → Contact**
3. **Ensure Patient ID** appears in mobile views

## Lightning vs Classic

### Lightning Experience

1. **Page Layout Editor**: Drag-and-drop interface
2. **Component Library**: Can add custom components
3. **Related Lists**: Configure related campaign memberships
4. **Actions**: Add quick actions for Patient ID lookup

### Classic Experience (if still used)

1. **Page Layout Editor**: Traditional layout editor
2. **Section Configuration**: Organize fields in logical sections
3. **Field Properties**: Set required/optional at layout level

## Testing and Validation

### Step 1: Create Test Contact

1. **Navigate to Contacts**
2. **Click "New"**
3. **Verify Patient ID field appears**
4. **Enter test data**:
   - **Name**: John Doe Test
   - **Email**: john.doe.test@healthcare.com
   - **Patient ID**: 999001
5. **Save record**

### Step 2: Validate Field Behavior

1. **Uniqueness Test**:
   - Try creating another contact with Patient ID: 999001
   - Should receive error: "DUPLICATE_VALUE: duplicate value found"

2. **Required Field Test**:
   - Try saving contact without Patient ID
   - Should receive error about required field

3. **API Integration Test**:
   - Run Salesforce connection test
   - Verify Patient ID appears in API responses

### Step 3: List View Testing

1. **Navigate to Patients with IDs list view**
2. **Verify test contact appears**
3. **Confirm Patient ID column displays correctly**
4. **Test sorting by Patient ID**

### Step 4: Mobile Testing

1. **Open Salesforce mobile app**
2. **Navigate to test contact**
3. **Verify Patient ID displays in compact layout**
4. **Test editing Patient ID from mobile**

## Advanced Configuration

### Custom Lightning Components

For enhanced Patient ID functionality, consider custom Lightning components:

```javascript
// Example: Patient ID Lookup Component
<lightning-input 
    label="Patient ID"
    type="number"
    value={patientId}
    onchange={handlePatientIdChange}
    required
    message-when-value-missing="Patient ID is required"
>
</lightning-input>
```

### Validation Rules

Create validation rules for Patient ID format:

1. **Setup → Object Manager → Contact → Validation Rules**
2. **Rule Name**: `Patient_ID_Format`
3. **Formula**:
   ```
   AND(
       NOT(ISBLANK(patient_id__c)),
       OR(
           patient_id__c < 100000,
           patient_id__c > 999999
       )
   )
   ```
4. **Error Message**: `Patient ID must be between 100000 and 999999`

### Workflow/Process Builder

Automate Patient ID assignment if needed:

1. **Setup → Process Builder**
2. **New Process**: Auto-assign Patient ID
3. **Trigger**: Contact creation
4. **Action**: Field Update (if using auto-generated IDs)

## Troubleshooting

### Common Issues

**Issue**: Patient ID field not visible
- **Check**: Field-level security permissions
- **Check**: Page layout assignment
- **Check**: User profile permissions

**Issue**: Duplicate Patient ID errors
- **Verify**: Unique constraint is enabled
- **Check**: Existing data for duplicates
- **Solution**: Clean up duplicate Patient IDs

**Issue**: Mobile display problems
- **Check**: Compact layout configuration
- **Check**: Mobile app permissions
- **Verify**: Field visibility on mobile layouts

### Testing Checklist

- ✅ Patient ID field visible on contact layout
- ✅ Field appears in list views
- ✅ Uniqueness constraint working
- ✅ Required field validation working  
- ✅ Mobile display correct
- ✅ API integration can read/write field
- ✅ Proper field-level security configured

## Integration Validation

### Verify Snowflake Integration

After layout configuration, test the integration:

```bash
cd ../Snowflake
snow sql --connection demo_admin_keypair -f test_patient_id_lookup.sql
```

**Expected behavior:**
- Contacts created via Snowflake appear with Patient ID in Salesforce
- Patient ID field is used for contact deduplication
- Layout displays Patient ID prominently for manual review

---

The Patient ID field is now properly configured in your Salesforce Contact layouts and ready for integration with Snowflake procedures!
