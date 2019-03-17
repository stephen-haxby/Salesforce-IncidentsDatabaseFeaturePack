/**
 * Contains code that encapsulates logic responsible for querying OpportunityLineItem records.
 * Uses FinacialForce Selector pattern explained at 
 * https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Selector_Layer.
 *
 * @author Mohamed Atheek (Artisan Consulting)
 * @date 2017/01/10 
 */
public class OpportunityLineItemsSelector extends fflib_SObjectSelector {
   
	/**
	 * Implementation to the parents class's abstract method.
	 */   
    public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField> {
			OpportunityLineItem.Id,
			OpportunityLineItem.DM_ID__c
		};
	}

	/**
	 * Implementation to the parents class's abstract method.
	 */
	public Schema.SObjectType getSObjectType() {
		return OpportunityLineItem.sObjectType;
	}

	/**
	 * Queries and returns a List of OpportunityLineItem matching the given set of Ids.
	 * 
	 * @param idSet the Set of OpportunityLineItem Ids to query
	 */
	public List<OpportunityLineItem> selectById(Set<Id> idSet) {
		return (List<OpportunityLineItem>) selectSObjectsById(idSet);
	}
	
	/**
	 * Queries and returns a List of OpportunityLineItem matching the given set of external ids (DM_ID__c field).
	 * 
	 * @param extIdSet the Set of OpportunityLineItem external Ids to query
	 */
	public List<OpportunityLineItem> selectByExternalId(Set<String> extIdSet) {
		return (List<OpportunityLineItem>)  Database.query(newQueryFactory()
													.setCondition('DM_ID__c IN :extIdSet')
													.toSOQL());
	}

	/**
	 * Added for ART-335 Opportunity campaign attribution 
	 * @param contactIdSet set of the traveller ids to check opp lines for 
	 */
	public List<OpportunityLineItem> selectByContactIds(Set<Id> contactIdSet) {
		return (List<OpportunityLineItem>)  Database.query(newQueryFactory()
			.selectFields(new Set<Schema.SObjectField> {
				OpportunityLineItem.OpportunityId,
				OpportunityLineItem.Id, 
				OpportunityLineItem.Traveller__c,
				OpportunityLineItem.TotalPrice,
				OpportunityLineItem.BDM_Stage__c,
				OpportunityLineItem.BDM_Component_Type__c,
				OpportunityLineItem.BDM_Product_Sub_Type_Name__c
			})
			.setCondition('Traveller__c IN :contactIdSet')
			.toSOQL());
	}
}