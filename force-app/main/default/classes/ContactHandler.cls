/*******************************************************************************
* @author       Anterey Custodio
* @date         14.Sept.2015         
* @description  Class used on Contact trigger to manage DML events
* @revision 
* 2016/10/05 Mohamed Atheek (Artisan Consulting) - Added handleMerge() method for JIRA ticket CRM-503   
* 2016/11/22 Mohamed Atheek (Artisan Consulting) - Updated handleMerge() method to create Merge_History__c only when customer -> customer merges happen  
* 2016/11/29 Richard Clarke (Artisan Consulting) - Added after insert/undelete and call to method to support merging subscription status for JIRA ticket MC-109
* 2016/12/15 Mohamed Atheek (Artisan Consulting) - Updated to unsubscribe deleted contacts in the marketing cloud (JIRA ticker MC-43)
* 2017/01/16 Mohamed Atheek (Artisan Consulting) - Updated to set the subscription dates based on the subscription status (JIRA ticker MC-158)
* 2017/02/13 Jimmy Hesketh (Artisan Consulting) - Fix for marketing regions. Due to formula constraints moved into code. 
* 2017/03/14 Jimmy Hesketh (Artisan Consulting) - minor bug raised where marketing region wasn't updating in before trigger. Issue was database
* hadn't set the OtherCountryCode before the before trigger ran. Updated to fall in a after trigger. 
*******************************************************************************/
public class ContactHandler {
   /**
     * Determines whether the contact was deleted as part of a merge operation by checking if the MasterRecordId field is populated.
     * Creates a Merge_History__c record for each merged contact if the merged and master contacts are of customer record type.
     * Added for JIRA ticket CRM-503.
     * 
     * @author Mohamed Atheek (Artisan Consulting)
     * @date 2016/10/05
     * @param deletedContacts Trigger.old context variable from after delete trigger
     * @revision
     *  2016/12/15 Mohamed Atheek (Artisan Consulting) - updated to unsubscribe deleted contacts in the marketing cloud (JIRA ticker MC-43)
     *  2017/04/06 Jimmy Hesketh (Artisan Consulting) - added support for subscribers for the merge history table (JIRA ticket MC-291 and MC-312)   
     *  2017/05/01 Jimmy Hesketh (Artisan Consulting) - Added DM_Id__c to merge history table (JIRA ticket CRM-714)
     */
    public static void handleMerge(List<Contact> deletedContacts) {
        Schema.RecordTypeInfo customerRecordTypeInfo = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(IGConstants.CONTACT_RECORDTYPE_CUSTOMER);
        Schema.RecordTypeInfo subscriberRecordTypeInfo = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(IGConstants.CONTACT_RECORDTYPE_SUBSCRIBER);

        //getting all merged customer or subscriber contacts    
        List<Contact> mergedCustSubscribers = new List<Contact>();
        Set<Id> masterIds = new Set<Id>();
        Set<Id> deletedCustomers = new Set<Id>();
        for (Contact c : deletedContacts) {
            //jh - added subscriber record type to the merge scenarios 
            if (String.isNotBlank(c.MasterRecordId)) {
                mergedCustSubscribers.add(c);
                masterIds.add(c.MasterRecordId);
            }   
            deletedCustomers.add(c.Id);             
        }
        
        //filtering out non customer master contacts
        Map<Id, Contact> customerMasters = new Map<Id, Contact>(new ContactsSelector().selectByRecordTypeId(masterIds, customerRecordTypeInfo.getRecordTypeId()));
        Map<Id, Contact> subscriberMasters = new Map<Id, Contact>(new ContactsSelector().selectByRecordTypeId(masterIds, subscriberRecordTypeInfo.getRecordTypeId()));

        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new Schema.SObjectType[] { 
            Merge_History__c.SObjectType              
        });
        for (Contact c : mergedCustSubscribers) {
            if (customerMasters.containsKey(c.MasterRecordId)
                || subscriberMasters.containsKey(c.MasterRecordId)) {
                uow.registerNew(new Merge_History__c(Merged_Record_ID__c = c.Id, Master_Record_ID__c = c.MasterRecordId
                    , DM_ID__c = c.SourceId__c));
            }
        }
        uow.commitWork(); 
        
