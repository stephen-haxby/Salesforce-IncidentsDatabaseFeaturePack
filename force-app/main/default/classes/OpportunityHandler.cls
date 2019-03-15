/*******************************************************************************
* @author       Anterey Custodio
* @date         1.Oct.2015         
* @description  Class used on Opportunity trigger to manage DML events
* @revision     
*				2016/12/02 Sridhar Sivaraman (Artisan Consulting) - Commented method "prepopulateAccountOwnerFirstName"
*				2017/01/30 Mohamed Atheek (Artisan Consulting) - Replaced findContact() method with populateContactOnInsert() for ART-198
*																 Also removed some commented code
*******************************************************************************/
public class OpportunityHandler {
    //public static final Map<String, CurrencyType> ctypMap = DataHelper.retrieveCurrencies();
    public static final List<DatedConversionRate> convRateList = DataHelper.retrieveDatedCurrencies();
    public static Map<Id, Account> accToUpdateMap = new Map<Id, Account>();
    public static Id rtid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Brand').getRecordTypeId();
    
    /*******************************************************************************
    * @author           Anterey Custodio
    * @date             16.Nov.2015           
    * @description      Method called to call the after insert and after update methods
    *                   used to prevent multiple updates of record
    * @revision     
    *******************************************************************************/
    /*
    Jimmy Hesketh (Artisan Consulting) - commented this out as after the code clean up is no longer used 
    public static void afterInsertAndUpdateEvents(Map<Id, Opportunity> oldMap, List<Opportunity> oppList) {

        sendEmailOn5thSale(oldMap, oppList);
        calculateRolling12MonthRevenue(oldMap, oppList);
        
        if (!accToUpdateMap.isEmpty()) {
            update accToUpdateMap.values();
        }
    }*/ 
    /*******************************************************************************
    * @author           Mac Domingo
    * @date             6.Oct.2015         
    * @description      Method to check if this is the first sale of the consultant
    * @revision     
    *******************************************************************************/
    public static void checkFirstSaleofConsultant(List<Opportunity> opptyList){
        Set<Id> conId = new Set<Id>();
        Map<Id, Contact> oppConMap = new Map<Id, Contact>();
        Map<Id, List<Opportunity>> conOppMap = new Map<Id, List<Opportunity>>();
        List<Opportunity> oppListConFinal = new List<Opportunity>();
        if(opptyList.size() > 0){
            for(Opportunity o : opptyList){
                if(o.RecordTypeId == rtid){
                    if(o.Contact__c != null){
                        conId.add(o.Contact__c);
                    }
                }                
            }
            List<Opportunity> oppList = [Select Id, Contact__c from Opportunity where Contact__c IN :conId and StageName = :IGConstants.OPP_STAGE_CLOSEDWON];
            if(oppList.size() > 0){
                for(String s : conId){
        			List<Opportunity> oppListCon = new List<Opportunity>();
                    for(Opportunity op : oppList){
                        if(s == op.Contact__c){
                            oppListCon.add(op);        
                        }
                    }
                    if(oppListCon.size() == 1){
                        conOppMap.put(s, oppListCon);     
                    }                      
                }                
            }
            if(!conOppMap.isEmpty()){
                for(String cId : conOppMap.keySet()){
                    List<Opportunity> oList = conOppMap.get(cId);
                    oList[0].Consultant_First_Sale__c = true;
                    oppListConFinal.add(oList[0]);
                }          
                if(!oppListConFinal.isEmpty()){
                    update oppListConFinal;
                }      
            }                    
        }
    }
    
    /*******************************************************************************
    * @author           Anterey Custodio
    * @date             6.Oct.2015         
    * @description      Method called to send an email to the contact when a 5th sale
    *                   is made in a month
    * @trigger event    after insert, after update
    * @revision     
    *******************************************************************************/
  /*
    Jimmy Hesketh (Artisan Consulting) - Commented this out as part of the code clean up 
    private static void sendEmailOn5thSale(Map<Id, Opportunity> oldMap, List<Opportunity> oppList){
    
        List<Opportunity> closedWonOppList = new List<Opportunity>();
        
        //filter Closed Won Opportunities
        for (Opportunity opp: oppList) {
            if(opp.RecordTypeId == rtid){
                if (oldMap != null) {
                    if (oldMap.get(opp.Id).StageName != opp.StageName && opp.StageName == IGConstants.OPP_STAGE_CLOSEDWON) {
                        closedWonOppList.add(opp);
                    }
                } else if (opp.StageName == IGConstants.OPP_STAGE_CLOSEDWON) {
                    closedWonOppList.add(opp);
                }
            }            
        }
        
        if (!closedWonOppList.isEmpty()) {
            List<Id> contIds = new List<Id>();
            
            for (Opportunity opp: closedWonOppList) {
                if (opp.CloseDate.month() == date.today().month() &&
                    opp.CloseDate.year() == date.today().year() && 
                    opp.Contact__c != null ) {
                        contIds.add(opp.Contact__c);
                }
            }
            
            Map<Id, Integer> salesMap = new Map<Id, Integer>();
            
            for (Opportunity opp: [SELECT Id, Contact__c,Owner.Email,CloseDate FROM Opportunity WHERE Contact__c IN: contIds]) {
                if (opp.CloseDate.month() == date.today().month() &&
                    opp.CloseDate.year() == date.today().year()) {
                    if (salesMap.containsKey(opp.Contact__c)) {
                        salesMap.put(opp.Contact__c, salesMap.get(opp.Contact__c) + 1);
                    } else {
                        salesMap.put(opp.Contact__c, 1);
                    }
                }
            }
            
            List<Contact> contToUpdate = new List<Contact>();
            for (Contact con: [SELECT Id FROM Contact WHERE Id IN: salesMap.keySet()]) {
                
                if (salesMap.get(con.Id) == 5) {
                    con.hasBooked5InAMonth__c = true;
                } else {
                    con.hasBooked5InAMonth__c = false;
                }
                contToUpdate.add(con);
            }
            
            if (!contToUpdate.isEmpty()) {
                update contToUpdate;
            }
        }
    }*/ 
    
