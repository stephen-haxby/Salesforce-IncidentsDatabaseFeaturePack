/*******************************************************************************
* @author       Anterey Custodio
* @date         1.Oct.2015         
* @description  This will handle all trigger events on the Opportunity object
* @revision        
*   2016/11/16 Mohamed Atheek (Artisan Consulting) - Added logic to not to run the trigger if it has been disabled in the custom setting
*   2017/04/10 Jimmy Hesketh (Artisan Consulting) - Added before events to the trigger 
*   2017/08/24 Jimmy Hesketh (Artisan Consulting) - Attribute the opportunity to a campaign based on the most recent travellers campaign membership (ART-335)
*******************************************************************************/
trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert, before update, after update, after insert, after delete) {
    if (IgUtil.isTriggerEnabled(OpportunityLineItem.sObjectType)) {
    	if(trigger.isBefore) {
    		if(trigger.isInsert) {
    			OpportunityLineItemHandler.buildProductHiearchy(trigger.new, 'BDM_Product_Code__c', 'Currency_Code__c'); 
    		}
    	}
	    if(trigger.isAfter){
	        if(trigger.isUpdate){
	        	OpportunityLineItemHandler.trackOppLineTealium(trigger.newMap, trigger.oldMap); 
	            OpportunityLineItemHandler.updateOpptyStage(trigger.oldMap, trigger.new);
	            //OpportunityLineItemHandler.updateOrderItem(trigger.oldMap, trigger.new);
	            OpportunityLineItemHandler.attributeOpportunitiesToCampaign(trigger.new); 
	        }
	        if(trigger.isInsert){
	        	OpportunityLineItemHandler.trackOppLineTealium(trigger.newMap, null); 
	            OpportunityLineItemHandler.updateOpptyStage(trigger.oldMap, trigger.new);
	            OpportunityLineItemHandler.attributeOpportunitiesToCampaign(trigger.new); 
	        }
	        
			if(trigger.isInsert || trigger.isUpdate){
				ContactHandler.updateContactTotalTripsAndSalePrice(trigger.new);
			}

	        if (trigger.isDelete) {
	            OpportunityLineItemHandler.prepopulateClosedDate(trigger.old);
	        }
	    }
    }
}