/**
 * Test class for ContactsSelector class.
 *
 * @author Mohamed Atheek (Artisan Consulting)
 * @date 2016/10/18 
 */

@isTest(isparallel=true)
private class ContactsSelectorTest {

	/**
	 * Inserts some customer and agent type contacts
	 */
    @testSetup
	static void setup() {
		List<Contact> contacts = TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_CUSTOMER, 6);
		contacts.addAll(TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_AGENT, 6));
		insert contacts;
	}
	
	/**
	 * Tests that selectById() method returns all the contacts mathing the given set of Ids
	 */
	@isTest
    static void testSelectById() {
    	List<Contact> contacts = [SELECT Id FROM Contact LIMIT 4];
    	
    	Test.startTest();
    	
    	List<Contact> selectedContacts = new ContactsSelector().selectById(new Map<Id, Contact>(contacts).keySet());
    	
    	Test.stopTest();
    	
    	System.assertEquals(contacts.size(), selectedContacts.size());
    	
    	Map<Id, Contact> selectedContactsMap = new Map<Id, Contact>(selectedContacts);
    	for (Contact c : contacts) {
    		System.assert(selectedContactsMap.containsKey(c.Id));
    	}
    }
	
	/**
	 * Tests that selectByRecordTypeId() method returns all the contacts mathing the given set of Ids and record type
	 */
	@isTest
    static void testSelectByRecordTypeId() {
    	Schema.RecordTypeInfo customerRecordTypeInfo = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(IGConstants.CONTACT_RECORDTYPE_CUSTOMER);
    	Schema.RecordTypeInfo agentRecordTypeInfo = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(IGConstants.CONTACT_RECORDTYPE_AGENT);
    	
    	List<Contact> customerContacts = [SELECT Id FROM Contact WHERE RecordTypeId = :customerRecordTypeInfo.getRecordTypeId() LIMIT 3];
    	List<Contact> agentContacts = [SELECT Id FROM Contact WHERE RecordTypeId = :agentRecordTypeInfo.getRecordTypeId() LIMIT 3];
    	
    	Test.startTest();
    	
    	List<Contact> selectedCustomerContacts = new ContactsSelector().selectByRecordTypeId(new Map<Id, Contact>(customerContacts).keySet(), customerRecordTypeInfo.getRecordTypeId());
    	List<Contact> selectedAgentContacts = new ContactsSelector().selectByRecordTypeId(new Map<Id, Contact>(agentContacts).keySet(), agentRecordTypeInfo.getRecordTypeId());
    	
    	
    	Test.stopTest();
    	
    	System.assertEquals(customerContacts.size(), selectedCustomerContacts.size());
    	System.assertEquals(agentContacts.size(), selectedAgentContacts.size());
    	
    	Map<Id, Contact> selectedCustomerContactsMap = new Map<Id, Contact>(selectedCustomerContacts);
    	for (Contact c : customerContacts) {
    		System.assert(selectedCustomerContactsMap.containsKey(c.Id));
    	}
    	
    	Map<Id, Contact> selectedAgentContactsMap = new Map<Id, Contact>(selectedAgentContacts);
    	for (Contact c : agentContacts) {
    		System.assert(selectedAgentContactsMap.containsKey(c.Id));
    	}
    }
    
    /**
     * Tests that selectByEmail() method returns contacts matching the given set of 
     * emails and the record type Id with the expected fields
     */
    @isTest
    static void testSelectByEmail() {
    	Schema.RecordTypeInfo customerRecordTypeInfo = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(IGConstants.CONTACT_RECORDTYPE_CUSTOMER);
    	    	
    	List<Contact> contacts = [SELECT Id, Email FROM Contact WHERE RecordTypeId = :customerRecordTypeInfo.getRecordTypeId() LIMIT 3];
    	
    	Set<String> emails = new Set<String>();
    	for (Contact c : contacts) {
    		emails.add(c.Email);
    		
    		//Setting the marketing cloud subscription fields. Returned contacts should have these fields with the values set here.
    		c.Marketing_ATA__c = IGConstants.MC_SUBSCRIBED;
			c.Marketing_Geckos__c = IGConstants.MC_SUBSCRIBED;
			c.Marketing_IG__c = IGConstants.MC_SUBSCRIBED;
			c.Marketing_Intrepid__c = IGConstants.MC_UNSUBSCRIBED;
			c.Marketing_Peregrine__c = IGConstants.MC_UNSUBSCRIBED;
    	}
    	update contacts;
    	
    	Test.startTest();
    	
    	List<Contact> selectedContacts = new ContactsSelector().selectByEmail(emails, customerRecordTypeInfo.getRecordTypeId());    	
    	
    	Test.stopTest();
    	
    	System.assertEquals(contacts.size(), selectedContacts.size());
    	
    	for (Contact c : selectedContacts) {
    		System.assert(emails.contains(c.Email));    		
    		System.assertEquals(IGConstants.MC_SUBSCRIBED, c.Marketing_ATA__c);    		
    		System.assertEquals(IGConstants.MC_SUBSCRIBED, c.Marketing_Geckos__c);    		
    		System.assertEquals(IGConstants.MC_SUBSCRIBED, c.Marketing_IG__c);    		
    		System.assertEquals(IGConstants.MC_UNSUBSCRIBED, c.Marketing_Intrepid__c);    		
    		System.assertEquals(IGConstants.MC_UNSUBSCRIBED, c.Marketing_Peregrine__c);
    	}
    }
    
    /**
     * Tests that selectByCorrelationId() method returns contacts matching the given set of correlation Ids
     */
    @isTest
    static void testSelectByCorrelationId() {
    	Set<String> correlationIds = new Set<String>();
    	
    	List<Contact> contacts = TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_CUSTOMER, 6);
    	for (Integer i = 0; i < 6; i++) {
    		String cid = 'correlationid' + i;
    		contacts[i].Correlation_ID__c = cid;
    		correlationIds.add(cid);
    	}
		insert contacts;    	
    	
    	Test.startTest();
    	
    	List<Contact> selectedContacts = new ContactsSelector().selectByCorrelationId(correlationIds);    	
    	
    	Test.stopTest();
    	
    	System.assertEquals(contacts.size(), selectedContacts.size());
    	
    	for (Contact c : selectedContacts) {
    		System.assert(correlationIds.contains(c.Correlation_ID__c));    		
    	}
    }
    
    /**
     * Tests that selectByFNLNEmail() method returns contacts matching the given set of first names, last names and emails
     */
    @isTest
    static void testSelectByFNLNEmail() {
    	Set<String> firstNames = new Set<String>();
    	Set<String> lastNames = new Set<String>();
    	Set<String> emails = new Set<String>();
    	
    	List<Contact> contacts = TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_CUSTOMER, 6);
    	//having some common first names and last names
    	contacts[1].FirstName = contacts[0].FirstName;
    	contacts[2].FirstName = contacts[0].FirstName;
    	
    	contacts[3].LastName = contacts[0].LastName;
    	contacts[4].LastName = contacts[0].LastName;
    	
    	for (Integer i = 0; i < 6; i++) {
    		firstNames.add(contacts[i].FirstName);
    		lastNames.add(contacts[i].LastName);
    		emails.add(contacts[i].Email);
    	}
		insert contacts;
    	
    	Test.startTest();
    	
    	List<Contact> selectedContacts = new ContactsSelector().selectByFNLNEmail(firstNames, lastNames, emails);    	
    	
    	Test.stopTest();
    	
    	System.assertEquals(contacts.size(), selectedContacts.size());
    	
    	for (Contact c : selectedContacts) {
    		System.assert(firstNames.contains(c.FirstName));
    		System.assert(lastNames.contains(c.LastName));
    		System.assert(emails.contains(c.Email));
    	}
    }
}