    /*******************************************************************************
    * @author           Anterey Custodio
    * @date             15.Oct.2015         
    * @description      private method that calculates the total amount per brand
    * @revision         12.Nov.2015 ACustodio - updated conversion logic
    *******************************************************************************/
    private static Decimal computeTotalAmount(Map<String, List<Opportunity>> oppMap, String mapKey, String accISOcode){
        Decimal totalAmount = 0;
        if (oppMap.containsKey(mapKey)) {
            
            /*String corporateCurrency = 'AUD';
            for (CurrencyType ctype: ctypMap.values()) {
                if (ctype.IsCorporate) {
                    corporateCurrency = ctype.ISOCode;
                }
            }*/

            for (Opportunity opp: oppMap.get(mapKey)) {
                
                Decimal convertedAmt = 0;
                if (opp.BDM_Total_Sales_Amount__c != null) {
                    convertedAmt = opp.BDM_Total_Sales_Amount__c;
                }
                
                if (opp.CurrencyIsoCode != accISOcode) {
                    Decimal dcRate = 0;
                    Decimal accRate = 0;
                    for (DatedConversionRate dcr: convRateList) {
                        if (dcr.StartDate <= opp.CloseDate && dcr.ISOCode == opp.CurrencyIsoCode) {
                            dcRate = dcr.ConversionRate;
                        }
                        
                        if (dcr.StartDate <= opp.CloseDate && dcr.ISOCode == accISOcode) {
                            accRate = dcr.ConversionRate;
                        }
                    }
                    Decimal conversionRate = 1 / dcRate;
                    convertedAmt = (convertedAmt * conversionRate);
                    convertedAmt = (convertedAmt * accRate);
                }

                /*if (ctypMap.containsKey(accISOcode)) {
                    convertedAmt = (convertedAmt * ctypMap.get(accISOcode).ConversionRate);
                }*/
                
                totalAmount += convertedAmt;
            }
        }
        
        return totalAmount;
    }
    
    /*******************************************************************************
    * @author           Anterey Custodio
    * @date             09.Nov.2015         
    * @description      calculates the 12 month rolling revenue
    * @trigger event    after insert, after update
    * @revision     
    *******************************************************************************/
    /*
    Jimmy Hesketh (Artisan Consulting) - Commented this out as part of the code cleanup work 
    private static void calculateRolling12MonthRevenue(Map<Id, Opportunity> oldMap, List<Opportunity> oppList){
        
        List<Opportunity> closedWonOppList = new List<Opportunity>();
        Set<Id> accIdSet = new Set<Id>();
        
        //filter Closed Won Opportunities
        for (Opportunity opp: oppList) {
            if(opp.RecordTypeId == rtid){
                if (oldMap != null) {
                    if (oldMap.get(opp.Id).StageName != opp.StageName ||
                        oldMap.get(opp.Id).BDM_Total_Sales_Amount__c != opp.BDM_Total_Sales_Amount__c ||
                        oldMap.get(opp.Id).CloseDate != opp.CloseDate) {
                        closedWonOppList.add(opp);
                    }
                } else {
                    closedWonOppList.add(opp);
                }                
                accIdSet.add(opp.AccountId);
            }            
        }
        
        if (!closedWonOppList.isEmpty()) {
            
            Map<String, List<Opportunity>> oppListMap = new Map<String, List<Opportunity>>();
            Integer lastYear = date.today().addYears(-1).year();
            Date startDate = date.newInstance(lastYear, date.today().month(), date.today().day());
            Date todaysDate = date.newInstance(date.today().year(), date.today().month(), date.today().day());
            for (Account acc: [ SELECT Id, 
                                        (   SELECT Id, Name, 
                                                    BDM_Total_Sales_Amount__c, 
                                                    CurrencyIsoCode,
                                                    AccountId,
                                                    CloseDate
                                            FROM    Opportunities
                                            WHERE   BDM_Brand__c != null 
                                                    AND CloseDate >=: startDate
                                                    AND CloseDate <=: todaysDate
                                                    AND StageName = :IGConstants.OPP_STAGE_CLOSEDWON)
                                FROM    Account
                                WHERE   Id IN: accIdSet]) {
                for (Opportunity opp: acc.Opportunities) {
                    if (oppListMap.containsKey(acc.Id)) {
                        oppListMap.get(acc.Id).add(opp);
                    } else {
                        oppListMap.put(acc.Id, new List<Opportunity> {opp});
                    }
                }
            }
            
            List<Account> accToUpdate = new List<Account>();
            
            for (Account acc: DataHelper.retrieveAccountsById(accIdSet)) {
                if (accToUpdateMap.containsKey(acc.Id)) {
                    acc = accToUpdateMap.get(acc.Id);
                }
                
                acc.BDM_Grand_12_Months_Total__c = computeTotalAmount(oppListMap, acc.Id, acc.CurrencyIsoCode).setScale(2);
                acc.BDM_12_Month_Rolling_Converted__c = IgUtil.convertToDatedCorporateCurrency(convRateList, acc.BDM_Grand_12_Months_Total__c, acc.CurrencyIsoCode).setScale(2);
                accToUpdate.add(acc);
            }
            
            if (!accToUpdate.isEmpty()) {
                accToUpdateMap.putAll(accToUpdate);
            }
        }
    }    
    */ 
      
