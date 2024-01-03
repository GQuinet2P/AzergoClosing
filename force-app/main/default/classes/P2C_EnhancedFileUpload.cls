public with sharing class P2C_EnhancedFileUpload {

    @InvocableMethod(label='getIdsAsString' description='return a json string representation of ids')
    public static List<String> getIdsAsString(List<List<String>> ids) {
        String result = '["';
        for (String id : ids.get(0)) {
            result += id + '","';
        }
        if (result.endsWith(',"')) {
            result = result.substring(0, result.length() - 2);
        }
        result += ']';
        return new List<String> {result};
    }


    @AuraEnabled
    public static void createFileAndLinks(String jsonRelatedRecordIds, String jsonData) {
        if (jsonRelatedRecordIds == null || jsonData == null) {
            System.debug('No data on input');
            return;
        }

        System.debug('relIds: ' + jsonRelatedRecordIds);
        System.debug('data: ' + jsonData);

        EnhancedFileUploadData fileData = (EnhancedFileUploadData)JSON.deserialize(jsonData, EnhancedFileUploadData.class);

        ContentVersion cv = new ContentVersion();
        cv.versionData = EncodingUtil.base64Decode(fileData.fileDataB64);
        cv.Title = fileData.fileName;
        cv.Description = fileData.description;
        cv.PathOnClient = fileData.fileName;

        insert cv;

        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
        List<String> linkedIds = (List<String>)JSON.deserialize(jsonRelatedRecordIds, List<String>.class);
        for (String related : linkedIds) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = related;
            cdls.add(cdl);
        }

        if (!cdls.isEmpty()) {
            insert cdls;
        }
    }

    public class EnhancedFileUploadData {
        public String fileName;
        public String description;
        public String fileDataB64;
    }
}