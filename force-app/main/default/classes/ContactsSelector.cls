/**
 * Contains code that encapsulates logic responsible for querying Contact records.
 * Uses FinacialForce Selector pattern explained at 
 * https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Selector_Layer.
 *
 * @author Mohamed Atheek (Artisan Consulting)
 * @date 2016/10/18 
 */
public class ContactsSelector extends fflib_SObjectSelector {
   
	/**
	 * Implementation to the parents class's abstract method.
	 */   
    public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField> {
			Contact.Id,
			Contact.FirstName,
			Contact.LastName,			
			Contact.Email, 
			Contact.AccountId,
			Contact.RecordTypeId,
			Contact.Correlation_ID__c
		};
	}

	/**
	 * Implementation to the parents class's abstract method.
	 */
	public Schema.SObjectType getSObjectType() {
		return Contact.sObjectType;
	}

	/**
	 * Queries and returns a List of Contacts matching the given set of Ids.
	 * 
	 * @param idSet the Set of Contact Ids to query
	 */
	public List<Contact> selectById(Set<Id> idSet) {
		return (List<Contact>) selectSObjectsById(idSet);
	}
	
	/**
	 * Queries and returns a List of Contacts filtered by the given record type.
	 * 
	 * @param idSet the Set of Contact Ids to query
	 * @param recordTypeId record type id of the records to return
	 */
	public List<Contact> selectByRecordTypeId(Set<Id> idSet, Id recordTypeId) {
		return (List<Contact>)  Database.query(newQueryFactory()
													.setCondition('Id IN :idSet AND RecordTypeId = :recordTypeId')
													.toSOQL());
	}

	/**
	 * Queries and returns a List of Contacts matching the given set of emails and the record type Id.
	 * 
	 * @param emails the Set of emails to match
	 * @param recordTypeId RecordTypeId of the contacts 
	 */
	public List<Contact> selectByEmail(Set<String> emails, Id recordTypeId) {
		return (List<Contact>) Database.query(newQueryFactory()
												.selectFields(new Set<Schema.SObjectField> {
														Contact.Marketing_ATA__c,
														Contact.Marketing_Geckos__c,
														Contact.Marketing_IG__c,
														Contact.Marketing_Intrepid__c,
														Contact.Marketing_Peregrine__c														
													})
											    .setCondition('Email IN :emails AND RecordTypeId = :recordTypeId')	
											    .toSOQL());
	}

	/**
	 * Builds the query to retreive propagation contacts and their email fields 
	 * @param  email The email of the contact to retrieve duplicates for 
	 * @return       List of matching contacts 
	*/
	public List<Contact> selectMarketingFields(String email) {
		return (List<Contact>) Database.query(newQueryFactory()
												.selectFields(new Set<Schema.SObjectField> {
													Contact.Id,
                
								                    Contact.Marketing_ATA__c,
								                    Contact.Marketing_ATA_Date_Subscribed__c,
								                    Contact.Marketing_ATA_First_Subscribed_Date__c,
								                    Contact.Marketing_ATA_Source__c,
								                    Contact.Marketing_ATA_Date_Unsubscribed__c,
								                    Contact.Date_Privacy_Policy_Accepted_ATA__c,
								                    Contact.Source_Type_ATA__c,
								                    
								                    Contact.Marketing_Geckos__c,
								                   	Contact.Marketing_Geckos_Date_Subscribed__c,
								                    Contact.Marketing_Geckos_First_Subscribed_Date__c,
								                    Contact.Marketing_Geckos_Source__c,
								                    Contact.Contact.Marketing_Geckos_Date_Unsubscribed__c,
								                    Contact.Contact.Date_Privacy_Policy_Accepted_Geckos__c,
								                    Contact.Contact.Source_Type_Geckos__c,
								                    
								                    Contact.Marketing_IG__c,
								                    Contact.Marketing_IG_Date_Subscribed__c,
								                    Contact.Marketing_IG_First_Subscribed_Date__c,
								                    Contact.Marketing_IG_Source__c,
								                    Contact.Marketing_IG_Date_Unsubscribed__c,
								                    Contact.Date_Privacy_Policy_Accepted_IG__c,
								                    Contact.Source_Type_IG__c,
								                    
								                    Contact.Marketing_Intrepid__c,
								                    Contact.Marketing_Intrepid_First_Subscribed_Date__c,
								                    Contact.Marketing_Intrepid_Source__c,
								                    Contact.Marketing_Intrepid_Date_Subscribed__c,
								                    Contact.Marketing_Intrepid_Date_Unsubscribed__c,
								                    Contact.Date_Privacy_Policy_Accepted_Intrepid__c,
								                    Contact.Source_Type_Intrepid__c,
								                    
								                    Contact.Marketing_Peregrine__c,
								                    Contact.Marketing_Peregrine_Date_Subscribed__c,
								                    Contact.Marketing_Peregrine_Date_Unsubscribed__c,
								                    Contact.Marketing_Peregrine_First_Subscribed_Dat__c,
								                    Contact.Marketing_Peregrine_Source__c,
								                    Contact.Date_Privacy_Policy_Accepted_Peregrine__c,
								                    Contact.Source_Type_Peregrine__c													
													})
											    .setCondition('Email = :email')	
											    .toSOQL());
	}
	
	/**
	 * Queries and returns a List of Contacts matching the given set of Correlation Ids.
	 * 
	 * @param correlationIds the Set of Correlation Ids
	 */
	public List<Contact> selectByCorrelationId(Set<String> correlationIds) {
		return (List<Contact>) Database.query(newQueryFactory()
												.selectFields(new Set<Schema.SObjectField> {
														Contact.Correlation_ID__c, 
														Contact.Marketing_ATA__c, 
														Contact.Marketing_Geckos__c, 
														Contact.Marketing_IG__c, 
														Contact.Marketing_Intrepid__c,
														Contact.Marketing_Peregrine__c														
													})
											    .setCondition('Correlation_ID__c IN :correlationIds')	
											    .toSOQL());
	}
	
	/**
	 * Queries and returns a List of Contacts matching the given set of first names, last names and emails.
	 * 
	 * @param firstNames the Set of first names to match
	 * @param lastNames the Set of last names to match
	 * @param emails the Set of emails to match
	 */
	public List<Contact> selectByFNLNEmail(Set<String> firstNames, Set<String> lastNames, Set<String> emails) {
		return (List<Contact>) Database.query(newQueryFactory()
													.selectFields(new Set<Schema.SObjectField> {
														Contact.Correlation_ID__c, 
														Contact.Marketing_ATA__c, 
														Contact.Marketing_Geckos__c, 
														Contact.Marketing_IG__c, 
														Contact.Marketing_Intrepid__c,
														Contact.Marketing_Peregrine__c,
														Contact.FirstName, 
														Contact.LastName, 
														Contact.Email														
													})
													.setCondition('FirstName IN :firstNames AND LastName IN :lastNames AND Email IN :emails')
													.toSOQL());
	}

	/**
	 * Returns a single contact based on its id 
	 * @param  contactId The contact Id to search for 
	 */
	public Contact selectBySingleContactIdMarketing(String contactId) {
		return (Contact) Database.query(newQueryFactory()
													.selectFields(new Set<Schema.SObjectField> {
														Contact.AccountId,
														Contact.Correlation_ID__c, 
														
														Contact.Marketing_ATA__c,
									                    Contact.Marketing_ATA_Date_Subscribed__c,
									                    Contact.Marketing_ATA_First_Subscribed_Date__c,
									                    Contact.Marketing_ATA_Source__c,
									                    Contact.Marketing_ATA_Date_Unsubscribed__c,
									                    Contact.Date_Privacy_Policy_Accepted_ATA__c,
									                    Contact.Source_Type_ATA__c,
									                    
									                    Contact.Marketing_Geckos__c,
									                   	Contact.Marketing_Geckos_Date_Subscribed__c,
									                    Contact.Marketing_Geckos_First_Subscribed_Date__c,
									                    Contact.Marketing_Geckos_Source__c,
									                    Contact.Contact.Marketing_Geckos_Date_Unsubscribed__c,
									                    Contact.Contact.Date_Privacy_Policy_Accepted_Geckos__c,
									                    Contact.Contact.Source_Type_Geckos__c,
									                    
									                    Contact.Marketing_IG__c,
									                    Contact.Marketing_IG_Date_Subscribed__c,
									                    Contact.Marketing_IG_First_Subscribed_Date__c,
									                    Contact.Marketing_IG_Source__c,
									                    Contact.Marketing_IG_Date_Unsubscribed__c,
									                    Contact.Date_Privacy_Policy_Accepted_IG__c,
									                    Contact.Source_Type_IG__c,
									                    
									                    Contact.Marketing_Intrepid__c,
									                    Contact.Marketing_Intrepid_First_Subscribed_Date__c,
									                    Contact.Marketing_Intrepid_Source__c,
									                    Contact.Marketing_Intrepid_Date_Subscribed__c,
									                    Contact.Marketing_Intrepid_Date_Unsubscribed__c,
									                    Contact.Date_Privacy_Policy_Accepted_Intrepid__c,
									                    Contact.Source_Type_Intrepid__c,
									                    
									                    Contact.Marketing_Peregrine__c,
									                    Contact.Marketing_Peregrine_Date_Subscribed__c,
									                    Contact.Marketing_Peregrine_Date_Unsubscribed__c,
									                    Contact.Marketing_Peregrine_First_Subscribed_Dat__c,
									                    Contact.Marketing_Peregrine_Source__c,
									                    Contact.Date_Privacy_Policy_Accepted_Peregrine__c,
									                    Contact.Source_Type_Peregrine__c,			

														Contact.FirstName, 
														Contact.LastName, 
														Contact.Email														
													})
													.setCondition('Id = :contactId')
													.setLimit(1)
													.toSOQL());
	}

	public List<Contact> selectAllContacts() {
		return (List<Contact>)  Database.query(newQueryFactory()
													.selectFields(new Set<Schema.SObjectField> {
														Contact.Id								
													})
													.toSOQL());
	}
}