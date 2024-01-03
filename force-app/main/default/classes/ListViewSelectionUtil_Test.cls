@isTest
public with sharing class ListViewSelectionUtil_Test {

    @isTest
    public static void testGetUsableIdsFromSLVSelection() {
        String fakeIds = '["abc","def",\'ghi\']';
        List<String> fakes = new List<String> {fakeIds};
        List<List<String>> toConvert = new List<List<String>> {fakes};
        List<List<String>> result = ListViewsSelectionUtil.getUsableIdsFromSLVSelection(toConvert);

        Assert.isNotNull(result);
        Assert.isTrue(result.get(0).contains('abc'));
    }
}