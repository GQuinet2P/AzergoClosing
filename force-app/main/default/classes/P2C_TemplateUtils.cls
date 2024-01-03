public with sharing class P2C_TemplateUtils {

    public static List<MergeFieldItem> parseMergeFieldsFor(String templateText) {
        List<Integer> objectMergeFieldsPositions = getIndexesOfMergeFields(templateText);

        List<MergeFieldItem> mergeObjects = new List<MergeFieldItem>();
        for(Integer position : objectMergeFieldsPositions) {
            Integer mergeKeyEnd = templateText.indexOf('}', position);
            String mergeKey = templateText.substring(position, mergeKeyEnd + 1);
            String fieldName = mergeKey.substring(mergeKey.indexOf('.') + 1, mergeKey.length() - 1);
            String objectName = mergeKey.substring(2, mergeKey.indexOf('.'));
            Integer mergefieldLength = mergeKey.length();

            MergeFieldItem item = new MergeFieldItem();
            item.start = position;
            item.mergeKey = mergeKey;
            item.length = mergefieldLength;
            item.objectName = objectName;
            item.fieldName = fieldName;

            mergeObjects.add(item);
        }
        // console.log('results for flag key ' + flagKey);
        // console.log(JSON.stringify(mergeObjects));
        return mergeObjects;
    }

    public static List<Integer> getIndexesOfMergeFields(String stringToAnalyze) {
        Integer searchLen = 2;
        if (searchLen == 0) {
            return new List<Integer>{};
        }
        Integer startIndex = 0;
        Integer curIndex = 0;
        List<Integer> indexes = new List<Integer>{};

        while ((curIndex = stringToAnalyze.indexOf('{!', startIndex)) > -1) {
            indexes.add(curIndex);
            startIndex = curIndex + searchLen;
        }
        return indexes;
    }


    public static List<MergeListItem> parseMergeListFor(String templateText) {
        List<Integer> objectMergeFieldsPositions = getIndexesOfMergeFields(templateText);
        List<Integer> objectMergeListsPositions = getIndexesOfMergeList(templateText);

        List<MergeListItem> mergeObjects = new List<MergeListItem>();
        for(Integer position : objectMergeListsPositions) {
            Integer mergeListKeyEnd = templateText.indexOf(']]', position);
            String mergeListKey = templateText.substring(position, mergeListKeyEnd + 2);
            Integer mergeListLength = mergeListKey.length();
            
            MergeListItem item = new MergeListItem();
            item.start = position;
            item.mergeKey = mergeListKey;
            item.length = mergeListLength;
            item.mergeKeys = new List<String>();
            
            for (Integer fieldPos : objectMergeFieldsPositions) {
                if (fieldPos > position && fieldPos < (position + mergeListLength)) {
                    Integer mergeKeyEnd = templateText.indexOf('}', fieldPos);
                    String mergeKey = templateText.substring(fieldPos, mergeKeyEnd + 1);
                    item.mergeKeys.add(mergeKey);
                }
            }

            mergeObjects.add(item);
        }
        // console.log('results for flag key ' + flagKey);
        // console.log(JSON.stringify(mergeObjects));
        return mergeObjects;
    }

    public static List<Integer> getIndexesOfMergeList(String stringToAnalyze) {
        Integer searchLen = 2;
        if (searchLen == 0) {
            return new List<Integer>{};
        }
        Integer startIndex = 0;
        Integer curIndex = 0;
        List<Integer> indexes = new List<Integer>{};

        while ((curIndex = stringToAnalyze.indexOf('[[REPEAT', startIndex)) > -1) {
            indexes.add(curIndex);
            startIndex = curIndex + searchLen;
        }
        return indexes;
    }

    public static Map<String, List<String>> getFieldsByObjects(List<MergeFieldItem> items) {
        Map<String, List<String>> results = new Map<String, List<String>>();
        for (MergeFieldItem item : items) {
            if (!results.containsKey(item.objectName)) {
                results.put(item.objectName, new List<String>());
            }
            if (!results.get(item.objectName).contains(item.fieldName)) {
                results.get(item.objectName).add(item.fieldName);
            }
        }
        return results;
    }

    public class MergeListItem {
        public Integer start;
        public Integer length;
        public String mergeKey;
        public List<String> mergeKeys;
    }

    public class MergeFieldItem {
        public Integer start;
        public Integer length;
        public String mergeKey;
        public String objectName;
        public String fieldName;
    }
}