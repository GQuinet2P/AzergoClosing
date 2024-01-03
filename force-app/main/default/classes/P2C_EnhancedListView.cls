public without sharing class P2C_EnhancedListView {

    @AuraEnabled
    public static string getListviewConfig(String configName){
        try {
            List<P2C_EnhancedListviewConfig__c> configs = [SELECT Id, Name, ObjectApiName__c, MasterListviewConfig__c, SharedListview__c, ListviewPageRowsNumber__c, ListviewTitle__c, ListviewIcon__c FROM P2C_EnhancedListviewConfig__c WHERE Name = :configName OR MasterListviewConfig__r.Name = :configName];
            if (configs.isEmpty()) return null;

            ListviewConfig config;
            List<ListviewConfig> related = new List<ListviewConfig>();
            for (P2C_EnhancedListviewConfig__c lvConfig : configs) {
                ListviewConfig lv = new ListviewConfig();
                lv = new ListviewConfig();
                lv.configId = lvConfig.Id;
                lv.configName = lvConfig.Name;
                lv.objectApiName = lvConfig.ObjectApiName__c;
                lv.listviewTitle = lvConfig.ListviewTitle__c;
                lv.listviewIcon = lvConfig.ListviewIcon__c;
                lv.isShared = lvConfig.SharedListview__c;
                lv.rowsPerPage = lvConfig.ListviewPageRowsNumber__c.intValue();
                lv.defaultFields = new List<ListviewConfigDefaultField>();
                lv.defaultFilters = new List<ListviewConfigFilter>();
                lv.defaultSorters = new List<ListviewConfigSorter>();
                lv.actions = new List<ListviewConfigActions>();

                if (lvConfig.Name == configName) {
                    config = lv;
                } else {
                    related.add(lv);
                }
            }
            if (config == null) return null;

            User u = [SELECT Id, ProfileId FROM User WHERE Id = :UserInfo.getUserId()];
            SObjectType objectType = Schema.getGlobalDescribe().get(config.objectApiName);
            for (Schema.RecordTypeInfo rtInfo : objectType.getDescribe().getRecordTypeInfos()) {
                if (rtInfo.isDefaultRecordTypeMapping()) {
                    config.defaultRecordTypeId = rtInfo.getRecordTypeId();
                //   System.debug(rtInfo);
                }
            }
            // ProfileRecordTypeTable prtt = [SELECT Id, RecordTypeId FROM ProfileRecordTypeTable WHERE sObjectType = :config.objectApiName AND IsDefault = TRUE];
            // if (prtt != null) config.defaultRecordTypeId = prtt.RecordTypeId;

            config.relatedListviews = related;

            for (P2C_EnhancedListviewUserPreferences__c usrPref : [SELECT EnhancedListviewConfig__c, PinnedListview__c, ListviewPageRowsNumber__c, ListviewsSortingPrefs__c FROM P2C_EnhancedListviewUserPreferences__c WHERE OwnerId = :UserInfo.getUserId() AND EnhancedListviewConfig__c = :config.configId LIMIT 1]) {
                ListviewUserPrefs pref = new ListviewUserPrefs();
                pref.configId = usrPref.EnhancedListviewConfig__c;
                pref.rowsPerPage = usrPref.ListviewPageRowsNumber__c.intValue();
                if (usrPref.PinnedListview__c != null) pref.pinnedListviewId = usrPref.PinnedListview__c;
                
                for (P2C_EnhancedListviewSortingField__c field : [SELECT Id, Name, FieldAPIName__c, SortingDirection__c, SortingOrder__c FROM P2C_EnhancedListviewSortingField__c WHERE EnhancedListviewConfig__c = :config.configId AND EnhancedListviewUserPreferences__c = '' ORDER BY SortingOrder__c]) {
                    if (pref.defaultSorters == null) pref.defaultSorters = new List<ListviewConfigSorter>();
                    ListviewConfigSorter df = new ListviewConfigSorter();
                    df.fieldApiName = field.FieldAPIName__c;
                    df.direction = field.SortingDirection__c;
                    df.soqlValue = field.FieldAPIName__c + ' ' + field.SortingDirection__c;
                    df.sortOrder = field.SortingOrder__c.intValue();
                    pref.defaultSorters.add(df);
                }

                if (usrPref.ListviewsSortingPrefs__c != null && !String.isBlank(usrPref.ListviewsSortingPrefs__c)) {
                    List<UserListviewsSorters> sorters = (List<UserListviewsSorters>)JSON.deserialize(usrPref.ListviewsSortingPrefs__c, List<UserListviewsSorters>.class);
                    pref.listviewsSorters = sorters;
                }
                config.userPrefs = pref;
            }

            for (P2C_EnhancedListviewDefaultField__c field : [SELECT Id, Name, FieldAPIName__c, TableColumnLabel__c, IsEditable__c, DisplayOrder__c, IsLinkToRecord__c, LinkHoverShowDetails__c, LinkHoverDetailsLayout__c, LookupFieldToDisplay__c, PopupWidth__c, PopupAlignment__c FROM P2C_EnhancedListviewDefaultField__c WHERE EnhancedListviewConfig__c = :config.configId ORDER BY DisplayOrder__c]) {
                ListviewConfigDefaultField df = new ListviewConfigDefaultField();
                df.fieldApiName = field.FieldAPIName__c;
                df.fieldColumnLabel = field.TableColumnLabel__c;
                df.displayOrder = field.DisplayOrder__c.intValue();
                if (field.IsEditable__c) df.isEditable = true;
                if (field.IsLinkToRecord__c) df.isLinkToRecord = true;
                if (field.LookupFieldToDisplay__c != null && field.LookupFieldToDisplay__c != '') df.lookupFieldToDisplay = field.LookupFieldToDisplay__c;
                if (field.LinkHoverShowDetails__c) {
                    df.popupAlign = field.PopupAlignment__c;
                    df.popupWidth = field.PopupWidth__c != null ? field.PopupWidth__c.intValue() : 800;
                    df.linkHoverShowDetails = true;
                    df.showDetailsLayout = field.LinkHoverDetailsLayout__c;
                }
                config.defaultFields.add(df);
            }
            for (P2C_EnhancedListviewFilter__c field : [SELECT Id, Name, FieldAPIName__c, Condition__c, Value__c FROM P2C_EnhancedListviewFilter__c WHERE EnhancedListviewConfig__c = :config.configId]) {
                ListviewConfigFilter df = new ListviewConfigFilter();
                df.fieldApiName = field.FieldAPIName__c;
                df.condition = field.Condition__c;
                                df.value = field.Value__c;
                df.soqlValue = field.Condition__c.contains('{field}') ? field.Condition__c : field.FieldAPIName__c + ' ' + field.Condition__c;
                df.soqlValue = df.soqlValue.replace('{value}', field.Value__c);
                df.soqlValue = df.soqlValue.replace('{field}', field.FieldAPIName__c);
                config.defaultFilters.add(df);
            }
            for (P2C_EnhancedListviewSortingField__c field : [SELECT Id, Name, FieldAPIName__c, SortingDirection__c, SortingOrder__c FROM P2C_EnhancedListviewSortingField__c WHERE EnhancedListviewConfig__c = :config.configId AND EnhancedListviewUserPreferences__c = '' ORDER BY SortingOrder__c]) {
                ListviewConfigSorter df = new ListviewConfigSorter();
                df.fieldApiName = field.FieldAPIName__c;
                df.direction = field.SortingDirection__c;
                df.soqlValue = field.FieldAPIName__c + ' ' + field.SortingDirection__c;
                df.sortOrder = field.SortingOrder__c.intValue();
                config.defaultSorters.add(df);
            }
            for (P2C_EnhancedListviewAction__c action : [SELECT Id, Label__c, ActionType__c, FlowApiName__c, Url__c, ShowActionWhen__c FROM P2C_EnhancedListviewAction__c WHERE EnhancedListviewConfig__c = :config.configId]) {
                ListviewConfigActions df = new ListviewConfigActions();
                df.actionLabel = action.Label__c;
                df.actionTarget = action.Url__c != null ? action.Url__c : action.FlowApiName__c;
                df.actionType = action.ActionType__c;
                df.showCondition = action.ShowActionWhen__c != null ? action.ShowActionWhen__c : null;
                config.actions.add(df);
            }
            return JSON.serialize(config);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ListviewConfig {
        public String defaultRecordTypeId;
        public String stdListviewId;
        public String configId;
        public String configName;
        public String listviewTitle;
        public String listviewIcon;
        public String objectApiName;
        public List<ListviewConfigDefaultField> defaultFields;
        public List<ListviewConfigFilter> defaultFilters;
        public List<ListviewConfigSorter> defaultSorters;
        public List<ListviewConfigActions> actions;
        public Boolean isShared;
        public String masterListviewConfig;
        public List<ListviewConfig> relatedListviews;
        public ListviewUserPrefs userPrefs;
        public Integer rowsPerPage;
        public String scope;
    }

    public class ListviewUserPrefs {
        public String pinnedListviewId;
        public String configId;
        public Integer rowsPerPage;
        public List<ListviewConfigSorter> defaultSorters;
        public List<UserListviewsSorters> listviewsSorters;
    }

    public class ListviewSorterOverride {
        public String listviewId;
        public List<ListviewSorter> orderBy;
    }

    public class ListviewSorter {
        public String fieldNameOrPath;
        public String sortDirection;
        public String nullsPosition;
    }

    public class ListviewConfigDefaultField {
        public String fieldApiName;
        public String fieldColumnLabel;
        public Integer displayOrder;
        public Boolean isEditable;
        public Boolean isLinkToRecord;
        public Boolean linkHoverShowDetails;
        public String lookupFieldToDisplay;
        public String showDetailsLayout;
        public String popupAlign;
        public Integer popupWidth;
    }

    public class LvConditionsMapper {
        public String conjunction;
        public List<LvConditionsMapper> conditions;

        public String field;
        public String operator;
        public List<Object> values;

        public void parseJson(String jsonCondition) {
            Map<String, Object> payload = (Map<String,Object>)JSON.deserializeUntyped(jsonCondition);
            if (payload.containsKey('field')) this.field = (String)payload.get('field');
            if (payload.containsKey('operator')) this.operator = (String)payload.get('operator');
            if (payload.containsKey('conjunction')) this.conjunction = (String)payload.get('conjunction');
            if (payload.containsKey('values')) this.values = (List<Object>)payload.get('values');

            if (payload.containsKey('conditions')) {
                this.conditions = new List<LvConditionsMapper>();
                for (Object cond : (List<Object>)payload.get('conditions')) {
                    LvConditionsMapper cm = new LvConditionsMapper();
                    cm.parseJson(JSON.serialize(cond));
                    this.conditions.add(cm);
                }
            }
        }
    }

    public class ListviewConfigFilter {
        public String fieldApiName;
        public String condition;
        public String value;
        public String soqlValue;
        public List<ListviewConfigFilter> subFilters;
        public String conjunction;
        public Integer filterLevel;

        public void setFilter(String field, String operator, List<Object> values, String conjunction) {
            this.fieldApiName = field;
            this.condition = ListviewDescribeConditionToEnhancedListviewCondition(operator);
            this.soqlValue = this.condition.contains('{field}') ? this.condition : this.fieldApiName + ' ' + this.condition;
            this.conjunction = conjunction;

            switch on operator {
                when 'equals','notEquals','lessThan','greaterThan','lessThanOrEqualTo','greaterThanOrEqualTo','notLike','like' { //'startsWith',
                    String val = (String)values.get(0);
                    if (val == null) val = 'null';
                    this.soqlValue = this.soqlValue.replace('{value}', val);
                    this.soqlValue = this.soqlValue.replace('{field}', this.fieldApiName);
                    this.value = val;
                }
                when 'includes','excludes','in','notIn' { //'contains','notContain',
                    List<Object> vals = new List<Object>();
                    for (Object val : values) {
                        vals.add(val);
                    }
                    this.soqlValue = this.soqlValue.replace('{value}', JSON.serialize(vals));
                    this.soqlValue = this.soqlValue.replace('{field}', this.fieldApiName);
                    this.value = JSON.serialize(vals);
                }
                when else {
                    System.debug('Unsuported condition');
                }
            }
        }
    }

    public class UserListviewsSorters {
        public String listviewId;
        public List<ListviewConfigSorter> listviewSorters;
    }

    public class ListviewConfigSorter {
        public String fieldApiName;
        public String direction;
        public Integer sortOrder;
        public String soqlValue;
    }

    public class ListviewConfigActions {
        public String actionLabel;
        public String showCondition;
        public String actionType;
        public String actionTarget;
    }

    @AuraEnabled
    public static string executeQueryCount(String objectApiName, String whereClause, String scope){
        try {
            String query = 'SELECT COUNT() FROM ' + objectApiName;
            if (scope != null) query += ' ' + scope + ' ';
            if (whereClause != null) query += whereClause;
            System.debug('query: ' + query);

            return JSON.serialize(Database.countQuery(query));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string executeQuery(String objectApiName, String fields, String scope, String whereClause, String orderClause, Integer rowNumber, Integer startIndex){
        try {
            if (fields == null) fields = 'Id, Name';
            if (!fields.contains('Id')) fields = 'Id, ' + fields;

            String query = 'SELECT ' + fields + ' FROM ' + objectApiName;
            if (scope != null) query += ' ' + scope + ' ';
            if (whereClause != null) query += whereClause;
            if (orderClause != null) query += orderClause;
            if (rowNumber != null) query += ' LIMIT ' + rowNumber;
            if (startIndex != null && startIndex > 0) query += ' OFFSET ' + startIndex;
            System.debug('query: ' + query);

            return JSON.serialize(Database.query(query));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string getObjectFieldsNamesSorted(String objectApiName){
        // System.debug('looking for fields of ' + objectApiName);
        try {
            SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
            Map<String,Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

            List<P2C_OptionValueLabel> result = new List<P2C_OptionValueLabel>();

            for (String k : fieldMap.keyset()) {
                Schema.DescribeFieldResult describeField = fieldMap.get(k).getDescribe();

                if (!describeField.isAccessible()) { continue; }
    
                String fieldName = describeField.getName();
                String fieldLabel = describeField.getLabel();

                P2C_OptionValueLabel option = new P2C_OptionValueLabel(fieldName, fieldLabel);
                option.isSortable = describeField.isSortable();

                if (describeField.getType() == Schema.DisplayType.REFERENCE) {
                    option.isReference = true;
                    option.type = 'lookup';
                    List<P2C_OptionValueLabel> referenceTargets = new List<P2C_OptionValueLabel>();

                    // fieldName = fieldName.endsWith('__c') ? fieldName.replace('__c', '__r') : fieldName;
                    // String targets = '#';
                    for (Schema.sObjectType targetSObjectType : describeField.getReferenceTo()) {
                        Schema.DescribeSObjectResult describeObject = targetSObjectType.getDescribe();
                        if (!describeObject.isAccessible()) { continue; }
            
                        String objName = describeObject.getName();
                        String objLabel = describeObject.getLabel();
            
                        if (!isStandardOrCustomObject(objName)) { continue; }
            
                        referenceTargets.add(new P2C_OptionValueLabel(objName, objLabel));
                    }
                    option.referenceTargets = referenceTargets;
                } else {
                    option.type = getDatatableTypeFor(describeField.getType());
                    if (option.type == 'picklist') {
                        option.restrictedValues = new List<P2C_OptionValueLabel>();
                        List<Schema.PicklistEntry> ple = describeField.getPicklistValues();
                        for( Schema.PicklistEntry pickListVal : ple){
                            P2C_OptionValueLabel picklistOption = new P2C_OptionValueLabel(pickListVal.getValue(), pickListVal.getLabel());
                            option.restrictedValues.add(picklistOption);
                        }
                    }
                }
    
                result.add(option);
            }
            result.sort();
    
            return JSON.serialize(result);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static string getObjectInfoFromApiName(String objectApiName){
        try {
            SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
            Schema.DescribeSObjectResult describeObject = objectType.getDescribe();
            if (!describeObject.isAccessible()) { throw new AuraHandledException('Object not enabled for user'); }

            String objName = describeObject.getName();
            String objLabel = describeObject.getLabel();
    
            if (!isStandardOrCustomObject(objName)) { throw new AuraHandledException('Not a correct object'); }

            P2C_OptionValueLabel result = new P2C_OptionValueLabel(objName, objLabel);
            return JSON.serialize(result);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    private static Boolean isStandardOrCustomObject(String objectApiName) {
        return !objectApiName.endsWithIgnoreCase('history') 
            && !objectApiName.endsWithIgnoreCase('share')
            && !objectApiName.endsWithIgnoreCase('tag')
            && !objectApiName.endsWithIgnoreCase('feed')
            && !objectApiName.endsWithIgnoreCase('event');
    }


    private static String getDatatableTypeFor(Schema.DisplayType sfType) {
        switch on sfType {
            when TEXTAREA {
                return 'richtext';
            }
            when ADDRESS, STRING {
                return 'text';
            }
            when EMAIL {
                return 'email';
            }
            when DATE {
                return 'date-local';
            }
            when DATETIME {
                return 'date';
            }
            when DOUBLE, INTEGER, LONG {
                return 'number';
            }
            when BOOLEAN {
                return 'boolean';
            }
            when CURRENCY {
                return 'currency';
            }
            when PERCENT {
                return 'percent';
            }
            when PHONE {
                return 'phone';
            }
            when URL {
                return 'url';
            }
            when PICKLIST, MULTIPICKLIST, COMBOBOX {
                return 'picklist';
            }
            when else {
                return 'text';
            }
        }
        // anytype
        // base64
        // DataCategoryGroupReference
        // EncryptedString
        // ID
        // Location
        // Time
        // Combobox
    }

    private static List<ListviewConfig> convertListviewsForObject(String objectApiName, String masterConfigId) {
        List<ListviewConfig> configs = new List<ListviewConfig>();

        Map<String, ListviewConfigDefaultField> defaultFieldsMap = new Map<String, ListviewConfigDefaultField>();
        if (masterConfigId != null) {
            for (P2C_EnhancedListviewDefaultField__c field : [SELECT Id, Name, FieldAPIName__c, TableColumnLabel__c, IsEditable__c, DisplayOrder__c, IsLinkToRecord__c, LinkHoverShowDetails__c, LinkHoverDetailsLayout__c, LookupFieldToDisplay__c, PopupAlignment__c, PopupWidth__c FROM P2C_EnhancedListviewDefaultField__c WHERE EnhancedListviewConfig__c = :masterConfigId ORDER BY DisplayOrder__c]) {
                ListviewConfigDefaultField df = new ListviewConfigDefaultField();
                df.fieldApiName = field.FieldAPIName__c;
                df.fieldColumnLabel = field.TableColumnLabel__c;
                df.displayOrder = field.DisplayOrder__c.intValue();
                if (field.IsEditable__c) df.isEditable = true;
                if (field.IsLinkToRecord__c) df.isLinkToRecord = true;
                if (field.LookupFieldToDisplay__c != null && field.LookupFieldToDisplay__c != '') df.lookupFieldToDisplay = field.LookupFieldToDisplay__c;
                if (field.LinkHoverShowDetails__c) {
                    df.popupAlign = field.PopupAlignment__c;
                    df.popupWidth = field.PopupWidth__c != null ? field.PopupWidth__c.intValue() : 800;
                    df.linkHoverShowDetails = true;
                    df.showDetailsLayout = field.LinkHoverDetailsLayout__c;
                }
                defaultFieldsMap.put(df.fieldApiName, df);
            }

            // for (P2C_EnhancedListviewSortingField__c field : [SELECT Id, Name, FieldAPIName__c, SortingDirection__c, SortingOrder__c FROM P2C_EnhancedListviewSortingField__c WHERE OwnerId = :UserInfo.getUserId() AND EnhancedListviewConfig__c = :masterConfigId AND EnhancedListviewUserPreferences__c = '' ORDER BY SortingOrder__c]) {
            //     ListviewConfigSorter df = new ListviewConfigSorter();
            //     df.fieldApiName = field.FieldAPIName__c;
            //     df.direction = field.SortingDirection__c;
            //     df.soqlValue = field.FieldAPIName__c + ' ' + field.SortingDirection__c;
            //     df.sortOrder = field.SortingOrder__c.intValue();
            //     config.defaultSorters.add(df);
            // }
        }

        List<ListviewConfigActions> actions = new List<ListviewConfigActions>();
        for (P2C_EnhancedListviewAction__c action : [SELECT Id, Label__c, ActionType__c, FlowApiName__c, Url__c, ShowActionWhen__c FROM P2C_EnhancedListviewAction__c WHERE EnhancedListviewConfig__c = :masterConfigId]) {
            ListviewConfigActions df = new ListviewConfigActions();
            df.actionLabel = action.Label__c;
            df.actionTarget = action.Url__c != null ? action.Url__c : action.FlowApiName__c;
            df.actionType = action.ActionType__c;
            df.showCondition = action.ShowActionWhen__c != null ? action.ShowActionWhen__c : null;
            actions.add(df);
        }

        String sessionId = fetchUserSessionId();
        List<ListView> lvs = [SELECT SobjectType, Id, Name, DeveloperName FROM ListView WHERE SobjectType = :objectApiName AND DeveloperName like '%Closing%'];

        for (ListView ulv : lvs) {
            HttpRequest req = new HttpRequest();
            String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
            String endPoinURL = baseUrl+'/services/data/v56.0/sobjects/' + objectApiName + '/listviews/' + ulv.Id + '/describe';
            req.setEndpoint(endPoinURL);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + sessionId);
            Http http = new Http();
            HttpResponse response = http.send(req);

            if (response.getStatusCode() == 200 ) {
                if (ulv.Id == '00B7E0000076ANoUAM') {
                    System.debug('api response:');
                    System.debug(response.getBody());
                }
                
                Map<String, Object> tokenResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                List<Object> cols = (List<Object>) tokenResponse.get('columns');
                List<Object> conditions = new List<Object>();
                String scope;
                // if (tokenResponse.get('whereCondition') != null) conditions.add((Object) tokenResponse.get('whereCondition'));
                if (tokenResponse.get('scope') != null) scope = String.valueOf(tokenResponse.get('scope'));
                List<Object> orders = (List<Object>) tokenResponse.get('orderBy');
                System.debug('token is ' + response);

                ListviewConfig conf = new ListviewConfig();
                conf.stdListviewId = ulv.Id;
                conf.configId = ulv.Id;
                conf.configName = ulv.Name;
                conf.objectApiName = objectApiName;
                conf.scope = scope;
                conf.defaultFields = new List<ListviewConfigDefaultField>();
                if (actions.size() > 0) conf.actions = actions;
                Integer idx = 0;
                for (Object col : cols) {
                    String colJs = JSON.serialize(col);
                    Map<String, Object> colFlds = (Map<String, Object>)JSON.deserializeUntyped(colJs);

                    if ((Boolean)colFlds.get('hidden')) continue;

                    ListviewConfigDefaultField defaultField = new ListviewConfigDefaultField();
                    defaultField.fieldApiName = (String)colFlds.get('fieldNameOrPath');
                    defaultField.fieldColumnLabel = (String)colFlds.get('label');
                    defaultField.displayOrder = (Integer)colFlds.get('sortIndex');
                    defaultField.displayOrder = idx;
                    idx++;
                    if (defaultFieldsMap.containsKey(defaultField.fieldApiName)) {
                        defaultField.isEditable = defaultFieldsMap.get(defaultField.fieldApiName).isEditable;
                        defaultField.isLinkToRecord = defaultFieldsMap.get(defaultField.fieldApiName).isLinkToRecord;
                        defaultField.linkHoverShowDetails = defaultFieldsMap.get(defaultField.fieldApiName).linkHoverShowDetails;
                        defaultField.showDetailsLayout = defaultFieldsMap.get(defaultField.fieldApiName).showDetailsLayout;
                        defaultField.lookupFieldToDisplay = defaultFieldsMap.get(defaultField.fieldApiName).lookupFieldToDisplay;
                        defaultField.popupAlign = defaultFieldsMap.get(defaultField.fieldApiName).popupAlign;
                        defaultField.popupWidth = defaultFieldsMap.get(defaultField.fieldApiName).popupWidth;
                    } else if (defaultField.fieldApiName.contains('.')) {
                        String fldApiName = defaultField.fieldApiName.substring(0, defaultField.fieldApiName.indexOf('.'));
                        String lookupField = defaultField.fieldApiName.substring(defaultField.fieldApiName.indexOf('.') + 1, defaultField.fieldApiName.length());
                        if (fldApiName.endsWith('__r')) {
                            fldApiName = fldApiName.replace('__r', '__c');
                        } else {
                            fldApiName += 'Id';
                        }
                        if (defaultFieldsMap.containsKey(fldApiName)) {
                            defaultField.isEditable = defaultFieldsMap.get(fldApiName).isEditable;
                            defaultField.isLinkToRecord = defaultFieldsMap.get(fldApiName).isLinkToRecord;
                            defaultField.linkHoverShowDetails = defaultFieldsMap.get(fldApiName).linkHoverShowDetails;
                            defaultField.showDetailsLayout = defaultFieldsMap.get(fldApiName).showDetailsLayout;
                            defaultField.lookupFieldToDisplay = defaultFieldsMap.get(fldApiName).lookupFieldToDisplay;
                            defaultField.popupAlign = defaultFieldsMap.get(fldApiName).popupAlign;
                            defaultField.popupWidth = defaultFieldsMap.get(fldApiName).popupWidth;
                        } else {
                            defaultField.isLinkToRecord = true;
                            defaultField.lookupFieldToDisplay = lookupField;
                        }
                        defaultField.fieldApiName = fldApiName;
                    }
                    conf.defaultFields.add(defaultField);
                }

                if (tokenResponse.get('whereCondition') != null) {
                    String whereCond = JSON.serialize(tokenResponse.get('whereCondition'));
                    LvConditionsMapper mapper = new LvConditionsMapper();
                    mapper.parseJson(whereCond);
                    
                    System.debug('parse filters for ' + ulv.Name + ':');
                    System.debug(whereCond);
                    conf.defaultFilters = getConditions(new List<P2C_EnhancedListView.LvConditionsMapper> {mapper}, null);
                }

                conf.defaultSorters = new List<ListviewConfigSorter>();

                idx = 0;
                for(Object ord : orders) {
                    String ordJs = JSON.serialize(ord);
                    Map<String, Object> ordFlds = (Map<String, Object>)JSON.deserializeUntyped(ordJs);
                    ListviewConfigSorter sortFld = new ListviewConfigSorter();
                    sortFld.fieldApiName = (String)ordFlds.get('fieldNameOrPath');
                    sortFld.direction = ('ascending' == (String)ordFlds.get('sortDirection')) ? 'ASC' : 'DESC';
                    sortFld.soqlValue = sortFld.fieldApiName + ' ' + sortFld.direction;
                    sortFld.sortOrder = idx;
                    idx++;
                    conf.defaultSorters.add(sortFld);
                }
                configs.add(conf);
            }
        }
        return configs;
    }

    public static List<ListviewConfigFilter> getConditions(List<LvConditionsMapper> conditions, String conjunction) {
        List<ListviewConfigFilter> results = new List<ListviewConfigFilter>();

        for (LvConditionsMapper condition : conditions) {
            ListviewConfigFilter flt = new ListviewConfigFilter();

            if (condition.field != null) {
                flt.setFilter(condition.field, condition.operator, condition.values, conjunction?.toUpperCase());
            }

            if (condition.conditions != null) {
                flt.subFilters = getConditions(condition.conditions, condition.conjunction);
            }
            results.add(flt);
        }

        return results;
    }

    @testVisible
    private static String ListviewDescribeConditionToEnhancedListviewCondition(String descCondition) {
        switch on descCondition {
            when 'equals' {
                return '= {value}';
            }
            when 'notEquals' {
                return '<> {value}';
            }
            when 'lessThan' {
                return '< {value}';
            }
            when 'greaterThan' {
                return '> {value}';
            }
            when 'lessThanOrEqualTo' {
                return '<= {value}';
            }
            when 'greaterThanOrEqualTo' {
                return '>= {value}';
            }
            when 'notLike' {
                return '(not {field} like {value})';
            }
            when 'like' {
                return 'like {value}';
            }
            when 'includes' {
                return 'like {value}';
            }
            when 'excludes' {
                return '(not {field} like {value})';
            }
            when 'in' {
                return 'in ({value})';
            }
            when 'notIn' {
                return '= ({value})';
            }
            when else {
                return '';
            }
        }
    }

    // public static void saveListviewConfigs(List<ListviewConfig> configs, String masterConfigId){
    //     for (ListviewConfig lvconf : configs) {
    //         P2C_EnhancedListviewConfig__c configData = new P2C_EnhancedListviewConfig__c();
    //         if (masterConfigId != null) configData.MasterListviewConfig__c = masterConfigId;
    //         if (lvconf.stdListviewId != null) configData.StandardListviewId__c = lvconf.stdListviewId;
    //         configData.Name = lvconf.configName;
    //         configData.ObjectApiName__c = lvconf.objectApiName;
    //         if (lvconf.isShared) configData.SharedListview__c = true;
    //         insert configData;

    //         List<P2C_EnhancedListviewDefaultField__c> defaultFields = new List<P2C_EnhancedListviewDefaultField__c>();
    //         for (ListviewConfigDefaultField defFld : lvconf.defaultFields) {
    //             P2C_EnhancedListviewDefaultField__c fieldData = new P2C_EnhancedListviewDefaultField__c();
    //             fieldData.FieldAPIName__c = defFld.fieldApiName;
    //             fieldData.TableColumnLabel__c = defFld.fieldColumnLabel;
    //             fieldData.DisplayOrder__c = defFld.displayOrder;
    //             fieldData.IsEditable__c = defFld.isEditable;
    //             fieldData.IsLinkToRecord__c = defFld.isLinkToRecord;
    //             fieldData.LookupFieldToDisplay__c = defFld.lookupFieldToDisplay;
    //             fieldData.LinkHoverShowDetails__c = defFld.linkHoverShowDetails;
    //             fieldData.LinkHoverDetailsLayout__c = defFld.showDetailsLayout;
    //             fieldData.EnhancedListviewConfig__c = configData.Id;
    //             defaultFields.add(fieldData);
    //         }
    //         insert defaultFields;

    //         List<P2C_EnhancedListviewFilter__c> filters = new List<P2C_EnhancedListviewFilter__c>();
    //         for (ListviewConfigFilter field : lvconf.defaultFilters) {
    //             P2C_EnhancedListviewFilter__c df = new P2C_EnhancedListviewFilter__c();
    //             df.FieldAPIName__c = field.fieldApiName;
    //             df.Condition__c = field.condition;
    //             df.Value__c = field.value;
    //             df.EnhancedListviewConfig__c = configData.Id;
    //             filters.add(df);
    //         }
    //         insert filters;

    //         List<P2C_EnhancedListviewSortingField__c> sorters = new List<P2C_EnhancedListviewSortingField__c>();
    //         for (ListviewConfigSorter field : lvconf.defaultSorters) {
    //             P2C_EnhancedListviewSortingField__c df = new P2C_EnhancedListviewSortingField__c();
    //             df.FieldAPIName__c = field.fieldApiName;
    //             df.SortingDirection__c = field.direction;
    //             df.SortingOrder__c = field.sortOrder;
    //             df.EnhancedListviewConfig__c = configData.Id;
    //             sorters.add(df);
    //         }
    //         insert sorters;
    //     }
    // }

    @AuraEnabled
    public static string getListview(String objectApiName, String masterConfigId){
        try {
            List<ListviewConfig> confs = convertListviewsForObject(objectApiName, masterConfigId);
            System.debug(JSON.serialize(confs));

            return JSON.serialize(confs);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

    }


    public static String fetchUserSessionId(){
        String sessionId = '';
        PageReference reportPage = Page.P2C_GetSessionIdForLwc;
        String vfContent;
        if (Test.isRunningTest()) {
            vfContent = 'Start_Of_Session_Id' + UserInfo.getSessionId() + 'End_Of_Session_Id';
        } else {
            vfContent = reportPage.getContent().toString();
        }
        Integer startP = vfContent.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(),
        endP = vfContent.indexOf('End_Of_Session_Id');
        sessionId = vfContent.substring(startP, endP);

        return sessionId;
    }

    @AuraEnabled
    public static void pinUnpinListview(String listviewId, String masterListviewId){
        try {
            if (listviewId != null && masterListviewId != null) {
                List<P2C_EnhancedListviewUserPreferences__c> userPrefs = [SELECT Id, EnhancedListviewConfig__c, PinnedListview__c FROM P2C_EnhancedListviewUserPreferences__c WHERE OwnerId = :UserInfo.getUserId() AND EnhancedListviewConfig__c = :masterListviewId LIMIT 1];
                if (userPrefs != null && !userPrefs.isEmpty()) {
                    P2C_EnhancedListviewUserPreferences__c updatePref = new P2C_EnhancedListviewUserPreferences__c();
                    updatePref.Id = userPrefs.get(0).Id;

                    if (userPrefs.get(0).PinnedListview__c != listviewId) {
                        updatePref.PinnedListview__c = listviewId;
                    } else {
                        updatePref.PinnedListview__c = null;
                    }
                    update updatePref;
                } else {
                    P2C_EnhancedListviewUserPreferences__c updatePref = new P2C_EnhancedListviewUserPreferences__c();
                    updatePref.EnhancedListviewConfig__c = masterListviewId;
                    updatePref.PinnedListview__c = listviewId;
                    insert updatePref;
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error when saving user preferences: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateUserPrefListviewSorters(String listviewsSorters, String masterListviewId){
        try {
            if (listviewsSorters != null && masterListviewId != null) {
                List<P2C_EnhancedListviewUserPreferences__c> userPrefs = [SELECT Id, EnhancedListviewConfig__c, ListviewsSortingPrefs__c FROM P2C_EnhancedListviewUserPreferences__c WHERE OwnerId = :UserInfo.getUserId() AND EnhancedListviewConfig__c = :masterListviewId LIMIT 1];
                if (userPrefs != null && !userPrefs.isEmpty()) {
                    P2C_EnhancedListviewUserPreferences__c updatePref = userPrefs.get(0);
                    updatePref.ListviewsSortingPrefs__c = listviewsSorters;
                    update updatePref;
                } else {
                    P2C_EnhancedListviewUserPreferences__c updatePref = new P2C_EnhancedListviewUserPreferences__c();
                    updatePref.EnhancedListviewConfig__c = masterListviewId;
                    updatePref.ListviewsSortingPrefs__c = listviewsSorters;
                    insert updatePref;
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error when saving user preferences: ' + e.getMessage());
        }
    }
}