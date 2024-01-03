public with sharing class P2C_SObjectUtils {

    private static Map<String, Schema.DisplayType> fieldTypes;

    public static SObject setFieldValue(SObject record, String fieldName, Object value) {
        try {
            if (fieldTypes == null) {
                fieldTypes = new Map<String, Schema.DisplayType>();
            }
            if (!fieldTypes.containsKey(fieldName)) {
                Schema.DescribeSObjectResult sor = record.getSObjectType().getDescribe();

                if (sor.fields.getMap().containsKey(fieldName)) {
                    fieldTypes.put(fieldName, sor.fields.getMap().get(fieldName).getDescribe().getType());
                } else if (fieldName.endsWithIgnoreCase('__r')) {
                    System.debug('masterdetail field (' + fieldName + ') forced type: REFERENCE');
                    fieldTypes.put(fieldName, Schema.DisplayType.REFERENCE);
                }
            }

            if (fieldTypes.containsKey(fieldName)) {
                switch on fieldTypes.get(fieldName) {
                    when BOOLEAN {
                        Boolean boolValue = Boolean.valueOf(value);
                        record.put(fieldName, boolValue);
                    }
                    when DATE {
                        String[] dateParts = ((String)value).split('-');
                        Date valueDate = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
                        record.put(fieldName, valueDate);
                    }
                    when Currency {
                        record.put(fieldName, (Decimal)value);
                    }
                    when DOUBLE {
                        record.put(fieldName, (Decimal)value);
                    }
                    when REFERENCE {
                        if (value instanceof String) {
                            record.put(fieldName, (String)value);
                        } else if (value instanceof SObject) {
                            // System.debug('set ref field (' + fieldName.replace('__c', '__r') + ') with ' + (SObject)value);
                            record.putSObject(fieldName.replace('__c', '__r'), (SObject)value);
                        }
                    }
                    when else {
                        if (value instanceof String) {
                            record.put(fieldName, value);
                        } else if (value instanceof Integer || value instanceof Decimal || value instanceof Long || value instanceof Double){
                            record.put(fieldName, '' + value);
                        } else {
                            record.put(fieldName, value.toString());
                        }
                    }
                }
            }

            return record;
        } catch(Exception e) {
            System.debug('P2C_SObjectUtils failed to set field value on record for ' + fieldName);
            throw e;
        }
    }

    public static Map<String, String> getObjectFieldLabels(String objectApiName, List<String> fields) {
        Map<String, String> results = new Map<String, String>();
        SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        Map<String,Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

        List<P2C_OptionValueLabel> result = new List<P2C_OptionValueLabel>();

        for (String k : fieldMap.keyset()) {
            Schema.DescribeFieldResult describeField = fieldMap.get(k).getDescribe();
            if (fields.contains(describeField.getName())) {
                results.put(describeField.getName(), describeField.getLabel());
            }
        }
        return results;
    }

    public static Map<String, Map<String, Object>> getObjectsFieldsValues(String objectApiName, List<String> recordIds, List<String> fieldNames){
        System.debug('get fields value for record');
        System.debug('object ' + objectApiName);
        System.debug('ids ' + recordIds);
        System.debug('fields ' + fieldNames);

        String objectsQuery = 'SELECT Id, ';
        for (String fieldName : fieldNames) {
            fieldName = ownerTemplateFieldToRealField(fieldName);
            if (!fieldName.equalsIgnoreCase('id')) {
                objectsQuery += fieldName + ', ';
            }
        }
        if (objectsQuery.endsWith(', ')){
            objectsQuery = objectsQuery.substring(0, objectsQuery.lastIndexOf(', '));
        }
        objectsQuery += ' FROM ' + objectApiName + ' WHERE Id IN :recordIds';

        System.debug('Query fields on object');
        System.debug(objectsQuery);

        Map<String, Map<String, Object>> recordsFieldsValues = new Map<String, Map<String, Object>>();
        for (SObject obj : Database.query(objectsQuery)) {
            if (!recordsFieldsValues.containsKey(obj.Id)) {
                recordsFieldsValues.put(obj.Id, new Map<String, Object>());
            }
            for (String fieldName : fieldNames) {
                String realFieldName = ownerTemplateFieldToRealField(fieldName);
                recordsFieldsValues.get(obj.Id).put(fieldName, getObjectFieldValue(realFieldName, obj));
            }
        }
        return recordsFieldsValues;
    }


    public static Object getObjectFieldValue(String fieldName, SObject sourceObject) {
        Object fieldValue;
        SObject tmpObj = sourceObject;
        while(fieldName.indexOf('.') > 0) {
            // System.debug('       > split relation field: ' + fieldName);

            String step = fieldName.substring(0, fieldName.indexOf('.'));
            fieldName = fieldName.substring(fieldName.indexOf('.') + 1);

            // System.debug('       > get related object in relation: ' + step);
            tmpObj = tmpObj.getSObject(step);
            System.debug(tmpObj);
        }
        return tmpObj?.get(fieldName);
    }


    public static String ownerTemplateFieldToRealField(String fieldName) {
        switch on fieldName {
            when 'OwnerFullName' {
                return 'Owner.Name';
            }
            when 'OwnerEmail' {
                return 'Owner.Email';
            }
            when 'OwnerFirstName' {
                return 'Owner.FirstName';
            }
            when 'OwnerLastName' {
                return 'Owner.LastName';
            }
            when else {
                return fieldName;
            }
        }
    }
}