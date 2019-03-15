@isTest
/*******************************************************************************
* @author       Anterey Custodio
* @date         15.Sept.2015
* @description  test class for OpportunityHandler
* @revision
* 	2017/01/25 Mohamed Atheek (Artisan Consulting) - Replaced references to TestDataHelper with the new TestDataFactory class (ART-82)
* 	2017/01/30 Mohamed Atheek (Artisan Consulting) - Added test methods assert the requirements in ART-198
*******************************************************************************/
private class OpportunityHandlerTest {
    
    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         03.Dec.2015
    * @description  scenario 1: test After Insert
    *******************************************************************************/
    static testMethod void scenario1() {

        User usr = TestDataFactory.createBDMUser();
        insert usr;
        system.runAs(usr) {
            Account a = TestDataFactory.createAgentAccount('Test Agent', IGConstants.ACCOUNT_RECORDTYPE_BUSINESS);
            insert a;
            
            Contact c = TestDataFactory.createContact(null,'first', 'last', 'test@email.com', IGConstants.CONTACT_RECORDTYPE_AGENT);
            insert c;
            
            Opportunity opp = TestDataFactory.createOpportunity('Test Opp', a, IGConstants.OPPORTUNITY_RECORDTYPE_BRAND);
            opp.StageName = IGConstants.OPP_STAGE_CLOSEDWON;
            opp.CloseDate = System.today();
            opp.Contact__c = c.Id;
            opp.BDM_Brand__c = 'Intrepid';
            opp.BDM_Total_Sales_Amount__c = 15000;
            
            Test.startTest();               
               insert opp;
            Test.stopTest();
        }
    }
    
    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         03.Dec.2015
    * @description  scenario 1: test After Update 
    *******************************************************************************/
    static testMethod void scenario2() {

        User usr = TestDataFactory.createBDMUser();
        insert usr;
        system.runAs(usr) {
            
            Account a = TestDataFactory.createAgentAccount('Test Agent', IGConstants.ACCOUNT_RECORDTYPE_BUSINESS);
            insert a;
            
            Contact c = TestDataFactory.createContact(null,'first', 'last', 'test@email.com', IGConstants.CONTACT_RECORDTYPE_AGENT);
            insert c;
            
            Opportunity opp = TestDataFactory.createOpportunity('Test Opp', a, IGConstants.OPPORTUNITY_RECORDTYPE_BRAND);
            opp.StageName = IGConstants.OPP_STAGE_OPENQUOTE;
            opp.CloseDate = System.today();
            opp.Contact__c = c.Id;
            opp.BDM_Brand__c = 'Intrepid';
            opp.BDM_Total_Sales_Amount__c = 15000;
            insert opp;
               
            Test.startTest();
               
               opp.StageName = IGConstants.OPP_STAGE_CLOSEDWON;
               update opp;
               
            Test.stopTest();
        }
    }
    
    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         03.Dec.2015
    * @description  scenario 3: test After Insert
    *******************************************************************************/
    static testMethod void scenario3() {

        User usr = TestDataFactory.createBDMUser();
        insert usr;
                
        Account comp = TestDataFactory.createCompanyAccount('Test Company', IGConstants.ACCOUNT_RECORDTYPE_BUSINESS);
        insert comp;
        
        system.runAs(usr) {
            Account a = TestDataFactory.createAgentAccount('Test Agent', IGConstants.ACCOUNT_RECORDTYPE_BUSINESS);
            insert a;
            
            Contact c = TestDataFactory.createContact(null,'first', 'last', 'test@email.com', IGConstants.CONTACT_RECORDTYPE_AGENT);
            insert c;
            
            Test.startTest();
               	List<Opportunity> oppList = TestDataFactory.createOpportunities(a, IGConstants.OPPORTUNITY_RECORDTYPE_BRAND, 5);            
               
               	for (Opportunity opp: oppList) {
                   	opp.StageName = IGConstants.OPP_STAGE_CLOSEDWON;
		            opp.CloseDate = System.today();
		            opp.Contact__c = c.Id;
		            opp.BDM_Brand__c = 'Intrepid';
		            opp.BDM_Total_Sales_Amount__c = 15000;
					opp.BDM_Wholesale_Account__c = comp.Id;
                   
               	}
               
               	insert oppList;
            Test.stopTest();
        }
    }
    
    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         03.Dec.2015
    * @description  scenario 4: test After Update
    *******************************************************************************/
    static testMethod void scenario4() {

        User usr = TestDataFactory.createBDMUser();
        insert usr;
        
        Account comp = TestDataFactory.createCompanyAccount('Test Company', IGConstants.ACCOUNT_RECORDTYPE_BUSINESS);
        comp.CurrencyIsoCode = 'GBP';
        insert comp;
        
        system.runAs(usr) {
            
            Account a = TestDataFactory.createAgentAccount('Test Agent', IGConstants.ACCOUNT_RECORDTYPE_BUSINESS);
            insert a;
            
            Contact c = TestDataFactory.createContact(null,'first', 'last', 'test@email.com', IGConstants.CONTACT_RECORDTYPE_AGENT);
            insert c;
         
           	List<Opportunity> oppList = TestDataFactory.createOpportunities(a, IGConstants.OPPORTUNITY_RECORDTYPE_BRAND, 10);
           	for (Opportunity opp: oppList) {
               	opp.StageName = IGConstants.OPP_STAGE_OPENQUOTE;
	            opp.CloseDate = System.today();
	            opp.Contact__c = c.Id;
	            opp.BDM_Brand__c = 'Intrepid';
	            opp.BDM_Total_Sales_Amount__c = 15000;               
           	}
           	insert oppList;
            
            Test.startTest();
               List<Opportunity> oppToUpdate = new List<Opportunity>();
               for (Opportunity opp: oppList) {                   
                   opp.StageName = IGConstants.OPP_STAGE_CLOSEDWON;
                   opp.BDM_Wholesale_Account__c = comp.Id;
                   oppToUpdate.add(opp);
               }
               oppToUpdate[0].CloseDate = date.today().addYears(-1);
               oppToUpdate[1].CurrencyIsoCode = 'GBP';
               oppToUpdate[2].BDM_First_Name__c = c.FirstName;
               oppToUpdate[2].BDM_Last_Name__c = c.LastName;
               
               update oppToUpdate;
            Test.stopTest();
        }
    }
    
