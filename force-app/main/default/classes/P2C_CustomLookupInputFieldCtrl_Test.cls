@isTest
public class P2C_CustomLookupInputFieldCtrl_Test {

    @isTest
    public static void testSearch() {

        User us1 = TestDataFactory.createUser('userOne', false);
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = us1.Id;
        Test.setFixedSearchResults(fixedSearchResults);
            
        String request = '';
        String results = P2C_CustomLookupInputFieldController.searchRecords('User','Alias', 'one');

        Assert.isNotNull(results);
        System.debug(results);
        Assert.isTrue(results.contains('userOne'));
    }
}