public class ListViewsSelectionUtil {
	
    @InvocableMethod(label='GetRecordIdsFromSimplyListViewsSelection' description='return a valid record ids list from Simply List Views selection')
    public static List<List<String>> getUsableIdsFromSLVSelection(List<List<String>> ids) {
        System.debug('Received Ids values are: ' + ids.get(0));
        List<String> realIds = new List<String>();
        for (String anId : ids.get(0)) {
            System.debug('parse id: ' + anId);
            String realId = anId.replaceAll('"', '');
            realId = realId.replaceAll('\\[', '');
            realId = realId.replaceAll('\\]', '');
            realId = realId.replaceAll('\'', '');
            for (String singleId : realId.split(',')) {
	            System.debug('gives real id: ' + singleId);
    	        realIds.add(singleId);
            }
        }
        return new List<List<String>> {realIds};
    }
}