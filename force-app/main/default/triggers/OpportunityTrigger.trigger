/*******************************************************************************
* @author       Anterey Custodio
* @date         1.Oct.2015         
* @description  This will handle all trigger events on the Opportunity object
* @revision     11.Nov.2015 Anterey Custodio - added a method on handler
*               29.Jan.2015 Anterey Custodio - removed the findContact on beforeUpdate event    
*   			2016/11/16 Mohamed Atheek (Artisan Consulting) - Added logic to not to run the trigger if it has been disabled in the custom setting
* 				2017/01/30 Mohamed Atheek (Artisan Consulting) - Replaced findContact() in before insert with populateContactOnInsert() for ART-198
*******************************************************************************/
trigger OpportunityTrigger on Opportunity (after update, after insert, before insert, before update) {
	if (IgUtil.isTriggerEnabled(Opportunity.sObjectType)) {
    	if(trigger.isBefore) {
        	if (trigger.isInsert) {
            	OpportunityHandler.populateContactOnInsert(Trigger.New);
            	OpportunityHandler.prepopulateClosedDate(trigger.new);
        	}
    	}
    
    	if(trigger.isAfter){
        	if(trigger.isInsert){
            	OpportunityHandler.checkFirstSaleofConsultant(trigger.new);
            //	OpportunityHandler.afterInsertAndUpdateEvents(null, trigger.new);
        	}
        	if(trigger.isUpdate){
            //	OpportunityHandler.afterInsertAndUpdateEvents(trigger.oldMap, trigger.new);
        	}

			if(trigger.isUpdate || trigger.isInsert){
				ContactHandler.updateContactTotalTripsAndSalePrice(trigger.new);
			}
    	}
    }
}