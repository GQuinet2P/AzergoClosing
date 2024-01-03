@isTest
public with sharing class P2C_EnhancedFileUpload_Test {

    @isTest
    public static void testGetIdsAsString() {
        List<String> ids = new List<String> {'fakeIdA', 'fakeIdB'};

        List<String> results = P2C_EnhancedFileUpload.getIdsAsString(new List<List<String>> {ids});

        Assert.isNotNull(results);
        Assert.areEqual('["fakeIdA","fakeIdB"]', results.get(0));
    }

    @isTest
    public static void testCreateFileAndLinks() {
        User usr = [SELECT Id, ALS_Bypass_Validation_rule__c FROM User WHERE Id = :UserInfo.getUserId()];
        usr.ALS_Bypass_Validation_rule__c = true;
        update usr;
        
        Opportunity opp = TestDataFactory.createOpportunity();

        P2C_EnhancedFileUpload.EnhancedFileUploadData data = new P2C_EnhancedFileUpload.EnhancedFileUploadData();
        data.description = 'test';
        data.fileName = 'test.pdf';
        data.fileDataB64 = EncodingUtil.base64Encode(Blob.valueOf('testcontent'));

        List<String> opIds = new List<String> {opp.Id};

        Test.startTest();

        P2C_EnhancedFileUpload.createFileAndLinks(JSON.serialize(opIds), JSON.serialize(data));

        Test.stopTest();

        List<ContentDocumentLink> cdls = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :opp.Id];
        Assert.isNotNull(cdls);
    }
}