    /** 
	* Tests ContactHandler.populateContactOnInsert() method with the new criteria added in ART-198 
   	* 
   	* @author Mohamed Atheek (Artisan Consulting)
    * @date 2017/01/30 
   	*/
   	@isTest
   	static void testPopulateContactOnInsert() {
   		List<Account> accs = TestDataFactory.createAgentAccounts(IGConstants.ACCOUNT_RECORDTYPE_BUSINESS, 2);
   		insert accs;
   		
   		
   		List<Contact> contacts = TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_CUSTOMER, 3);
   		contacts.addAll(TestDataFactory.createContacts(IGConstants.CONTACT_RECORDTYPE_AGENT, 3));
   		contacts[0].AccountId = accs[0].Id;
   		contacts[1].AccountId = accs[1].Id;
   		contacts[2].AccountId = null;
   		contacts[3].AccountId = accs[0].Id;
   		contacts[4].AccountId = accs[1].Id;
   		contacts[5].AccountId = null;
   		insert contacts;
   		
   		
   		List<Opportunity> opps = TestDataFactory.createOpportunities(accs[0], IGConstants.OPPORTUNITY_RECORDTYPE_BRAND, 12);
   		opps[0].BDM_Sales_Model_Name__c = IGConstants.SALES_MODEL_DIRECT;
   		opps[0].BDM_First_Name__c = contacts[0].FirstName;
   		opps[0].BDM_Last_Name__c = contacts[0].LastName;
   		
   		opps[1].BDM_Sales_Model_Name__c = IGConstants.SALES_MODEL_DIRECT;
   		opps[1].BDM_First_Name__c = contacts[1].FirstName;
   		opps[1].BDM_Last_Name__c = contacts[1].LastName;
   		
   		opps[2].AccountId = null;
   		opps[2].BDM_Sales_Model_Name__c = IGConstants.SALES_MODEL_DIRECT;
   		opps[2].BDM_First_Name__c = contacts[2].FirstName;
   		opps[2].BDM_Last_Name__c = contacts[2].LastName;
   		
   		opps[3].BDM_Sales_Model_Name__c = IGConstants.SALES_MODEL_INDIRECT;
   		opps[3].BDM_First_Name__c = contacts[0].FirstName;
   		opps[3].BDM_Last_Name__c = contacts[0].LastName;
   		
   		opps[4].BDM_Sales_Model_Name__c = IGConstants.SALES_MODEL_INDIRECT;
   		opps[4].BDM_First_Name__c = contacts[1].FirstName;
   		opps[4].BDM_Last_Name__c = contacts[1].LastName;
   		
   		opps[5].AccountId = null;
   		opps[5].BDM_Sales_Model_Name__c = IGConstants.SALES_MODEL_INDIRECT;
   		opps[5].BDM_First_Name__c = contacts[2].FirstName;
   		opps[5].BDM_Last_Name__c = contacts[2].LastName;
   		
   		opps[6].BDM_Sales_Model_Name__c = IGConstants.SALES_MODEL_DIRECT;
   		opps[6].BDM_First_Name__c = contacts[3].FirstName;
   		opps[6].BDM_Last_Name__c = contacts[3].LastName;
   		
   		opps[7].BDM_Sales_Model_Name__c = IGConstants.SALES_MODEL_DIRECT;
   		opps[7].BDM_First_Name__c = contacts[4].FirstName;
   		opps[7].BDM_Last_Name__c = contacts[4].LastName;
   		
   		opps[8].AccountId = null;
   		opps[8].BDM_Sales_Model_Name__c = IGConstants.SALES_MODEL_DIRECT;
   		opps[8].BDM_First_Name__c = contacts[5].FirstName;
   		opps[8].BDM_Last_Name__c = contacts[5].LastName;
   		
