/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 12-10-2021
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   03-10-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
 **/
public with sharing class TestStaticVariables {
  public static final String DEFAULT_ACCOUNT_NAME = 'Test Account';
  public static final String DEFAULT_CONTACT_EMAIL = 'mtest31415@gmail.com.invalid';
  public static final String DEFAULT_EVENT_SUBJECT = 'Test Event';
  public static final String DEFAULT_TASK_SUBJECT = 'Test Task';
  public static final String DEFAULT_CALL_SUBJECT = 'Test Call';

  // Create default Account with specific recordtype
  public static Map<String, Account> accTestMap = new Map<String, Account>();
  public static Account getAccount(String accName) {
    if (!accTestMap.containsKey(accName)) {
      Account ac = (Account) TestFactory.createSObject(new Account(Name = accName));
      insert ac;
      accTestMap.put(accName, ac);
    }
    return accTestMap.get(accName);
  }

  //Create default Contact
  public static Contact conTest = null;
  public static Contact getContact() {
    if (conTest == null) {
      conTest = (Contact) TestFactory.createSObject(new Contact());
      insert conTest;
    }
    return conTest;
  }

  // Create default user
  public static User userTst = null;
  public static User getUser() {
    if (userTst == null) {
      User userTst = (User) TestFactory.createSObject(new User(ProfileId = UserInfo.getProfileId()));
      insert userTst;
    }
    return userTst;
  }

  // Create default user
  public static Map<String, User> userTstMap = new Map<String, User>();
  public static User getUser(String userName, Boolean hasBypassVr) {
    if (!userTstMap.containsKey(userName)) {
      String usrnameEmail = userName.replaceAll(' ', '') + '@test.com';
      User userTst = (User) TestFactory.createSObject(new User(Username = usrnameEmail, Alias = userName.substring(0, 7), Email = usrnameEmail, ProfileId = UserInfo.getProfileId()));
      if (hasBypassVr) {
        userTst.ALS_Bypass_Validation_rule__c = true;
      }
      insert userTst;
      userTstMap.put(userName, userTst);
    }
    return userTstMap.get(userName);
  }

  // // Create an event
  // public static Event evtTest = null;
  // public static Event getEvent(Id accountId) {
  //   if (evtTest == null) {
  //     Datetime currTime = Datetime.now();
  //     // Event evtTest = (Event) TestFactory.createSObject(new Event(WhatId = accountId, WhoId = getContact().Id, StartDateTime = currTime.addDays(2), EndDateTime = currTime.addDays(5)));
  //     // Event evtTest = (Event) TestFactory.createSObject(new Event(WhatId = accountId));
  //     Event evtTest = (Event) TestFactory.createSObject(new Event());
  //     insert evtTest;
  //   }
  //   return evtTest;
  // }

  // Create default Opportunity
  public static Opportunity oppTest = null;
  public static Opportunity getOpportunity() {
    if (oppTest == null) {
      oppTest = (Opportunity) TestFactory.createSObject(new Opportunity());
      insert oppTest;
    }
    return oppTest;
  }

  // Create default Quote
  public static Quote quoteTest = null;
  public static Quote getQuote() {
    if (quoteTest == null) {
      quoteTest = (Quote) TestFactory.createSObject(new Quote());
      Contact ct = getContact();
      Opportunity opp = getOpportunity();
      quoteTest.Interlocuteur_Devis_Commande_Facture__c = ct.Id;
      quoteTest.Interlocuteur_de_livraison__c = ct.Id;
      quoteTest.OpportunityId = opp.Id;
      insert quoteTest;
    }
    return quoteTest;
  }

}
