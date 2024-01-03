@isTest
public class TestDataFactory {

    // public static User getSystemAdminUserBypass() {
    //     User user1 = TestStaticVariables.getUserBypass();
    //     System.debug('*** IMA user admin = ' + user1);
    //     return [Select Id, Profile.Name, ProfileId FROM User 
    //             // WHERE (Profile.Name = 'Administrateur Système' OR Profile.Name = 'System Administrator') AND Bypass_VR__c= true and Bypass_PB__c= true and IsActive = true 
    //             WHERE (Profile.Name = 'Administrateur Système' OR Profile.Name = 'System Administrator') and IsActive = true 
    //             LIMIT 1];
    // }
    
     
    //  public static User getSystemAdminUser() {
    //     User user1 = TestStaticVariables.getUser();
    //     System.debug('*** IMA normal user = ' + user1);
    //     return [Select Id, Profile.Name FROM User 
    //             WHERE (Profile.Name = 'Administrateur Système' OR Profile.Name = 'System Administrator') AND BypassVR__c = false and IsActive = true 
    //             // WHERE (Profile.Name = 'Administrateur Système' OR Profile.Name = 'System Administrator') AND BypassVR__c= false and Bypass_PB__c= false and IsActive = true 
    //             LIMIT 1];
    // }
    
    // public static User getManagerUser() {
    //     User user = TestStaticVariables.getUserManager();
    //     System.debug('*** IMA Manager user = ' + user);
    //     return [Select Id, Profile.Name FROM User 
    //             WHERE Profile.Name = 'Manager' AND BypassVR__c = false and IsActive = true 
    //             // WHERE Profile.Name = 'Manager'  AND BypassVR__c = false and Bypass_PB__c= false and IsActive = true 
    //             LIMIT 1];
    // }
	
    // Create contact
    public static Contact createContact(){
        System.debug('Creating a contact');
      
		Contact ctTest = TestStaticVariables.getContact();
        System.debug('contact created: ' + ctTest.Id);
    
        return ctTest;
    }
	
    // // Create event
    // public static Event createEvent(Id accountId){
    //     System.debug('Creating an avent');
      
	// 	Event evt = TestStaticVariables.getEvent(accountId);
    //     System.debug('event created: ' + evt.Id);
    
    //     return evt;
    // }

    // Create user
    public static User createUser(String userName, Boolean hasBypassVr){
        System.debug('Creating a user');
      
		User usr = TestStaticVariables.getUser(userName, hasBypassVr);
        System.debug('user created: ' + usr.Id);
    
        return usr;
    }
  
    // Create account
    public static Account createGroup(){
        System.debug('Creating a group account');
      
		Account groupAccount = TestStaticVariables.getAccount('testuser');
        System.debug('group account created: ' + groupAccount.Id);
    
        return groupAccount;
    }
  
    // Create account
    public static Account createLegal(){
        System.debug('Creating a legal account');
      
		Account legalAccount = TestStaticVariables.getAccount('testuser');
        System.debug('legal account created: ' + legalAccount.Id);
    
        return legalAccount;
    }
  
    // Create account
    public static Account createCustomer(){
        System.debug('Creating a customer account');
      
		Account customerAccount = TestStaticVariables.getAccount('testuser');
        System.debug('customer created: ' + customerAccount.Id);
    
        return customerAccount;
    }
  
    // Create Opportunity method override with One param
    public static Opportunity createOpportunity(Account acc){
        return createOpportunity();
    }
  
	// Create Opportunity Method without param
    public static Opportunity createOpportunity(){
        Opportunity opportunity = TestStaticVariables.getOpportunity();
        return opportunity;
    }
    
    // Create Quote
    public static Quote createQuote(){
        Quote quote = TestStaticVariables.getQuote();
    	return quote;
	}

    // public static Product2 createProduct() {     
    // 	Product2 prod = TestStaticVariables.getProduct2();
    //     return prod;
    // } 
    
    // // Create QuoteLines
    // public static SBQQ__QuoteLine__c createQuoteLine(SBQQ__Quote__c quote, Product2 prod){
    //     return createQuoteLine();
    // }
    
    // public static SBQQ__QuoteLine__c createQuoteLine(){
    //     SBQQ__QuoteLine__c quoteLine = TestStaticVariables.getSBQQQuoteLine();																		
    //     return quoteLine;
    // }
    
    // public static Opportunity createOpportunityBypass(Account acc)
    // {
    //     return createOpportunityBypass();
    // }
	 
    // public static Opportunity createOpportunityBypass()
    // {

    //     Opportunity opportunity = TestStaticVariables.getOpportunity();
    //     return opportunity;
    // }
}