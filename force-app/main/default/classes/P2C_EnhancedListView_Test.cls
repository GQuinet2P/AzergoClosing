@isTest
public with sharing class P2C_EnhancedListView_Test {

    @TestSetup
    static void setupTests(){
        User usr = [SELECT Id, ALS_Bypass_Validation_rule__c FROM User WHERE Id = :UserInfo.getUserId()];
        usr.ALS_Bypass_Validation_rule__c = true;
        update usr;
        
        P2C_EnhancedListviewConfig__c cfg = new P2C_EnhancedListviewConfig__c();
        cfg.ObjectApiName__c = 'Opportunity';
        cfg.Name = 'test';
        cfg.SharedListview__c = true;
        insert cfg;

        P2C_EnhancedListviewDefaultField__c fld1 = new P2C_EnhancedListviewDefaultField__c();
        fld1.Name = 'name';
        fld1.EnhancedListviewConfig__c = cfg.Id;
        fld1.FieldAPIName__c = 'Name';
        fld1.TableColumnLabel__c = 'Name';
        fld1.DisplayOrder__c = 1;
        fld1.IsEditable__c = true;
        fld1.IsLinkToRecord__c = true;
        fld1.LinkHoverShowDetails__c = true;
        fld1.LinkHoverDetailsLayout__c = '{"columns":[{"label": "firstcol","rows":[{"fieldApiName": "OwnerId"},{"fieldApiName": "TYPE_D_OPPORTUNITE__c"},{"fieldApiName": "Equipement_en_place__c"}]},{"label": "secondcol","rows":[{"fieldApiName": "Numero_de_devis_SF__c"},{"fieldApiName": "Commentaire_interne__c"},{"fieldApiName": "Commentaire_Demande_de_Devis__c"}]}]}';
        fld1.LookupFieldToDisplay__c = 'Name';
        fld1.PopupWidth__c = 500;
        fld1.PopupAlignment__c = 'Auto';
        
        P2C_EnhancedListviewDefaultField__c fld2 = new P2C_EnhancedListviewDefaultField__c();
        fld2.Name = 'owner';
        fld2.EnhancedListviewConfig__c = cfg.Id;
        fld2.FieldAPIName__c = 'OwnerId';
        fld2.TableColumnLabel__c = 'Propriétaire';
        fld2.DisplayOrder__c = 2;
        fld2.IsEditable__c = true;
        fld2.IsLinkToRecord__c = true;
        fld2.LookupFieldToDisplay__c = 'Name';
        insert new List<P2C_EnhancedListviewDefaultField__c> {fld1, fld2};

        P2C_EnhancedListviewFilter__c filt = new P2C_EnhancedListviewFilter__c();
        filt.EnhancedListviewConfig__c = cfg.Id;
        filt.FieldAPIName__c = 'Name';
        filt.Condition__c = 'like \'%{value}%\'';
        filt.Value__c = 'test';
        insert filt;

        P2C_EnhancedListviewSortingField__c sortfld = new P2C_EnhancedListviewSortingField__c();
        sortfld.EnhancedListviewConfig__c = cfg.Id;
        sortfld.FieldAPIName__c = 'Name';
        sortfld.SortingDirection__c = 'DESC';
        sortfld.SortingOrder__c = 1;
        insert sortfld;

        P2C_EnhancedListviewAction__c action = new P2C_EnhancedListviewAction__c();
        action.EnhancedListviewConfig__c = cfg.Id;
        action.Label__c = 'testaction';
        action.FlowApiName__c = 'testflow';
        action.ActionType__c = 'Flow';
        action.ShowActionWhen__c = 'One record is selected';
        insert action;


        TestDataFactory.createOpportunity();
    }

    @isTest
    public static void testGetListviewConfig() {
        String result = P2C_EnhancedListView.getListviewConfig('test');

        Assert.isNotNull(result);
    }

    @isTest
    public static void testListviewDescribeConditionToEnhancedListviewCondition() {
        Assert.areEqual('= {value}', P2C_EnhancedListView.ListviewDescribeConditionToEnhancedListviewCondition('equals'));
        Assert.areEqual('<> {value}', P2C_EnhancedListView.ListviewDescribeConditionToEnhancedListviewCondition('notEquals'));
        Assert.areEqual('< {value}', P2C_EnhancedListView.ListviewDescribeConditionToEnhancedListviewCondition('lessThan'));
        Assert.areEqual('> {value}', P2C_EnhancedListView.ListviewDescribeConditionToEnhancedListviewCondition('greaterThan'));
        Assert.areEqual('<= {value}', P2C_EnhancedListView.ListviewDescribeConditionToEnhancedListviewCondition('lessThanOrEqualTo'));
        Assert.areEqual('>= {value}', P2C_EnhancedListView.ListviewDescribeConditionToEnhancedListviewCondition('greaterThanOrEqualTo'));
        Assert.areEqual('(not {field} like {value})', P2C_EnhancedListView.ListviewDescribeConditionToEnhancedListviewCondition('notLike'));
        Assert.areEqual('like {value}', P2C_EnhancedListView.ListviewDescribeConditionToEnhancedListviewCondition('like'));
        Assert.areEqual('like {value}', P2C_EnhancedListView.ListviewDescribeConditionToEnhancedListviewCondition('includes'));
        Assert.areEqual('(not {field} like {value})', P2C_EnhancedListView.ListviewDescribeConditionToEnhancedListviewCondition('excludes'));
        Assert.areEqual('in ({value})', P2C_EnhancedListView.ListviewDescribeConditionToEnhancedListviewCondition('in'));
        Assert.areEqual('= ({value})', P2C_EnhancedListView.ListviewDescribeConditionToEnhancedListviewCondition('notIn'));
    }

    @isTest
    public static void testExecuteQueryCount() {
        String result = P2C_EnhancedListView.executeQueryCount('Opportunity', null, ' USING SCOPE everything ');

        Assert.isNotNull(result);
        Assert.areEqual(1, Integer.valueOf(result));
    }

    @isTest
    public static void testExecuteQuery() {
        String result = P2C_EnhancedListView.executeQuery('Opportunity', 'Id, Name', ' USING SCOPE everything ', null, null, 200, 0);

        Assert.isNotNull(result);
    }

    @isTest
    public static void testGetObjectFieldsNamesSorted() {
        String result = P2C_EnhancedListView.getObjectFieldsNamesSorted('Opportunity');

        Assert.isNotNull(result);
        Assert.isTrue(result.containsIgnoreCase('StageName'));
    }

    @isTest
    public static void testGetObjectInfoFromApiName() {
        String result = P2C_EnhancedListView.getObjectInfoFromApiName('Opportunity');

        Assert.isNotNull(result);
        P2C_OptionValueLabel option = (P2C_OptionValueLabel)JSON.deserialize(result, P2C_OptionValueLabel.class);
        Assert.isTrue(option.value == 'Opportunity');
    }

    @isTest
    public static void testGetListview() {
        P2C_EnhancedListviewConfig__c cfg = [SELECT Id, Name FROM P2C_EnhancedListviewConfig__c LIMIT 1];

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new P2C_MockHttpServiceData());
        String result = P2C_EnhancedListView.getListview('Opportunity', cfg.Id);
        
        Test.stopTest();

        Assert.isNotNull(result);
    }

    @isTest
    public static void testPinListview() {
        P2C_EnhancedListviewConfig__c cfg = [SELECT Id, Name FROM P2C_EnhancedListviewConfig__c LIMIT 1];
        ListView lv = [SELECT Id, Name, DeveloperName, NamespacePrefix, SobjectType FROM ListView WHERE SobjectType = 'Opportunity' LIMIT 1];

        Test.startTest();

        P2C_EnhancedListView.pinUnpinListview(lv.Id, cfg.Id);
        P2C_EnhancedListView.pinUnpinListview(cfg.Id, cfg.Id);

        Test.stopTest();

        List<P2C_EnhancedListviewUserPreferences__c> prefs = [SELECT Id, Name FROM P2C_EnhancedListviewUserPreferences__c];
        Assert.isNotNull(prefs);
        Assert.isTrue(!prefs.isEmpty());
    }
}