        if (!deletedCustomers.isEmpty()) {
            if(IgUtil.isMarketingCloudApiEnabled()) {
              ContactService.unsubscribeInMarketingCloud(deletedCustomers);
            }
        }
    }
    /**
     * Handles the merge of any customer or subscriber accounts. So that we don't have 
     * orphaned accounts.   
     * @date 2017/06/01
     * @param contacts list of contacts that were deleted 
    */
    public static void mergeContactAccounts(List<Contact> contacts) {
        Schema.RecordTypeInfo customerRecordTypeInfo = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(IGConstants.CONTACT_RECORDTYPE_CUSTOMER);
        Schema.RecordTypeInfo subscriberRecordTypeInfo = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(IGConstants.CONTACT_RECORDTYPE_SUBSCRIBER);

        Map<Id, String> victimAccKeyedBySurvivorId = new Map<Id, String>();
        for(Contact cont: contacts) {
            if(cont.RecordTypeId == customerRecordTypeInfo.getRecordTypeId() || cont.RecordTypeId == subscriberRecordTypeInfo.getRecordTypeId()) {
                if(String.isNotBlank(cont.MasterRecordId)) {
                    victimAccKeyedBySurvivorId.put(cont.MasterRecordId, cont.AccountId);  
                }
            }
        }

        List<Contact> survivorContacts = new ContactsSelector().selectById(victimAccKeyedBySurvivorId.keySet()); 
        for(Contact survivor :survivorContacts) {
            //now get the victim for this survivor 
            if(String.isNotBlank(victimAccKeyedBySurvivorId.get(survivor.Id)) && String.isNotBlank(survivor.AccountId)) { 
                ContactService.mergeTravelerAccounts(survivor.AccountId, victimAccKeyedBySurvivorId.get(survivor.Id)); 
            }
        }
    } 

    /* 
     * 2016/11/29 Richard Clarke (Artisan Consulting) - After insert/undelete/update propagate/blend subscription status per brand for JIRA ticket MC-109
     * Only queue subscription propogation if there are more than 1 contact sharing the same email and the context is insert, undelete or an update which changes subscriptions
     * 2017/06/19 Jimmy Hesketh (Artisan consulting) - Refactor to simplify, TC-36 changes to propagation 
     */
    public static void handleSubscriptionBlend(List<Contact> newContacts, Map<Id,Contact> oldContacts, boolean isAfterInsert, 
        boolean isAfterUpdate, boolean isAfterUndelete) {
        // Map keyed by unique email addresses to check with related contact(email plus blended subscription values only) and list of Contact IDs in trigger
        Map<string,Contact> uniqueEmails = new Map<string,Contact>();
        //stores the duplicate emails (for use case where there are duplicate contacts in the trigger context)
        List<Contact> duplicateContacts = new List<Contact>(); 
        // Build map blending subscription values in the edge case that the trigger collection has two records for the same email address 
        for(Contact c : newContacts) {
            // Only consider this new Contact if it has an email and the context is inserting, undeleting or updating with a subscription or email change
            boolean considerContact = false;
            if (( isAfterInsert || isAfterUndelete ) && ( c.Email != null )){
                considerContact = true;
            } else if ( isAfterUpdate && ( c.Email != null )){
                // Need to check to see if a subscription status has changed, find the old record in the old map
                Contact o = oldContacts.get(c.Id);
                if ( o != null){
                    if(ContactService.marketingRecordChanged(o, c)) {
                        considerContact = true;
                    } 
                }
            }
            
            // Evaluate contact for propagation if needed
            if ( considerContact == true ) {
                
                Contact newContact = populateMarketingFieldsFromContact(c); 
                if (uniqueEmails.containsKey(c.Email) == false){
                    /// New email address so just add to the map
                    uniqueEmails.put(c.Email, newContact);
                }else {
                    //handle edge case where trigger collection has duplicate emails 
                    duplicateContacts.add(newContact); 
                } 
            }
        }
        if(!duplicateContacts.isEmpty()) {
            List<Contact> contactsToProcess = new List<Contact>(); 
            for (Contact c : duplicateContacts) {
                contactsToProcess.add(c); 
                if (contactsToProcess.size() == 50 ) {
                    // Queue batch size reached so queue this batch
                    ContactMarketingSubscriptionPropagation contactPropogationJob = new ContactMarketingSubscriptionPropagation( contactsToProcess );
                    System.enqueueJob(contactPropogationJob);
                    contactsToProcess.clear();
                }
            }

            if(contactsToProcess.size() > 0) {
                // Queue batch size reached so queue this batch
                ContactMarketingSubscriptionPropagation contactPropogationJob = new ContactMarketingSubscriptionPropagation( contactsToProcess );
                System.enqueueJob(contactPropogationJob);
                contactsToProcess.clear();
            }
        }

        // If there is at least 1 email do an aggregate SOQL query to derive a count of duplicates per email address
        if (uniqueEmails.size() > 0) {
            // SOQL query to extract all contacts with 2 or more duplicates by email in the context of this trigger
            AggregateResult[] duplicatesForMerge = [select Email, Count(Id) DuplicateCount from Contact where Email in :uniqueEmails.keySet() group by Email having Count(Id) > 1];

            // For each case where there are duplicates which need propagation/merging call queueable method to run async passing Email and new Contact subscription state
            // Pass List<Contact> to queuable method to support the unusual case where the trigger collection has more than 50 contacts all with the same email address
            // Limit List<Contact> size to 50 as the execute method of the queueable class does 2 queries per record and the code needs to avoid > 200 SOQL queries
            // This means the code is bulkified as the trigger will have a max of 200 records and hence a max of 4 batches of 50 will be queued for execution
            List<Contact> contactsToPropagate = new List<Contact>();
          //  system.debug(LoggingLevel.ERROR, 'The contacts to propagate: ' + contactsToPropagate);
            for (AggregateResult ar : duplicatesForMerge) {
                contactsToPropagate.add( uniqueEmails.get((String)ar.get('Email')) );
                if ( contactsToPropagate.size() == 50 ) {
                    // Queue batch size reached so queue this batch
                    ContactMarketingSubscriptionPropagation contactPropogationJob = new ContactMarketingSubscriptionPropagation( contactsToPropagate );
                    System.enqueueJob(contactPropogationJob);
                    contactsToPropagate.clear();
                }
            }

            // Queue any residual contacts in the list
            if ( contactsToPropagate.size() > 0 ) {
                ContactMarketingSubscriptionPropagation contactPropogationJob = new ContactMarketingSubscriptionPropagation( contactsToPropagate );
                System.enqueueJob(contactPropogationJob);
            }
        }
    }

    /**
     * Populates the marketing fields on a new contact from another contact 
     * @param  c The contact to copy the marketing fields from 
     * @return  
     */
    private static Contact populateMarketingFieldsFromContact(Contact c) {
        // Setup new contact based on data in trigger collection
        return new Contact(
            Email = c.Email, 
            Id = c.Id, 
            
            Marketing_ATA__c = c.Marketing_ATA__c,
            Marketing_ATA_Date_Subscribed__c = c.Marketing_ATA_Date_Subscribed__c,
            Marketing_ATA_First_Subscribed_Date__c = c.Marketing_ATA_First_Subscribed_Date__c,
            Marketing_ATA_Source__c = c.Marketing_ATA_Source__c,
            Marketing_ATA_Date_Unsubscribed__c = c.Marketing_ATA_Date_Unsubscribed__c,
            Date_Privacy_Policy_Accepted_ATA__c = c.Date_Privacy_Policy_Accepted_ATA__c,
            Source_Type_ATA__c = c.Source_Type_ATA__c,
            
            Marketing_Geckos__c = c.Marketing_Geckos__c,
            Marketing_Geckos_Date_Subscribed__c = c.Marketing_Geckos_Date_Subscribed__c,
            Marketing_Geckos_First_Subscribed_Date__c = c.Marketing_Geckos_First_Subscribed_Date__c,
            Marketing_Geckos_Source__c = c.Marketing_Geckos_Source__c,
            Marketing_Geckos_Date_Unsubscribed__c = c.Marketing_Geckos_Date_Unsubscribed__c,
            Date_Privacy_Policy_Accepted_Geckos__c = c.Date_Privacy_Policy_Accepted_Geckos__c,
            Source_Type_Geckos__c = c.Source_Type_Geckos__c,
            
            Marketing_IG__c = c.Marketing_IG__c,
            Marketing_IG_Date_Subscribed__c = c.Marketing_IG_Date_Subscribed__c,
            Marketing_IG_First_Subscribed_Date__c = c.Marketing_IG_First_Subscribed_Date__c,
            Marketing_IG_Source__c = c.Marketing_IG_Source__c,
            Marketing_IG_Date_Unsubscribed__c = c.Marketing_IG_Date_Unsubscribed__c,
            Date_Privacy_Policy_Accepted_IG__c = c.Date_Privacy_Policy_Accepted_IG__c,
            Source_Type_IG__c = c.Source_Type_IG__c,
            
            Marketing_Intrepid__c = c.Marketing_Intrepid__c,
            Marketing_Intrepid_First_Subscribed_Date__c = c.Marketing_Intrepid_First_Subscribed_Date__c,
            Marketing_Intrepid_Source__c = c.Marketing_Intrepid_Source__c,
            Marketing_Intrepid_Date_Subscribed__c = c.Marketing_Intrepid_Date_Subscribed__c,
            Marketing_Intrepid_Date_Unsubscribed__c = c.Marketing_Intrepid_Date_Unsubscribed__c,
            Date_Privacy_Policy_Accepted_Intrepid__c = c.Date_Privacy_Policy_Accepted_Intrepid__c,
            Source_Type_Intrepid__c = c.Source_Type_Intrepid__c,
            
            Marketing_Peregrine__c = c.Marketing_Peregrine__c,
            Marketing_Peregrine_Date_Subscribed__c = c.Marketing_Peregrine_Date_Subscribed__c,
            Marketing_Peregrine_Date_Unsubscribed__c = c.Marketing_Peregrine_Date_Unsubscribed__c,
            Marketing_Peregrine_First_Subscribed_Dat__c = c.Marketing_Peregrine_First_Subscribed_Dat__c,
            Marketing_Peregrine_Source__c = c.Marketing_Peregrine_Source__c,
            Date_Privacy_Policy_Accepted_Peregrine__c = c.Date_Privacy_Policy_Accepted_Peregrine__c,
            Source_Type_Peregrine__c = c.Source_Type_Peregrine__c,

            CreatedDate = c.CreatedDate
        );
    }
    
    /**
     * Sets the subscription date fields based on the subscription status
     * Added for JIRA ticket MC-158
     * 
     * @author Mohamed Atheek (Artisan Consulting)
     * @date 2017/01/16
     * @param newContacts Trigger.new context variable from before insert or before update trigger
     * @param oldContacts Trigger.oldMap context variable from before insert or before update trigger    
     */
    public static void setMarketingSubscriptionDates(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        DateTime now = System.now();
        for (Contact newCont : newContacts) {
            Contact oldCont = oldContacts != null 
                              ? oldContacts.get(newCont.Id) //update
                              : null;                 //insert
            
            setMarketingSubscriptionDates(newCont, oldCont, now);           
        }
    }

     /**
     * @author Jimmy Hesketh (Artisan Consulting)
     * @date 2017/02/13
     * @description Based on a country code sets the marketing region appropriately. 
     * 2017/03/15 Jimmy Hesketh (Artisan Consulting) - updated method to be called in the after trigger  
     * due to issue where OtherCountryCode was not set in the before trigger from API calls. At the time of writing 
     * this was being set in records created from the UI. 
     */
    public static void setMarketingRegion(Map<Id, Contact> oldContacts, Map<Id, Contact> newContacts) {
        List<MarketingRegionMapping__mdt> mappingList = [SELECT MarketingRegion__c, OtherCountryCode__c 
                                                         FROM MarketingRegionMapping__mdt]; 

        Map<String, String> regionMap = new Map<String, String>(); 
        for(MarketingRegionMapping__mdt region : mappingList) {
            regionMap.put(region.OtherCountryCode__c, region.MarketingRegion__c); 
        }

        List<Contact> contactsForUpdate = new List<Contact>(); 
        //if there isn't a defined mapping set the contact to rest of world
        for(Contact newContact :newContacts.values()) {
            Contact contactForUpdate = new Contact(Id = newContact.Id); 
            //if called from an update make sure that otherCountry has been updated. 
            if(Trigger.isInsert || (Trigger.isUpdate && oldContacts.get(newContact.Id).OtherCountry != newContact.OtherCountry)) {
                if(regionMap.containsKey(newContact.OtherCountryCode)) {
                    contactForUpdate.Marketing_Region__c = regionMap.get(newContact.OtherCountryCode); 
                }
                else {
                    contactForUpdate.Marketing_Region__c = 'Rest of World'; 
                }

                contactsForUpdate.add(contactForUpdate); 
            }
        }

        if(contactsForUpdate != null && !contactsForUpdate.isEmpty()) {
            update contactsForUpdate; 
        }
    }

      /**
     * @author Jimmy Hesketh (Artisan Consulting)
     * @date 2017/03/22
     * @description If the contacts that are passed in are unknown subscribers (ie are a subscriber with only a email address provided)
     * then set the contact name to predefined values. 
     * @param list of contacts to be processed 
    **/
    public static void setUnknownSubscriberName(List<Contact> contacts) {
        Schema.RecordTypeInfo recordTypeInfo = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(IGConstants.CONTACT_RECORDTYPE_SUBSCRIBER);
        for(Contact cont :contacts) { 
            if(cont.RecordTypeId == recordTypeInfo.getRecordTypeId() 
                && String.isBlank(cont.FirstName) && String.isBlank(cont.LastName)) {
                cont.FirstName = IGConstants.CONTACT_UNKNOWN_NAME; 
                cont.LastName = '.';
                cont.Initially_Unknown__c = true;  
            }
        }
    }

      /**
     * @author Jimmy Hesketh (Artisan Consulting)
     * @date 2017/02/17
     * @description If the FN, LN on the contact record are blank but the contact has a passport name then 
     * sync the fields. 
     */
    public static void setStandardNameFields(List<Contact> contacts) {
        for(Contact cont : contacts) {
            if(String.isBlank(cont.FirstName) && String.isNotBlank(cont.Passport_First_Name__c)) {
                cont.FirstName = cont.Passport_First_Name__c; 
            }

            if(String.isBlank(cont.MiddleName) && String.isNotBlank(cont.Passport_Middle_Name__c)) {
                cont.MiddleName = cont.Passport_Middle_Name__c; 
            }

            if(String.isBlank(cont.LastName) && String.isNotBlank(cont.Passport_Last_Name__c)) {
                cont.LastName = cont.Passport_Last_Name__c; 
            }
        }
    }
    
    /**
     * Iterates over all the brand subscription fields and sets the corresponding subscription date fields
     * Added for JIRA ticket MC-158
     * 
     * @author Mohamed Atheek (Artisan Consulting)
     * @date 2017/01/16
     * @param newCont new contact
     * @param oldCont old contact. this will be null when called in the before insert context
     */
    private static void setMarketingSubscriptionDates(Contact newCont, Contact oldCont, DateTime now) {
        for (String brand : IgUtil.brandSubscriptionFields.keySet()) {
            Schema.SObjectField subscriptionField = IgUtil.brandSubscriptionFields.get(brand);                  
            Schema.SObjectField dateSubField = IgUtil.brandDateSubFields.get(brand);
            Schema.SObjectField firstDateSubField = IgUtil.brandFirstDateSubFields.get(brand);
            Schema.SObjectField dateUnsubField = IgUtil.brandDateUnsubFields.get(brand);
            
            
            if (isFieldChangedToValue(newCont, oldCont, subscriptionField, IGConstants.MC_SUBSCRIBED)) {
                if (newCont.get(dateSubField) ==  null || (oldCont != null && newCont.get(dateSubField) == oldCont.get(dateSubField))) {
                    //setting the date only if it is not set (null) or its an update and the subscription status changed but the date is not changed
                    newCont.put(dateSubField, now);
                }
            }
            if (isFieldChangedToValue(newCont, oldCont, subscriptionField, IGConstants.MC_SUBSCRIBED) && newCont.get(firstDateSubField) == null) {
                //should never have a subscription date older than the first date subscribed! Fixed for ART-361
                if((DateTime)newCont.get(dateSubField) < now){
                    newCont.put(firstDateSubField, newCont.get(dateSubField)); 
                }
                else {
                    newCont.put(firstDateSubField, now);
                }
            }
            if (isFieldChangedToValue(newCont, oldCont, subscriptionField, IGConstants.MC_UNSUBSCRIBED)) {
                if (newCont.get(dateUnsubField) ==  null || (oldCont != null && newCont.get(dateUnsubField) == oldCont.get(dateUnsubField))) {
                    //setting the date only if it is not set (null) or its an update and the subscription status changed but the date is not changed
                    newCont.put(dateUnsubField, now);
                }
            }
        }
    }    
   
    /**
     * If oldCont is null, checks if the value of the given field on the newCont is the given newValue.
     * If oldCont is not null, checks if the value of the given field on the newCont is the given newValue and was different on the oldCont.
     * Added for JIRA ticket MC-158
     * 
     * @author Mohamed Atheek (Artisan Consulting)
     * @date 2017/01/16
     * @param newCont new contact
     * @param oldCont old contact. this will be null when called in the before insert context
     * @param field field to check
     * @param newValue the value to check against
     */
    private static Boolean isFieldChangedToValue(Contact newCont, Contact oldCont, Schema.SObjectField field, Object newValue) {
        return newCont.get(field) == newValue &&
                (oldCont == null || //insert
                newCont.get(field) != oldCont.get(field));//update
    }

    /**
     * Pattern to call methods syncronously if they were called in a asyncronous code context and 
     * vice versa 
     * @param contactIds Set of contact ids to create new accounts for 
     */
    public static void createAccountOnContactCreation(Set<Id> contactIds) {
        if (System.isBatch() || System.isFuture() || System.isQueueable()) {
            createAccountOnContactCreationSync(contactIds);
        }
        else {
            createAccountOnContactCreationAsync(contactIds); 
        }
    }

    /**Jimmy Hesketh (Artisan Consulting) - Due to the interplay with dupeblocker this method had to be made asyncronous. Dupeblocker 
     * will not (at the time of writing) deduplicate when there are multiple objects in a transaction. The syncronous call is used 
     * in the customer 
    **/ 
    @future 
    public static void createAccountOnContactCreationAsync(Set<Id> contactIds) {
        createAccountOnContactCreation(contactIds); 
    }
    
        /**
     * Create Account with the same name as the Contact  On Contact Creation
     * Added for JIRA ticket ART-224
     * 
     * @author Shyamprasath Somaskandhan
     * @date 2017/05/03 
     * @param contacts new contacts
     */
    public static void createAccountOnContactCreationSync(Set<Id> contactIds) {
        List<Contact> contacts = new ContactsSelector().selectById(contactIds); 

        Map<Id, Account> accountMap = new Map<Id, Account>(); 
        Id personAccId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(IGConstants.ACCOUNT_RECORDTYPE_PERSON).getRecordTypeId();    
        //jh - should only be creating accounts for customer & subscriber contacts 
        Id customerRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(IGConstants.CONTACT_RECORDTYPE_CUSTOMER).getRecordTypeId();
        Id subscriberRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(IGConstants.CONTACT_RECORDTYPE_SUBSCRIBER).getRecordTypeId();  
        for(Contact cont : contacts) { 
            if((cont.RecordTypeId == customerRecordTypeId || cont.RecordTypeId == subscriberRecordTypeId) 
                && String.isBlank(cont.AccountId) 
                && (String.isNotBlank(cont.FirstName) || String.isNotBlank(cont.LastName))) {

                Account acc = new Account(Name = cont.FirstName + ' ' +cont.LastName, RecordTypeId = personAccId, Type = IGConstants.ACCOUNT_TYPE_TRAVELER); 
                accountMap.put(cont.Id, acc); 
            }
        }  
        if(!accountMap.isEmpty()) {
            insert accountMap.values();
            List<Contact> contsToUpdate = new List<Contact>(); 
            for(Id contactId :accountMap.keySet()) {
                Contact cont = new Contact(Id = contactId, AccountId = accountMap.get(contactId).Id);
                contsToUpdate.add(cont); 
            } 
            update contsToUpdate; 
        }
    }

    /**
     * Sync Account Name With Contact Name
     * Added for JIRA ticket ART-224
     * 
     * @author Shyamprasath Somaskandhan
     * @date 2017/05/03
     * @param cont contact
     */
    public static void syncAccountNameWithContactName(Map<Id, Contact> newMap, Map<Id, Contact> oldMap) {
        List<Account> accsForUpdate = new List<Account>(); 
        for(Contact cont : newMap.values()) {
            Id customerRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(IGConstants.CONTACT_RECORDTYPE_CUSTOMER).getRecordTypeId();
            Id subscriberRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(IGConstants.CONTACT_RECORDTYPE_SUBSCRIBER).getRecordTypeId();  
            if(cont.RecordTypeId == subscriberRecordTypeId || cont.RecordTypeId == customerRecordTypeId) {
                if(String.isNotBlank(cont.AccountId)) {
                    if(cont.FirstName != oldMap.get(cont.Id).FirstName || cont.LastName != oldMap.get(cont.Id).LastName) {
                        Account updateAccount = new Account(Id = cont.AccountId, Name = cont.FirstName + ' ' + cont.LastName); 
                        accsForUpdate.add(updateAccount); 
                    }
                }
            }
        } 
        try {
            if(!accsForUpdate.isEmpty()) {
                update accsForUpdate; 
            }
        }
        catch(Exception ex) {
            ExceptionHandler.AddExceptionLogRecord(ex);  
        }
    }

     /**
     * @author Shyam Prasath
     * @date 2017/07/24
     * @description Populate Other Country if Mailing Country is Populated.
     * @Ticket MC-372
     **/
    public static void populateOtherCountryIfMailingCountryIsPopulated(List<Contact> contacts) {
        for(Contact cont : contacts) {
            if(String.isBlank(cont.OtherCountry) && String.isNotBlank(cont.MailingCountry)) {
                cont.OtherCountry = cont.Mailingcountry; 
            }
        }
    }

    /**
     * Detect how the calling code has called this method and process async or sync as appropriate 
     * @param contacts list of contacts to process 
     */
    public static void attributeOpportunitiesToCampaign(List<Contact> contacts) {
        if (System.isBatch() || System.isFuture() || System.isQueueable()) {
            attributeOpportunitiesToCampaignSync(contacts); 
        }
        else {
            Set<Id> contactIds = new Set<Id>(); 
            for(Contact c :contacts) {
                contactIds.add(c.Id); 
            }
            attributeOpportunitiesToCampaignAsync(contactIds); 
        }
    }

    /**
     * @param contacts list of contacts to process 
     */
    @future
    public static void attributeOpportunitiesToCampaignAsync(Set<Id> contactIds) {

        List<Contact> contacts = new ContactsSelector().selectById(contactIds); 

        attributeOpportunitiesToCampaignSync(contacts); 
    }

    /**
     * @author Jimmy Hesketh (Artisan Consulting)
     * @date 2017/09/06 
     * @description Determine if the related opp lines need to be attributed 
     * @ticket ART-335 
     */
    public static void attributeOpportunitiesToCampaignSync(List<Contact> contacts) {
        Set<Id> contactIds = new Set<Id>(); 
        for(Contact c : contacts) {
            contactIds.add(c.Id); 
        }

        List<OpportunityLineItem> lineItems = new OpportunityLineItemsSelector().selectByContactIds(contactIds); 
        if(!lineItems.isEmpty()) {
            OpportunityLineItemHandler.attributeOpportunitiesToCampaign(lineItems); 
        }
    }

    /**
     * Based on contact information sends a http request to tealium to notify of any updates. Passes contact records into a 
     * queueble job to avoid governour limits around the number of future calls. If not running in a future context the tealium service 
     * will run the callout asyncronously. 
     * ART-351 
     * @author Jimmy Hesketh 
     * @date 15/09/2017 
     */
    public static void trackToTealium(Map<Id, Contact> contacts, Map<Id, Contact> oldContacts) {
        //then its just an insert, updates will have the old contact list
        List<Contact> contactsToTrack = new List<Contact>();  
        if(oldContacts != null && !oldContacts.isEmpty()) {
            //check if the tealium fields have changed 
            for(Contact newContact :contacts.values()) {
                Boolean hasChanged = TealiumService.tealiumContactFieldsHaveChanged(newContact, oldContacts.get(newContact.Id)); 
                if(hasChanged) {
                    contactsToTrack.add(newContact); 
                }
            }
        }
        else {
            contactsToTrack.addAll(contacts.values()); 
        }
     
        if(!contactsToTrack.isEmpty()) {
            Set<Id> contactIds = new Set<Id>(); 
            for(Contact c :contactsToTrack) {
                contactIds.add(c.Id); 
            }

            if(System.isBatch() || System.isFuture() || System.isQueueable()) {
                TealiumService.trackContactInTealium(contactIds); 
            }
            else {
                for(Set<Id> contactList : IGUtil.slice(contactIds, 95)) { 
                    ContactTrackInTealiumQueueable contactTrack = new ContactTrackInTealiumQueueable(contactList); 
                    System.enqueueJob(contactTrack);    
                }
            }
        }
    }
    
    public static void deactivateContacts(List<Contact> newContacts, Map<Id, Contact> oldContacts){
        for(Contact updatedContact : newContacts){
            Contact oldContact = 
                (oldContacts != null) ? oldContacts.get(updatedContact.Id) : null;
            
            ContactAgentPortalAccessHandler.deactivateContact(updatedContact, oldContact);
        }
    }

    public static void updateContactTotalTripsAndSalePrice(List<Opportunity> opportunities){
        Set<Id> opportunityIds = new Set<Id>();
        for (Opportunity opp: opportunities) {
            opportunityIds.add(opp.Id);
        }

        OpportunityLineItemsSelector lineItemSelector = new OpportunityLineItemsSelector();

        //Find line items for each opportunity
        List<OpportunityLineItem> opportunityLineItems = 
            lineItemSelector.selectTripsForOpportunityIds(opportunityIds);

        //Find unique Contacts
        Set<Id> contactIds = new Set<Id>();
        for (OpportunityLineItem lineItem : OpportunityLineItems) {
           if(!contactIds.contains(lineItem.Traveller__c)){
               contactIds.add(lineItem.Traveller__c);
           }
        }

        //Find all line items for contacts
        List<OpportunityLineItem> contactLineItems = 
            lineItemSelector.selectByContactIds(contactIds);

        List<Contact> contactsToUpdate = new List<Contact>();

        for (Id contactId : contactIds) {
            ContactTripTotalHelper contactHelper = 
                getContactTripTotalHelper(contactId, contactLineItems);

            contactsToUpdate.add(new Contact(Id = contactId, Lifetime_Value__c = contactHelper.totalSalePrice, Number_Of_Trips__c = contactHelper.tripCount));
        }
        
        update contactsToUpdate;
    }

    private static ContactTripTotalHelper getContactTripTotalHelper(Id contactId, List<OpportunityLineItem> lineItems){
        ContactTripTotalHelper contactTotalHelper = new ContactTripTotalHelper(contactId);       

        for (OpportunityLineItem lineItem : lineItems) {
            if(lineItem.Traveller__c == contactId
                && (lineItem.BDM_Stage__c == 'Confirmed'
                    || lineItem.BDM_Stage__c == 'FullyPaid'
                    || lineItem.BDM_Stage__c == 'Ticketed')){

                    contactTotalHelper.addTrip(lineItem);
            }
        }

        return contactTotalHelper;
    }

    private class ContactTripTotalHelper {
        public Id contactId { get; set; }
        public Integer tripCount { get; set; }
        public Decimal totalSalePrice { get; set; }

        public ContactTripTotalHelper(Id contactId){
            this.contactId = contactId;
            tripCount = 1;
            totalSalePrice = 0;
        }

        public void addTrip(OpportunityLineItem lineItem){
            tripCount = tripCount + 1;
            totalSalePrice = totalSalePrice + lineItem.TotalPrice;
        }
    }
}