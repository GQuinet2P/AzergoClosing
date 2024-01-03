@isTest
public with sharing class P2C_SObjectUtils_Test {

    @isTest
    public static void testSetValue() {
        User usr = TestDataFactory.createUser('setValueTest', true);
        usr = (User)P2C_SObjectUtils.setFieldValue(usr, 'Alias', 'updated');
        usr = (User)P2C_SObjectUtils.setFieldValue(usr, 'isActive', true);

        Opportunity op = new Opportunity();
        op = (Opportunity)P2C_SObjectUtils.setFieldValue(op, 'OwnerId', usr.Id);
        op = (Opportunity)P2C_SObjectUtils.setFieldValue(op, 'CloseDate', Date.today().year() + '-' + Date.today().month() + '-' + Date.today().day());

        Assert.areEqual('updated', usr.Alias);
        Assert.areEqual(usr.Id, op.OwnerId);
    }

    @isTest
    public static void testGetObjectFieldLabels() {
        Map<String, String> results = P2C_SObjectUtils.getObjectFieldLabels('User', new List<String> {'Id','Alias'});

        Assert.isNotNull(results);
        Assert.isTrue(results.containsKey('Id'));
    }

    @isTest
    public static void testOwnerTemplateField() {
        Assert.areEqual('Owner.Name', P2C_SObjectUtils.ownerTemplateFieldToRealField('OwnerFullName'));
        Assert.areEqual('Owner.Email', P2C_SObjectUtils.ownerTemplateFieldToRealField('OwnerEmail'));
        Assert.areEqual('Owner.FirstName', P2C_SObjectUtils.ownerTemplateFieldToRealField('OwnerFirstName'));
        Assert.areEqual('Owner.LastName', P2C_SObjectUtils.ownerTemplateFieldToRealField('OwnerLastName'));
    }

    @isTest
    public static void testGetObjectFieldValue() {
        User usr = TestDataFactory.createUser('setValueTest', true);
        Object result = P2C_SObjectUtils.getObjectFieldValue('Alias', usr);

        Assert.isNotNull(result);
        Assert.areEqual(usr.Alias, result);
    }

    @isTest
    public static void testGetObjectFieldsValues() {
        User userTest = [SELECT Id, ALS_Bypass_Validation_rule__c FROM User WHERE Id = :UserInfo.getUserId()];
        userTest.ALS_Bypass_Validation_rule__c = true;
        update userTest;
        
        User usr = TestDataFactory.createUser('setValueTest', true);
        Opportunity opp = TestDataFactory.createOpportunity();

        Map<String, Map<String, Object>> results = P2C_SObjectUtils.getObjectsFieldsValues('Opportunity', new List<String> {opp.Id}, new List<String> {'Owner.Name', 'Name', 'Amount'});

        Assert.isNotNull(results);
        Assert.isTrue(results.containsKey(opp.Id));
        Assert.isTrue(results.get(opp.Id).containsKey('Name'));
    }
}