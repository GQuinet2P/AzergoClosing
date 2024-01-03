/**
 * @ description:
 * @ author: Gregory Quinet
 * @ group:
 * @ last modified on: 2023-10-24
 * @ last modified by: Gregory Quinet
 */

@isTest
public with sharing class P2C_ClosingSendEmailCtrl_Test {
    private static String templateBody = 'Bonjour, {!Opportunity.OwnerFullName} [[REPEAT{!Opportunity.Name}{!Opportunity.Numero_de_devis_SF__c}{!Opportunity.Niveau_de_relance__c}{!Opportunity.Infos_relance_commande_client__c}{!Opportunity.Commentaire_retour_relance_client__c}]]  {!User.Name} {!User.Title}';

    @TestSetup
    static void setupTest(){
        Folder f = [SELECT Id, Name FROM Folder WHERE Type = 'Email' LIMIT 1];
        EmailTemplate template = new EmailTemplate(
            Name = 'testTpl', 
            DeveloperName = 'testTpl', 
            folderId = f.Id, 
            Subject = 'test', 
            Body = templateBody, 
            TemplateType = 'text', 
            isActive = true
        );
        insert template;
    }

    @isTest
    public static void testGetTemplateFolder() {
        // Folder testFld = new Folder(Name = 'testFld', DeveloperName = 'testFld', Type = 'Email', AccessType = 'Public');
        // insert testFld;

        Test.startTest();
        String results = P2C_ClosingSendEmailController.getTemplateFolders();

        Test.stopTest();
        Assert.isNotNull(results);
        Assert.isTrue(results.length() > 0);
    }

    @isTest
    public static void testGetEmailTemplates() {
        Folder f = [SELECT Id, Name FROM Folder WHERE Type = 'Email' LIMIT 1];

        Test.startTest();
        String results = P2C_ClosingSendEmailController.getEmailTemplates(f.Id);

        Test.stopTest();
        Assert.isNotNull(results);
        Assert.isTrue(results.length() > 0);
    }

    @isTest
    public static void testGetRecordInfo() {
        User usr = [SELECT Id, ALS_Bypass_Validation_rule__c FROM User WHERE Id = :UserInfo.getUserId()];
        usr.ALS_Bypass_Validation_rule__c = true;
        update usr;
        
        Account a = new Account(Name = 'testAccount');
        insert a;

        Test.startTest();
        String results = P2C_ClosingSendEmailController.getRecordInfo('Account', a.Id, 'Id, Name');
        Test.stopTest();

        Assert.isNotNull(results);
        Assert.isTrue(results.length() > 0);
        System.debug(results);
        Assert.isTrue(results.containsIgnoreCase('testAccount'));
    }

    @isTest
    public static void testGetRecordsInfo() {
        User usr = [SELECT Id, ALS_Bypass_Validation_rule__c FROM User WHERE Id = :UserInfo.getUserId()];
        usr.ALS_Bypass_Validation_rule__c = true;
        update usr;
        
        Account a = new Account(Name = 'testAccount');
        Account b = new Account(Name = 'testAccount2');
        insert new List<Account> {a, b};

        Test.startTest();
        List<String> ids = new List<String> {a.Id, b.Id};
        String results = P2C_ClosingSendEmailController.getRecordsInfo('Account', JSON.serialize(ids), 'Id, Name');
        Test.stopTest();

        Assert.isNotNull(results);
        Assert.isTrue(results.length() > 0);
        Assert.isTrue(results.containsIgnoreCase('testAccount'));
        Assert.isTrue(results.containsIgnoreCase('testAccount2'));
    }

    @isTest
    public static void testGetTemplatePreview() {
        User usr = [SELECT Id, ALS_Bypass_Validation_rule__c FROM User WHERE Id = :UserInfo.getUserId()];
        usr.ALS_Bypass_Validation_rule__c = true;
        update usr;
        
        Account a = new Account(Name = 'testAccount');
        insert a;
        Opportunity opp = TestDataFactory.createOpportunity();
        
        EmailTemplate tpl = [SELECT Id, Name FROM EmailTemplate WHERE Name = 'testTpl'];

        Test.startTest();
        String preview = P2C_ClosingSendEmailController.getTemplatePreview(tpl.Id, JSON.serialize(new List<String> {opp.Id}));
        Test.stopTest();

        Assert.isNotNull(preview);
    }

    @isTest
    public static void testGeenerateQuoteFile(){
        User usr = [SELECT Id, ALS_Bypass_Validation_rule__c FROM User WHERE Id = :UserInfo.getUserId()];
        usr.ALS_Bypass_Validation_rule__c = true;
        update usr;
        Quote q = TestDataFactory.createQuote();

        Test.startTest();
        String fileId = P2C_ClosingSendEmailController.generateQuoteFile(q.Id);
        Test.stopTest();

        List<P2C_ClosingSendEmailController.FolderFileStructure> files = P2C_ClosingSendEmailController.getFilesFor(q.Id);

        Assert.isNotNull(fileId);
        Assert.isNotNull(files);
    }

    @isTest
    public static void testGetQuoteFilesForOppty(){
        User usr = [SELECT Id, ALS_Bypass_Validation_rule__c FROM User WHERE Id = :UserInfo.getUserId()];
        usr.ALS_Bypass_Validation_rule__c = true;
        update usr;
        Quote q = TestDataFactory.createQuote();
        String fileId = P2C_ClosingSendEmailController.generateQuoteFile(q.Id);
        Opportunity opp = TestDataFactory.createOpportunity();

        Test.startTest();
        String files = P2C_ClosingSendEmailController.getQuotesFilesForOppty(JSON.serialize(new List<String> {opp.Id}));
        Test.stopTest();

        Assert.isNotNull(files);
    }

    @isTest
    public static void testSendEmail() {
        P2C_ClosingSendEmailController.EmailData data = new P2C_ClosingSendEmailController.EmailData();
        data.send = true;
        data.recordIds = new List<String> {'afakeId'};
        data.body = 'a simple body';
        data.subject = 'a simple subject';
        data.fromEmail = 'test@test.com';
        data.toEmails = 'test@test.com, test2@test.com';
        data.ccEmails = 'test3@test.com';
        data.bccEmails = 'test4@test.com';

        Test.startTest();
        String result = P2C_ClosingSendEmailController.sendEmails(JSON.serialize(new List<P2C_ClosingSendEmailController.EmailData>{data}));
        Test.stopTest();

        Assert.isNotNull(result);
        Assert.isTrue(result.containsIgnoreCase(data.recordIds.get(0)));
    }
}