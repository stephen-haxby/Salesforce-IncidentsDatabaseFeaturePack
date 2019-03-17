/**
 * Created to do some basic test cases on some of the more complicated flows. 
 * @author Jimmy Hesketh 
 * @date 26/09/2017
 */
@isTest
private with sharing class ContactFlowTest {
	static testMethod void testContactLifetimeValueTripsPositive() {
		//GIVEN
		//create the accounts for the contacts 
		List<Account> accs = TestDataFactory.createPersonAccounts(2); 

		//create the contact records 
		List<Contact> contacts = TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_CUSTOMER, 1); 
		contacts[0].AccountId = accs[0].Id; 
		insert contacts; 
		//create the opportunities 
		List<Opportunity> oppC1 = TestDataFactory.createOpportunities(accs[0], IGConstants.OPPORTUNITY_RECORDTYPE_BRAND, 2); 
		insert oppC1; 

		List<OpportunityLineItem> oppLinesC1 = TestDataFactory.createOpportunityLineItems(oppC1[0], 3);
		//required for opportunity line items, atm just points to a generic pricebook called Starship 
		List<PricebookEntry> priceBookEntries = TestDataFactory.insertPricebookEntries(3);  
		for(Integer i = 0; i < oppLinesC1.size(); i++) {
			oppLinesC1[i].BDM_Component_Type__c = 'Trip'; 
			oppLinesC1[i].Quantity = i + 1;
            oppLinesC1[i].PricebookEntryId = priceBookEntries[i].Id;
            oppLinesC1[i].TotalPrice = 100;
            oppLinesC1[i].BDM_Stage__c = 'FullyPaid'; 
            oppLinesC1[i].Traveller__c = contacts[0].Id; 
		} 
		//This sub type should be excluded from 
		oppLinesC1[1].BDM_Product_Sub_Type_Name__c = 'Single Supplement'; 
		oppLinesC1[2].OpportunityId = oppC1[1].Id; 
		//now begin the actual test, the Test.startTest() resets the govenor limits  
		Test.startTest();
		//WHEN 
		//flow will trigger when the new lines are inserted.  
		insert oppLinesC1; 
		Test.stopTest(); 
		//THEN 
		//now assert the outcomes are as expected 
		//first get the updated contact information 
		List<Contact> updatedContacts = [SELECT Lifetime_Value__c, Number_Of_Trips__c FROM Contact]; 
		system.assert(!contacts.isEmpty()); 
		system.assertEquals(200, updatedContacts[0].Lifetime_Value__c);  
		system.assertEquals(2, updatedContacts[0].Number_Of_Trips__c); 
	}

	static testMethod void testContactLifetimeValueTripsNegative() {
		List<Account> accs = TestDataFactory.createPersonAccounts(2); 
		//create the contact records 
		List<Contact> contacts = TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_CUSTOMER, 2); 
		contacts[0].AccountId = accs[0].Id; 
		insert contacts; 
		//create the opportunities 
		List<Opportunity> oppC1 = TestDataFactory.createOpportunities(accs[0], IGConstants.OPPORTUNITY_RECORDTYPE_BRAND, 2); 
		insert oppC1; 

		List<OpportunityLineItem> oppLinesC1 = TestDataFactory.createOpportunityLineItems(oppC1[0], 5);
		//required for opportunity line items, atm just points to a generic pricebook called Starship 
		List<PricebookEntry> priceBookEntries = TestDataFactory.insertPricebookEntries(5);  
		for(Integer i = 0; i < oppLinesC1.size(); i++) {
			oppLinesC1[i].BDM_Component_Type__c = 'Trip'; 
			oppLinesC1[i].Quantity = i + 1;
            oppLinesC1[i].PricebookEntryId = priceBookEntries[i].Id;
            oppLinesC1[i].TotalPrice = 100;
            oppLinesC1[i].BDM_Stage__c = 'FullyPaid'; 
            oppLinesC1[i].Traveller__c = contacts[0].Id; 
		} 
		//This sub type should be excluded from 
		oppLinesC1[2].BDM_Product_Sub_Type_Name__c = 'Single Supplement'; 
		oppLinesC1[2].OpportunityId = oppC1[1].Id; 
		oppLinesC1[2].Traveller__c = contacts[1].Id; 
		Test.startTest();
		
		insert oppLinesC1; 
		Test.stopTest(); 

		List<Contact> updatedContacts = [SELECT Lifetime_Value__c, Number_Of_Trips__c FROM Contact WHERE Id = :contacts[0].Id]; 
		system.assert(!updatedContacts.isEmpty()); 
		system.assertEquals(400, updatedContacts[0].Lifetime_Value__c);  
		system.assertEquals(4, updatedContacts[0].Number_Of_Trips__c); 

		//Because this trip is a single supp shouldn't be aggregated with the other values. 
		List<Contact> otherContacts = [SELECT Lifetime_Value__c, Number_Of_Trips__c FROM Contact WHERE Id = :contacts[1].Id]; 
		system.assert(!otherContacts.isEmpty()); 
		system.assertEquals(0, otherContacts[0].Lifetime_Value__c); 
		system.assertEquals(0, otherContacts[0].Number_Of_Trips__c); 
	}
}