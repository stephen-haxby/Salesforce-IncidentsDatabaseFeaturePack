/*******************************************************************************
* @author       Anterey Custodio
* @date         15.Sept.2015
* @description  test class for ContactHandler
* @revision 
*   2016/10/05 Mohamed Atheek (Artisan Consulting) - Added more test methods
*   2016/11/22 Mohamed Atheek (Artisan Consulting) - Added test method to verify that non Customer merges do not create Merge_History__c records    
*   2016/01/13 Mohamed Atheek (Artisan Consulting) - Removed some of the subscription fields from propagation as requested in JIRA ticket MC-220 (related to MC-109). 
*   2017/01/25 Mohamed Atheek (Artisan Consulting) - Replaced references to TestDataHelper with the new TestDataFactory class (ART-82)
*******************************************************************************/
@isTest(isparallel=true)
private class ContactHandlerTest {
   /** 
    * Tests ContactHandler.handleMerge() method. Following cases are tested,
    * - One Merge_History__c record is created for each merged record
    * - Old Merge_History__c records are retained even if a record that was the master in a previous merge was merged into another record
    * - Deletes that are not part of a merge operation do not create Merge_History__c records 
    * 
    * @author Mohamed Atheek (Artisan Consulting)
    * @date 2016/10/05 
    */
    static testMethod void testHandleMergeCustomer() {
        Test.setMock(HttpCalloutMock.class, new TealiumCollectHttpMockImpl());
        //inserting 10 customer contacts
        List<Contact> contacts = TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_CUSTOMER, 10);
        insert contacts;
      
        String[] contactsIds = new List<String>();
        for (Contact c : contacts) {
            contactsIds.add(c.Id);
        }

        System.assertEquals(0, [SELECT count() FROM Merge_History__c]);
  
        Test.startTest();
  
        merge contacts[0] contacts[1];
        merge contacts[0] contacts[2];
        merge contacts[0] new List<Contact> {contacts[3], contacts[4]};
  
        merge contacts[6] contacts[0];
  
        delete contacts[5];
  
        Test.stopTest();
  
        //asserting 5 merge history records have been created corresponsing to each merged record
        System.assertEquals(5, [SELECT count() FROM Merge_History__c]);
  
        //asserting contactsIds[0] was the master in 4 merges and contactsIds[6] was the master in 1 merge
        System.assertEquals(4, [SELECT count() FROM Merge_History__c WHERE Master_Record_ID__c = :contactsIds[0]]);
        System.assertEquals(1, [SELECT count() FROM Merge_History__c WHERE Master_Record_ID__c = :contactsIds[6]]);
  
        //asserting the mergered record in each merge 
        System.assertEquals(1, [SELECT count() FROM Merge_History__c WHERE Merged_Record_ID__c = :contactsIds[0]]);
        System.assertEquals(1, [SELECT count() FROM Merge_History__c WHERE Merged_Record_ID__c = :contactsIds[1]]);
        System.assertEquals(1, [SELECT count() FROM Merge_History__c WHERE Merged_Record_ID__c = :contactsIds[2]]);
        System.assertEquals(1, [SELECT count() FROM Merge_History__c WHERE Merged_Record_ID__c = :contactsIds[3]]);
        System.assertEquals(1, [SELECT count() FROM Merge_History__c WHERE Merged_Record_ID__c = :contactsIds[4]]); 
  
