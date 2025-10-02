#!/usr/bin/env python3
"""
Example usage of Campaign Contact Manager
Shows how to use the campaign_contact_manager functions with your own data
"""

from campaign_contact_manager import process_campaign_contacts

def example_1_simple_emails():
    """Example 1: Simple list of email addresses"""
    print("=== Example 1: Simple Email List ===")
    
    campaign_name = "Patient Wellness Check 2025"
    
    # Simple list of emails - contacts will be created with random names
    contact_list = [
        "patient1@healthcare.com",
        "patient2@healthcare.com", 
        "patient3@healthcare.com"
    ]
    
    process_campaign_contacts(campaign_name, contact_list)

def example_2_mixed_contacts():
    """Example 2: Mix of emails and detailed contact info"""
    print("=== Example 2: Mixed Contact Information ===")
    
    campaign_name = "Diabetes Prevention Program"
    
    # Mix of email strings and full contact dictionaries
    contact_list = [
        # Just email - will create contact with random name
        "mary.smith@email.com",
        
        # Full contact information
        {
            "FirstName": "Robert",
            "LastName": "Davis",
            "Email": "robert.davis@healthcare.com",
            "Phone": "(555) 111-2222"
        },
        
        # Another email only
        "james.brown@email.com",
        
        # Another detailed contact
        {
            "FirstName": "Jennifer",
            "LastName": "Wilson", 
            "Email": "jennifer.wilson@healthcare.com",
            "Phone": "(555) 333-4444"
        }
    ]
    
    process_campaign_contacts(campaign_name, contact_list)

def example_3_healthcare_specific():
    """Example 3: Healthcare-specific campaign"""
    print("=== Example 3: Healthcare Specific Campaign ===")
    
    campaign_name = "Annual Health Screening Reminder"
    
    # Healthcare-focused contact list
    contact_list = [
        {
            "FirstName": "Dr. Sarah",
            "LastName": "Thompson",
            "Email": "s.thompson@medicalpractice.com",
            "Phone": "(555) 444-5555",
            "Title": "Healthcare Provider"
        },
        {
            "FirstName": "Michael",
            "LastName": "Rodriguez",
            "Email": "m.rodriguez@patientemail.com",
            "Phone": "(555) 666-7777", 
            "Title": "Patient"
        },
        {
            "FirstName": "Emily",
            "LastName": "Chen",
            "Email": "e.chen@patientemail.com",
            "Phone": "(555) 888-9999",
            "Title": "Patient"
        }
    ]
    
    process_campaign_contacts(campaign_name, contact_list)

def custom_campaign_example():
    """Custom example - modify this for your own use"""
    print("=== Custom Campaign Example ===")
    
    # MODIFY THESE VALUES FOR YOUR OWN USE
    campaign_name = "Your Campaign Name Here"
    
    contact_list = [
        # Add your own contacts here
        "your.email@example.com",
        
        {
            "FirstName": "Your", 
            "LastName": "Contact",
            "Email": "contact@yourcompany.com",
            "Phone": "(555) 000-0000"
        }
        # Add more contacts as needed...
    ]
    
    # Uncomment the line below to run your custom campaign
    # process_campaign_contacts(campaign_name, contact_list)
    
    print("📝 Modify the campaign_name and contact_list variables above")
    print("📝 Then uncomment the process_campaign_contacts() call to run")

if __name__ == "__main__":
    
    print("Choose an example to run:")
    print("1. Simple email list")
    print("2. Mixed contact information") 
    print("3. Healthcare-specific campaign")
    print("4. Custom campaign (modify the code)")
    
    try:
        choice = input("\nEnter choice (1-4): ").strip()
        
        if choice == "1":
            example_1_simple_emails()
        elif choice == "2":
            example_2_mixed_contacts()
        elif choice == "3":
            example_3_healthcare_specific()
        elif choice == "4":
            custom_campaign_example()
        else:
            print("Invalid choice. Please run again and select 1-4.")
            
    except KeyboardInterrupt:
        print("\n\nExiting...")
    except Exception as e:
        print(f"Error: {e}")
