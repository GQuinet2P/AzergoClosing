public with sharing class P2C_CustomLookupInputFieldController {

    @AuraEnabled
    public static String searchRecords(String objectApiName, String fieldApiName, String searchKey) {
        // String searchKeyword = searchKey + '*';
        String returningQuery = objectApiName + ' ( Id, ' + fieldApiName + ' )';
        String query = 'FIND :searchKey IN ALL FIELDS RETURNING ' + returningQuery + ' LIMIT 2000';
        // String query = 'FIND :searchKeyword IN ALL FIELDS RETURNING ' + returningQuery + ' LIMIT 2000';
        List<List<sObject>> sobjectList = Search.query(Query);
        return JSON.serialize(sobjectList);
    }
}