    /**
	 * Populates Opportunity.Contact__c lookup field with the Id of an existing Contact if the following criteria are met
	 * - Contact.FirstName = Opportunity.BDM_First_Name__c
	 * - Contact.LastName = Opportunity. BDM_Last_Name__c
	 * - Contact.AccountId = Opportuity.AccountId (or both blank)
	 * - Contact.RecordType = 'Agent'
	 * - Opportunity.BDM_Sales_Model_Name__c = 'Indirect'	 
	 * 
	 * @author Mohamed Atheek (Artisan Consulting)
	 * @date 2017/01/30
	 * @param newOpps Trigger.New context variable from before insert trigger	 
	 */
    public static void populateContactOnInsert(List<Opportunity> newOpps) {
    	List<Opportunity> oppsToUpdate = new List<Opportunity>();
    	
    	Set<Id> accIds = new Set<Id>();
    	Set<String> contNames = new Set<String>();
    	
    	for (Opportunity o : newOpps) {
    		if (o.BDM_Sales_Model_Name__c == IGConstants.SALES_MODEL_INDIRECT &&
    				String.isNotBlank(o.BDM_First_Name__c) &&
    				String.isNotBlank(o.BDM_Last_Name__c)) {
    			oppsToUpdate.add(o);
    			accIds.add(o.AccountId);
    			contNames.add(getName(o.BDM_First_Name__c, o.BDM_Last_Name__c));
    		}
    	}
    	
    	Schema.RecordTypeInfo agentRecordType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(IGConstants.CONTACT_RECORDTYPE_AGENT);
    	
    	Map<String, List<Contact>> nameToContactList = new Map<String, List<Contact>>();
    	for (Contact c : [SELECT Id, Name, AccountId 
    					  FROM Contact 
    					  WHERE RecordTypeId = :agentRecordType.getRecordTypeId() AND AccountId IN :accIds AND Name IN :contNames 
    					  ORDER BY NAME DESC]) {
    		String key = c.Name.toUpperCase();
    		List<Contact> contList = nameToContactList.get(key);
    		if (contList == null) {
    			contList = new List<Contact>();
    		}
    		contList.add(c);
    		nameToContactList.put(key, contList);
    	}
    	
    	for (Opportunity o : oppsToUpdate) {
    		String key = getNameUpper(o.BDM_First_Name__c, o.BDM_Last_Name__c);
    		if (nameToContactList.containsKey(key)) {    			
	    		for (Contact c : nameToContactList.get(key)) {
	    			if (o.AccountId == c.AccountId) {
	    				o.Contact__c = c.Id;
	    			}
	    		}
    		}
    	}
    }
    
    private static String getName(String firstName, String lastName) {
    	return firstName + ' ' + lastName; 
    }
    
    private static String getNameUpper(String firstName, String lastName) {
    	return getName(firstName, lastName).toUpperCase(); 
    }
    
    /*******************************************************************************
    * @author           Anterey Custodio
    * @date             30.Nov.2015         
    * @description      Method to update the closed date to 3 months of created date
    * @event            before insert
    * @revision
    *		   2017/03/21 Mohamed Atheek (Artisan Consulting) - Deactivated the WFR 'Default Close Date' and moved that logic here to set the close date to first travel date  
    *******************************************************************************/
    public static void prepopulateClosedDate(List<Opportunity> oppList) {
        for (Opportunity opp: oppList) {
            opp.CloseDate = opp.First_Date_Of_Travel__c != null ? opp.First_Date_Of_Travel__c : date.today().addMonths(3);
        }
    }
}