        //asserting normal deletes (ie not a delete resulting from a merge) do not create merge history records
        System.assertEquals(0, [SELECT count() FROM Merge_History__c WHERE Merged_Record_ID__c = :contactsIds[5]]);     
    }  
    
    /** 
    * Tests ContactHandler.handleMerge() method. Following cases are tested,
    * - One Merge_History__c record is created for each merged record
    * - Old Merge_History__c records are retained even if a record that was the master in a previous merge was merged into another record
    * - Deletes that are not part of a merge operation do not create Merge_History__c records 
    * - Same as merge scenario above except checks the Subscriber record type is being merged correctly. 
    * - Added as part of MC-312 
    * @author Jimmy Hesketh (Artisan Consulting)
    * @date 2017/04/06 
    */
    static testMethod void testHandleMergeSubscriber() {
        //inserting 10 customer contacts
        List<Contact> contacts = TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_SUBSCRIBER, 10);
        insert contacts;
      
        String[] contactsIds = new List<String>();
        for (Contact c : contacts) {
            contactsIds.add(c.Id);
        }

        System.assertEquals(0, [SELECT count() FROM Merge_History__c]);
  
        Test.startTest();
  
        merge contacts[0] contacts[1];
        merge contacts[0] contacts[2];
        merge contacts[0] new List<Contact> {contacts[3], contacts[4]};
  
        merge contacts[6] contacts[0];
  
        delete contacts[5];
  
        Test.stopTest();
  
        //asserting 5 merge history records have been created corresponsing to each merged record
        System.assertEquals(5, [SELECT count() FROM Merge_History__c]);
  
        //asserting contactsIds[0] was the master in 4 merges and contactsIds[6] was the master in 1 merge
        System.assertEquals(4, [SELECT count() FROM Merge_History__c WHERE Master_Record_ID__c = :contactsIds[0]]);
        System.assertEquals(1, [SELECT count() FROM Merge_History__c WHERE Master_Record_ID__c = :contactsIds[6]]);
  
        //asserting the mergered record in each merge 
        System.assertEquals(1, [SELECT count() FROM Merge_History__c WHERE Merged_Record_ID__c = :contactsIds[0]]);
        System.assertEquals(1, [SELECT count() FROM Merge_History__c WHERE Merged_Record_ID__c = :contactsIds[1]]);
        System.assertEquals(1, [SELECT count() FROM Merge_History__c WHERE Merged_Record_ID__c = :contactsIds[2]]);
        System.assertEquals(1, [SELECT count() FROM Merge_History__c WHERE Merged_Record_ID__c = :contactsIds[3]]);
        System.assertEquals(1, [SELECT count() FROM Merge_History__c WHERE Merged_Record_ID__c = :contactsIds[4]]); 
  
        //asserting normal deletes (ie not a delete resulting from a merge) do not create merge history records
        System.assertEquals(0, [SELECT count() FROM Merge_History__c WHERE Merged_Record_ID__c = :contactsIds[5]]);     
    }  

    /**
     * Tests that the source ID is maintained within the merge history object 
     * @return [description]
     */
    static testMethod void testHandleMergeSourceId() {
            //inserting 10 customer contacts
        List<Contact> contacts = TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_SUBSCRIBER, 10);
        contacts[0].SourceId__c = 'contact0'; 
        insert contacts;
      
        String[] contactsIds = new List<String>();
        for (Contact c : contacts) {
            contactsIds.add(c.Id);
        }

        System.assertEquals(0, [SELECT count() FROM Merge_History__c]);
  
        Test.startTest();
  
        merge contacts[0] contacts[1];
        merge contacts[0] contacts[2];
        merge contacts[0] new List<Contact> {contacts[3], contacts[4]};
  
        merge contacts[6] contacts[0];
        //only one record should have the dm_id populated thus only one should be returned 
        List<Merge_History__c> mergeHistories = [SELECT Id, DM_ID__c FROM Merge_History__c WHERE DM_ID__c = 'contact0']; 
        system.assertEquals(1, mergeHistories.size()); 
        Test.stopTest(); 
    }
    
   /** 
    * This test method performs the following bulk data operations and verifies that "Exception Message: Update failed. First exception on row 0 with id a0WN0000003ClueMAC; first error: UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record:"" []
    * error which was observed in the customer sandbox does not occur
    *   - insert 500 Contacts
    *  - insert 150 duplicate Contacts (duplicates of the first 150 of those 500 Contacts)
    *   - delete 250 non duplicate Contacts (last 250 of those 500 Contacts)
    *
    * @author Mohamed Atheek (Artisan Consulting)
    * @date 2016/11/02 
    */
    static testMethod void testBulkDeletes() {
        Test.setMock(HttpCalloutMock.class, new TealiumCollectHttpMockImpl());
        //Create DupeBlocker Scenarios
        CRMfusionDBR101__Scenario__c scenario = TestDataFactory.createDupeBlockerScenario(
          'Contact - FirstName, LastName, Email', 'Contact');
        scenario.CRMfusionDBR101__Match_on_Insert_Action__c = 'Auto-Merge';
        insert scenario;

        //Create DupeBlocker Rules
        List<CRMfusionDBR101__Scenario_Rule__c> rules = new List<CRMfusionDBR101__Scenario_Rule__c> {
          TestDataFactory.createDupeBlockerRule(scenario, 'Contact', 'First Name', 'First Name'),
          TestDataFactory.createDupeBlockerRule(scenario, 'Contact', 'Last Name', 'Exact'),
          TestDataFactory.createDupeBlockerRule(scenario, 'Contact', 'Email', 'Exact')
        };    
        insert rules;
        
        //Creating 1000 Contact reocords
        List<Contact> contacts = TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_CUSTOMER, 500);
        insert contacts;
        
        //Rebuild DupeBlocker keys so that DupeBlocker can run the matching scenarios
        CRMfusionDBR101.DB_Api.rebuildKeys(new List<Id>(new Map<Id, Contact>(contacts).keySet()));
        
        Test.startTest();
        
        //Inserting 300 duplicates. Most probably Dupeblocker will not run on bulk inserts but if runs then the after delete contact trigger should not fail
        List<Contact> duplicateContacts = new List<Contact>();
        for (Integer i = 0; i < 150; i++) {
          duplicateContacts.add(TestDataFactory.createContact(
            null,contacts[i].FirstName, contacts[i].LastName, contacts[i].Email, IGConstants.CONTACT_RECORDTYPE_CUSTOMER));
        }
        insert duplicateContacts;
        
        //Delete 500 non-duplicate contacts
        List<Contact> contactsToDelete = new List<Contact>();
        for (Integer i = 250; i < 500; i++) {
          contactsToDelete.add(contacts[i]);
        }
        delete contactsToDelete;
        
        Test.stopTest();
        
        //Asserting deleted contacts do not exist
        System.assertEquals(0 , [SELECT count() FROM Contact WHERE Id IN :contactsToDelete]);
        
        //Asserting that non of the bulk deleted Contacts end up in the Merge History table
        System.assertEquals(0, [SELECT count() FROM Merge_History__c WHERE Merged_Record_ID__c IN :new Map<ID, Contact>(contactsToDelete).keySet()]);
        //Succesful run of this method implies that the UNABLE_TO_LOCK_ROW exception was not thown
    }
    
  

    /** 
    * @author Jimmy Hesketh (Artisan Consulting)
    * @date 2017/02/13
    * @description tests the mapping works in a positive test case ("happy path")
    **/ 
    static testMethod void setMarketingRegionPositiveTest() { 
        List<Contact> contacts = TestDataFactory.createContacts('customer', 1); 
        contacts[0].OtherCountryCode = 'AU'; 
        
        Test.startTest(); 
        insert contacts; 

        List<Contact> conts = [SELECT Marketing_Region__c FROM Contact];  
        system.assertEquals(conts[0].Marketing_Region__c, 'Australia'); 
        Test.stopTest(); 
    }

    /** 
    * @author Jimmy Hesketh (Artisan Consulting)
    * @date 2017/03/14
    * @description Unit test for issue raised where the marketing region isn't being set correctly 
    * due to before trigger being fired for updates
    **/ 
    static testMethod void setMarketingRegionFromUpdateTest() { 
        List<Contact> contacts = TestDataFactory.createContacts('customer', 1); 
        contacts[0].OtherCountry = 'Iceland'; 
        
        Test.startTest(); 
        insert contacts; 

        List<Contact> conts = [SELECT Marketing_Region__c FROM Contact];  
        system.assertEquals(conts[0].Marketing_Region__c, 'Europe - Rest'); 

        conts[0].OtherCountry = 'Australia'; 
        update conts; 
        conts = [SELECT Marketing_Region__c FROM Contact];  

        system.assertEquals('Australia', conts[0].Marketing_Region__c); 
        Test.stopTest(); 
    }

    /** 
    * @author Jimmy Hesketh (Artisan Consulting)
    * @date 2017/02/13
    * @description tests the mapping works in a negative scenario
    **/ 
    static testMethod void setMarketingRegionNegativeTest() { 
        List<Contact> contacts = TestDataFactory.createContacts('customer', 1);
        try {
            insert contacts;
        }  
        catch (Exception ex) {
            system.assert(false); 
        } 
    }

    /**
     * @author Jimmy Hesketh (Artisan Consulting) 
     * @date 2017/03/22
     * @description tests the happy path for an unknown subscriber getting fn ln set automatically 
     */
    static testMethod void setUnknownSubscriberNamePositiveTest() {
        List<Contact> unknownContacts = TestDataFactory.createContacts('Subscriber', 1); 
        unknownContacts[0].FirstName = null; 
        unknownContacts[0].LastName = null; 

        insert unknownContacts; 

        List<Contact> unknownSubscribers = [SELECT FirstName, LastName, Initially_Unknown__c FROM Contact]; 
        system.assert(String.isNotBlank(unknownSubscribers[0].FirstName)); 
        system.assert(String.isNotBlank(unknownSubscribers[0].LastName)); 
        system.assertEquals(true, unknownSubscribers[0].Initially_Unknown__c);
    }

    static testMethod void setSubscriberInitiallyUnknownNegativeTest() {
        List<Contact> unknownContacts = TestDataFactory.createContacts('Subscriber', 1); 

        insert unknownContacts; 

        List<Contact> unknownSubscribers = [SELECT Initially_Unknown__c FROM Contact]; 
        system.assertEquals(false, unknownSubscribers[0].Initially_Unknown__c);
    }

    /** 
    * @author Jimmy Hesketh (Artisan Consulting)
    * @date 2017/02/17
    * @description Tests that when standard name fields are empty & passport fields are populated then the standard name fields 
    * get populated 
    **/ 
    static testMethod void setStandardNameFieldsPositiveTest() { 
        List<Contact> contacts = TestDataFactory.createContacts('customer', 1);
        contacts[0].FirstName = null; 
        contacts[0].MiddleName = null;
        contacts[0].LastName = null; 

        contacts[0].Passport_First_Name__c = 'First Name'; 
        contacts[0].Passport_Middle_Name__c = 'Middle Name';
        contacts[0].Passport_Last_Name__c = 'Last Name'; 
        insert contacts; 

        List<Contact> updatedContact = [SELECT Name, Passport_Name__c
                                        FROM Contact]; 
        system.assertEquals(updatedContact[0].Passport_Name__c, updatedContact[0].Name); 
    }

     /** 
    * @author Jimmy Hesketh (Artisan Consulting)
    * @date 2017/02/17
    * @description Tests that when standard name fields are empty & passport fields are populated then the standard name fields 
    * get populated 
    **/ 
    static testMethod void setStandardNameFieldsNegativeTest() { 
        List<Contact> contacts = TestDataFactory.createContacts('customer', 1);
        contacts[0].FirstName = 'PreferredFN'; 
        contacts[0].MiddleName = 'PreferredMN';
        contacts[0].LastName = 'PreferredLN'; 

        contacts[0].Passport_First_Name__c = 'First Name'; 
        contacts[0].Passport_Middle_Name__c = 'Middle Name';
        contacts[0].Passport_Last_Name__c = 'Last Name'; 
        insert contacts; 

        List<Contact> updatedContact = [SELECT Name,Passport_Name__c 
                                        FROM Contact]; 
        system.assert(updatedContact[0].Name != updatedContact[0].Passport_Name__c); 
    }   

     /** 
    * @author Shyam Somaskandhan
    * @date 2017/07/24
    * @description Tests that populate Other Country If Mailing Country Is Populated
    * @Ticket MC-372
    **/ 
    static testMethod void populateOtherCountryIfMailingCountryIsPopulatedPositiveTest() { 
        List<Contact> contacts = TestDataFactory.createContacts('customer', 1);
        contacts[0].OtherCountry = ''; 
        contacts[0].MailingCountry = 'Australia';

        insert contacts; 

        List<Contact> updatedContact = [SELECT OtherCountry,MailingCountry 
                                        FROM Contact]; 
        system.assert(updatedContact[0].OtherCountry == updatedContact[0].MailingCountry); 
        system.assert(updatedContact[0].OtherCountry == 'Australia'); 
    }   

     /** 
    * @author Shyam Somaskandhan
    * @date 2017/07/25
    * @description Tests that other Country Should Not Update When Other CountryCode Is Populated
    * @Ticket MC-372
    **/ 
    static testMethod void otherCountryShouldNotUpdateWithMailingCountryWhenOtherCountryCodeIsPopulatedTest() { 
        List<Contact> contacts = TestDataFactory.createContacts('customer', 1);
        contacts[0].OtherCountryCode = 'Au'; 
        contacts[0].MailingCountryCode = 'IN';

        insert contacts; 

        List<Contact> updatedContact = [SELECT OtherCountry,OtherCountryCode,MailingCountry 
                                        FROM Contact]; 
        system.assert(updatedContact[0].OtherCountry != updatedContact[0].MailingCountry); 
        system.assert(updatedContact[0].OtherCountryCode == 'Au'); 
        system.assert(updatedContact[0].OtherCountry == 'Australia'); 
        system.assert(updatedContact[0].MailingCountry == 'India'); 
    }   

     /** 
    * @author Shyam Somaskandhan
    * @date 2017/07/25
    * @description Tests that populate Other Country If Mailing CountryCode Is Populated
    * @Ticket MC-372
    **/ 
    static testMethod void populateOtherCountryIfMailingCountryCodeIsPopulatedPositiveTest() { 
        List<Contact> contacts = TestDataFactory.createContacts('customer', 1);
        contacts[0].OtherCountryCode = ''; 
        contacts[0].MailingCountryCode = 'Au';

        insert contacts; 

        List<Contact> updatedContact = [SELECT OtherCountry,OtherCountryCode,MailingCountry 
                                        FROM Contact]; 
        system.assert(updatedContact[0].OtherCountry == updatedContact[0].MailingCountry); 
        system.assert(updatedContact[0].OtherCountryCode == 'Au'); 
        system.assert(updatedContact[0].OtherCountry == 'Australia'); 
    }   

     /** 
    * @author Shyam Somaskandhan
    * @date 2017/07/24
    * @description Tests that other Country Should Not Update When It Is Already Populated
    * @Ticket MC-372
    **/ 
    static testMethod void otherCountryShouldNotUpdateWhenItIsAlreadyPopulatedTest() { 
        List<Contact> contacts = TestDataFactory.createContacts('customer', 1);
        contacts[0].OtherCountry = 'Sri Lanka'; 
        contacts[0].MailingCountry = 'Australia';

        insert contacts; 

        List<Contact> updatedContact = [SELECT OtherCountry,MailingCountry 
                                        FROM Contact]; 
        system.assert(updatedContact[0].OtherCountry != updatedContact[0].MailingCountry); 
        system.assert(updatedContact[0].OtherCountry == 'Sri Lanka'); 
    }   
    
     /** 
    * @author Shyam Somaskandhan
    * @date 2017/07/24
    * @description Tests that otherCountry Should Not Populate When Mailing Country Is Blank
    * @Ticket MC-372
    **/ 
    static testMethod void otherCountryShouldNotPopulateWhenMailingCountryIsBlankTest() { 
        List<Contact> contacts = TestDataFactory.createContacts('customer', 1);
        contacts[0].OtherCountry = null; 
        contacts[0].MailingCountry = '';

        insert contacts; 

        List<Contact> updatedContact = [SELECT OtherCountry,MailingCountry 
                                        FROM Contact]; 
        system.assert(updatedContact[0].OtherCountry == null); 
    }   

    /** 
    * @author Shyam Somaskandhan
    * @date 2017/04/25
    * @description 
    **/ 
    static testMethod void createAccountOnContactCreationTest() {
        Test.startTest();        
        List<Contact> contacts = TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_CUSTOMER, 1);
        insert contacts; 
        Test.stopTest(); 

        List<Contact> insertedContacts = [SELECT Id, AccountId FROM Contact]; 

        System.assertEquals(1 , [SELECT count() FROM Account WHERE Id =: insertedContacts[0].AccountId]);       
    }
    
    /** 
    * @author Shyam Somaskandhan
    * @date 2017/04/25
    * @description 
    **/ 
    static testMethod void syncAccountNameWithContactNameTest() { 
        Test.startTest(); 
        List<Contact> contacts = TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_CUSTOMER, 1);       
        insert contacts; 
        Test.stopTest();

        List<Contact> insertedContacts = [SELECT Id, AccountId FROM Contact]; 
        insertedContacts[0].LastName = 'New Last Name';

        update insertedContacts;         

        List<Contact> updatedContacts = [SELECT Name FROM Contact WHERE Id =: contacts[0].Id];  
        List<Account> accounts = [SELECT Name FROM Account WHERE Id =: insertedContacts[0].AccountId];  

        system.assertEquals(accounts[0].Name, updatedContacts[0].Name); 
    }

    /** 
    * @author Shyam Somaskandhan
    * @date 2017/04/25
    * @description 
    **/ 
    static testMethod void createAccountOnContactCreationBulkCreateTest() { 
        Test.setMock(HttpCalloutMock.class, new TealiumCollectHttpMockImpl());
        Test.startTest(); 
        List<Contact> contacts = TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_CUSTOMER, 200);
        insert contacts; 
        Test.stopTest(); 

        List<Contact> insertedContacts = [SELECT Id, AccountId FROM Contact]; 

        String[] accountIds = new List<String>();
        for (Contact c : insertedContacts) {
            accountIds.add(c.AccountId);
        }

        System.assertEquals(200 , [SELECT count() FROM Account WHERE Id IN :accountIds]);       
    }   

     /** 
    * @author Shyam Somaskandhan
    * @date 2017/04/25
    * @description 
    **/ 
    static testMethod void syncAccountNameWithContactNameBulkTest() { 
        Test.setMock(HttpCalloutMock.class, new TealiumCollectHttpMockImpl());
        Test.startTest(); 
        List<Contact> contacts = TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_CUSTOMER, 200);
        insert contacts; 
        Test.stopTest(); 
        
        List<Contact> insertedContacts = [SELECT Id, Name, LastName, AccountId FROM Contact]; 
        String[] accountIds = new List<String>();

        for (Contact c : insertedContacts) {

            accountIds.add(c.AccountId);

            c.FirstName = 'New First Name';
            c.LastName = 'New Last Name';
        }

       
        update insertedContacts; 
        List<Account> accounts = [SELECT Name FROM Account WHERE Id =: insertedContacts[0].AccountId];  

        System.assertEquals(200 , [SELECT count() FROM Account WHERE Id IN :accountIds AND Name = 'New First Name New Last Name']);       
    }
	
	/** 
    * @author Shyam prasath
    * @date 2017/06/14
    * @description Test the Account merge when contact merge happens
    **/ 
    static testMethod void testHandlemergeContactAccounts() {

        CRMfusionDBR101__Scenario__c scenario = TestDataFactory.createDupeBlockerScenario(
            'Contact - FirstName, LastName, Email', 'Contact');
        scenario.CRMfusionDBR101__Match_on_Insert_Action__c = 'Auto-Merge';
        insert scenario;
        
        //Create DupeBlocker Rules
        List<CRMfusionDBR101__Scenario_Rule__c> rules = new List<CRMfusionDBR101__Scenario_Rule__c> {
            TestDataFactory.createDupeBlockerRule(scenario, 'Contact', 'First Name', 'First Name'),
            TestDataFactory.createDupeBlockerRule(scenario, 'Contact', 'Last Name', 'Exact'),
            TestDataFactory.createDupeBlockerRule(scenario, 'Contact', 'Email', 'Exact')
        };      

        insert rules;

        List<Contact> contacts = TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_CUSTOMER, 1);
        insert contacts;      

        //Rebuild DupeBlocker keys so that DupeBlocker can run the matching scenarios
        CRMfusionDBR101.DB_Api.rebuildKeys(new List<Id>(new Map<Id, Contact>(contacts).keySet()));  

        Test.startTest(); 
        //Inserting 1 duplicate
        List<Contact> duplicateContacts1 = new List<Contact>();
        for (Integer i = 0; i < 1; i++) {
            duplicateContacts1.add(TestDataFactory.createContact(
                null,contacts[i].FirstName, contacts[i].LastName, contacts[i].Email, IGConstants.CONTACT_RECORDTYPE_CUSTOMER));
        }
        insert duplicateContacts1;
        Test.stopTest();            
        System.assertEquals(1, [SELECT count() FROM Merge_History__c]);
        System.assertEquals(1, [SELECT count() FROM Contact]);
        System.assertEquals(1, [SELECT count() FROM Account]);
    } 

     /**
     * @author Jimmy Hesketh (Artisan Consulting)
     * @date 02/08/2017 
     * @description 
     * Tests that when there are two assets related to contacts that merge they are reparented correctly by the SF platform (for ART-308)
     */
    static testMethod void assetMergeOnContactMergeTest() {
        Account acc = TestDataFactory.createIndividualAccount('Test1'); 
        Account acc2 = TestDataFactory.createIndividualAccount('Test1');
        insert acc; 
        insert acc2; 

        List<Contact> newContacts = TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_CUSTOMER, 2); 
        newContacts[0].AccountId = acc.Id; 
        newContacts[1].AccountId = acc2.Id; 
        //assets cannot be linked to private contacts (contacts without accounts), therefore need the async account creation to happen
        insert newContacts; 
        //trigger a merge of the records so we can check the assets are reparented correctly 
        Test.startTest(); 
        List<Asset> extIds1 = TestDataFactory.createAssetsExternalId(newContacts[0].Id, 'Starship', 2); 
        insert extIds1; 

        List<Asset> extIds2 = TestDataFactory.createAssetsExternalId(newContacts[1].Id, 'Starship', 1);
        insert extIds2; 
        
        merge newContacts[0] newContacts[1]; 
        Test.stopTest();

        List<Contact> mergedContacts = [SELECT Id FROM Contact]; 
        system.assertEquals(1, mergedContacts.size()); 

        //now check the assets were reparented onto the contact record 
        List<Asset> newAssets = [SELECT Id, ContactId, External_System_Name__c FROM Asset]; 
        system.assertEquals(3, newAssets.size()); 
        for(Asset newAsset : newAssets) {
            system.assertEquals(mergedContacts[0].Id, newAsset.ContactId); 
        }
    } 
}