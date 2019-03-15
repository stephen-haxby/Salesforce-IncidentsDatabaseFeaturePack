/**
 * Test class for OpportunityLineItemsSelector class.
 *
 * @author Mohamed Atheek (Artisan Consulting)
 * @date 2017/01/10 
 */
@isTest
private class OpportunityLineItemsSelectorTest {

    /**
	 * Inserts some OpportunityLineItems
	 */
    @testSetup
	static void setup() {
		Account a = TestDataFactory.createAgentAccount('Test Acc', IGConstants.ACCOUNT_RECORDTYPE_BUSINESS);
        insert a; 
        
        Opportunity opp = TestDataFactory.createOpportunity('Test Opp', a, IGConstants.OPPORTUNITY_RECORDTYPE_BRAND);
        insert opp;
        
        List<Contact> contacts = TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_CUSTOMER, 12); 
        insert contacts;
        
        //creating line items with price book entries
        List<OpportunityLineItem> lineItems = TestDataFactory.createOpportunityLineItems(opp, 12);
        
        List<PricebookEntry> priceBookEntries = TestDataFactory.insertPricebookEntries(12);
        
        for (Integer i = 0; i < 12; i++) {
        	lineItems[i].PricebookEntryId = priceBookEntries[i].Id;
        	lineItems[i].Quantity = 1;
        	lineItems[i].UnitPrice = 2000; 
        	lineItems[i].DM_ID__c = 'li' + i;
        	lineItems[i].Traveller__c = contacts[i].Id;   	    	        	
        }
        insert lineItems;
	}
	
	/**
	 * Tests that selectById() method returns all the OpportunityLineItems mathing the given set of Ids
	 */
	@isTest
    static void testSelectById() {
    	List<OpportunityLineItem> lineItems = [SELECT Id FROM OpportunityLineItem LIMIT 4];
    	
    	Test.startTest();
    	
    	List<OpportunityLineItem> selectedLineItems = new OpportunityLineItemsSelector().selectById(new Map<Id, OpportunityLineItem>(lineItems).keySet());
    	
    	Test.stopTest();
    	
    	System.assertEquals(lineItems.size(), selectedLineItems.size());
    	
    	Map<Id, OpportunityLineItem> selectedLineItemsMap = new Map<Id, OpportunityLineItem>(selectedLineItems);
    	for (OpportunityLineItem li : lineItems) {
    		System.assert(selectedLineItemsMap.containsKey(li.Id));
    	}
    }
    
    /**
	 * Tests that selectByExternalId() method returns all the OpportunityLineItems mathing the given set of external Ids
	 */
	@isTest
    static void testSelectByExternalId() {
    	List<OpportunityLineItem> lineItems = [SELECT Id, DM_Id__c FROM OpportunityLineItem LIMIT 4];
    	Set<String> extIds = new Set<String>();
    	for (OpportunityLineItem li : lineItems) {
    		extIds.add(li.DM_ID__c);
    	}
    	
    	Test.startTest();
    	
    	List<OpportunityLineItem> selectedLineItems = new OpportunityLineItemsSelector().selectByExternalId(extIds);
    	
    	Test.stopTest();
    	
    	System.assertEquals(lineItems.size(), selectedLineItems.size());   	
    	
    	for (OpportunityLineItem li : selectedLineItems) {
    		System.assert(extIds.contains(li.DM_Id__c));
    	}
    }
}