   		opps[9].BDM_Sales_Model_Name__c = IGConstants.SALES_MODEL_INDIRECT;
   		opps[9].BDM_First_Name__c = contacts[3].FirstName;
   		opps[9].BDM_Last_Name__c = contacts[3].LastName;
   		
   		opps[10].BDM_Sales_Model_Name__c = IGConstants.SALES_MODEL_INDIRECT;
   		opps[10].BDM_First_Name__c = contacts[4].FirstName;
   		opps[10].BDM_Last_Name__c = contacts[4].LastName;
   		
   		opps[11].AccountId = null;
   		opps[11].BDM_Sales_Model_Name__c = IGConstants.SALES_MODEL_INDIRECT;
   		opps[11].BDM_First_Name__c = contacts[5].FirstName;
   		opps[11].BDM_Last_Name__c = contacts[5].LastName;
   		
   		Test.startTest();
   		
   		insert opps;
   		
   		Test.stopTest();
   		
   		//assert the contact lookups on the opps
   		
   		List<Opportunity> oppsSelected = [SELECT Contact__c FROM Opportunity WHERE Id IN :opps];
   		
   		System.assertEquals(12, oppsSelected.size());
   		
   		for (Opportunity o : oppsSelected) {
   			if (o.Id == opps[0].Id) {
   				System.assertEquals(null, o.Contact__c);			//Direct Sales, Customer Contact & Same Account --> Don't set the lookup
   			}
   			
   			if (o.Id == opps[1].Id) {
   				System.assertEquals(null, o.Contact__c);			//Direct Sales, Customer Contact & Different Account --> Don't set the lookup
   			}
   			
   			if (o.Id == opps[2].Id) {
   				System.assertEquals(null, o.Contact__c);			//Direct Sales, Customer Contact & null Account --> Don't set the lookup
   			}
   			
   			if (o.Id == opps[3].Id) {
   				System.assertEquals(null, o.Contact__c);			//Indirect Sales, Customer Contact & Same Account --> Don't set the lookup
   			}
   			
   			if (o.Id == opps[4].Id) {
   				System.assertEquals(null, o.Contact__c);			//Indirect Sales, Customer Contact & Different Account --> Don't set the lookup
   			}
   			
   			if (o.Id == opps[5].Id) {
   				System.assertEquals(null, o.Contact__c);			//Indirect Sales, Customer Contact & null Account --> Don't set the lookup
   			}
   			
   			if (o.Id == opps[6].Id) {
   				System.assertEquals(null, o.Contact__c);			//Direct Sales, Agent Contact & Same Account --> Don't set the lookup
   			}
   			
   			if (o.Id == opps[7].Id) {
   				System.assertEquals(null, o.Contact__c);			//Direct Sales, Agent Contact & Different Account --> Don't set the lookup
   			}
   			
   			if (o.Id == opps[8].Id) {
   				System.assertEquals(null, o.Contact__c);			//Direct Sales, Agent Contact & null Account --> Don't set the lookup
   			}
   			
   			if (o.Id == opps[9].Id) {
   				System.assertEquals(contacts[3].Id, o.Contact__c);	//Indirect Sales, Agent Contact & Same Account --> Set the lookup
   			}
   			
   			if (o.Id == opps[10].Id) {
   				System.assertEquals(null, o.Contact__c);			//Indirect Sales, Agent Contact & Different Account --> Don't set the lookup
   			}
   			
   			if (o.Id == opps[11].Id) {
   				System.assertEquals(contacts[5].Id, o.Contact__c);	//Indirect Sales, Agent Contact & null Account --> Set the lookup
   			}
   		}
   	}

    @isTest
    static void testOppLineProductCreation() {
        List<Account> theAcc = TestDataFactory.createCompanyAccounts('Company', 1); 
        insert theAcc; 

        //jh - get the starship pricebook 
        List<Product_Pricebook__mdt> pricebook = new ProductPricebooksSelector().selectByDeveloperName(IGConstants.PRICEBOOK_NAME_BROCHURE); 
        system.assert(!pricebook.isEmpty(), 'Product Pricebook metadata doesnt exist. This must be deployed prior to this unit test running.'); 

        List<Opportunity> opps = TestDataFactory.createOpportunities(theAcc[0], 'Brand', 1); 
        opps[0].Pricebook2Id = pricebook[0].PricebookID__c; 
        insert opps; 

        OpportunityLineItem lineItem = TestDataFactory.createOpportunityLineItem(opps[0]); 
        lineItem.BDM_Product_Code__c = 'TestBDMCode';
        lineItem.Quantity = 1; 
        lineItem.TotalPrice = 100; 

        List<SObject> sObj = new List<SObject>(); 
        sObj.add(lineItem); 
        
        Test.startTest(); 
        // Instantiate the Pricebook2 record first, setting the Id
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
         
        // Run an update DML on the Pricebook2 record
        // This is the weird workaround that enables IsStandard to become true
        // on the PricebookEntry record
        update standardPricebook; 

        insert lineItem; 
        Test.stopTest(); 
    }
}