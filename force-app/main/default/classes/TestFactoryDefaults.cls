/**
 * @ description:
 * @ author: Gregory Quinet
 * @ group:
 * @ last modified on: 2023-10-19
 * @ last modified by: Gregory Quinet
 */

public class TestFactoryDefaults {
  // To specify defaults for objects, use the naming convention [ObjectName]Defaults.
  // For custom objects, omit the __c from the Object Name

  public class AccountDefaults implements TestFactory.FieldDefaults {
    public Map<Schema.SObjectField, Object> getFieldDefaults() {
      return new Map<Schema.SObjectField, Object>{
        Account.Name => TestStaticVariables.DEFAULT_ACCOUNT_NAME,
        Account.BillingCountry => 'France',
        Account.BillingStreet => '47 Rue de Ponthieu',
        Account.BillingCity => 'Paris',
        Account.BillingPostalCode => '75008',
        Account.OwnerId => UserInfo.getUserId()
      };
    }
  }

  // public class CaseDefaults implements TestFactory.FieldDefaults {
  //   public Map<Schema.SObjectField, Object> getFieldDefaults() {
  //     return new Map<Schema.SObjectField, Object>{
  //       Case.Status => 'Draft',
  //       Case.Subject => 'Test Case',
  //       Case.ContactId => TestStaticVariables.getContact().Id,
  //       Case.Description => 'test'
  //     };
  //   }
  // }

  public class ContactDefaults implements TestFactory.FieldDefaults {
    public Map<Schema.SObjectField, Object> getFieldDefaults() {
      return new Map<Schema.SObjectField, Object>{
        Contact.AccountId => TestStaticVariables.getAccount('testuser').Id,
        Contact.FirstName => 'Toto',
        Contact.LastName => 'Tata',
        Contact.email => TestStaticVariables.DEFAULT_CONTACT_EMAIL,
        Contact.MobilePhone => '0600000000',
        Contact.Phone => '0300000000'
      };
    }
  }

  // public class EventDefaults implements TestFactory.FieldDefaults {
  //   public Map<Schema.SObjectField, Object> getFieldDefaults() {
  //     return new Map<Schema.SObjectField, Object>{
  //       Event.Subject => TestStaticVariables.DEFAULT_EVENT_SUBJECT,
  //       Event.WhoId => TestStaticVariables.getContact().Id,
  //       Event.StartDateTime => Date.today().addDays(5),
  //       Event.EndDateTime => Date.today().addDays(6)
  //     };
  //   }
  // }

  public class OpportunityDefaults implements TestFactory.FieldDefaults {
    public Map<Schema.SObjectField, Object> getFieldDefaults() {
      return new Map<Schema.SObjectField, Object>{
        Opportunity.StageName => 'Qualification',
        Opportunity.CloseDate => Date.today(),
        Opportunity.Name => 'Test',
        Opportunity.Adresse_de_livraison_Code_postal__c => '75000',
        Opportunity.Adresse_de_livraison_Rue__c => '47 Rue de Ponthieu',
        Opportunity.Adresse_de_livraison_Ville__c => 'Paris',
        Opportunity.Adresse_de_livraison_Pays__c => 'France',
        Opportunity.AccountId => TestStaticVariables.getAccount('testuser').Id,
        Opportunity.Adresse_de_livraison_Libelle__c => 'Siege'
        // Opportunity.OwnerId => TestStaticVariables.getUser().Id
      };
    }
  }

  public class QuoteDefaults implements TestFactory.FieldDefaults {
    public Map<Schema.SObjectField, Object> getFieldDefaults() {
      return new Map<Schema.SObjectField, Object>{
        Quote.Name => 'ACOME France',
        Quote.Methode_de_livraison__c => 'Expédition chez le client matériel monté',
        Quote.Relance_Qui_intervient__c => 'ADV gère la relance'
      };
    }
  }

  // public class SBQQQuoteDefaults implements TestFactory.FieldDefaults {
  //   public Map<Schema.SObjectField, Object> getFieldDefaults() {
  //     return new Map<Schema.SObjectField, Object>{
  //       SBQQ__Quote__c.Commercial_Entity__c => 'ACOME France'
  //     };
  //   }
  // }

  // public class Product2Defaults implements TestFactory.FieldDefaults {
  //   public Map<Schema.SObjectField, Object> getFieldDefaults() {
  //     return new Map<Schema.SObjectField, Object>{
  //       Product2.Name => 'Test product'
  //     };
  //   }
  // }

  // public class TaskDefaults implements TestFactory.FieldDefaults {
  //   public Map<Schema.SObjectField, Object> getFieldDefaults() {
  //     return new Map<Schema.SObjectField, Object>{
  //       Task.Subject => TestStaticVariables.DEFAULT_TASK_SUBJECT,
  //       Task.WhoId => TestStaticVariables.getContact().Id,
  //       Task.Status => 'Not Started'
  //     };
  //   }
  // }
  
  public class UserDefaults implements TestFactory.FieldDefaults {
    public Map<Schema.SObjectField, Object> getFieldDefaults() {
      return new Map<Schema.SObjectField, Object>{
        user.Username => 'testcpa@usertes.test',
        user.LanguageLocaleKey => 'en_US',
        user.Email => 'test@test.fr',
        user.LastName => 'TestU',
        user.TimeZoneSidKey => 'Europe/Paris',
        user.LocaleSidKey => 'fr_FR',
        user.EmailEncodingKey => 'UTF-8',
        user.Alias => 'tes'
      };
    }
  }
  
}