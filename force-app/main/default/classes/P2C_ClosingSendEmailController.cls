/**
 * @ description:
 * @ author: Gregory Quinet
 * @ group:
 * @ last modified on: 2023-12-05
 * @ last modified by: Gregory Quinet
 */

public with sharing class P2C_ClosingSendEmailController {

    @AuraEnabled
    public static string getTemplateFolders(){
        try {
            List<Folder> folders = P2C_EmailTemplateUtils.getTemplateFolders();
            return JSON.serialize(folders);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getEmailTemplates(String folderId){
        try {
            List<EmailTemplate> templates = P2C_EmailTemplateUtils.getFolderEmailTemplates(folderId);
            return JSON.serialize(templates);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getRecordInfo(String recordApiName, String recordId, String fieldNames){
        try {
            String query = 'SELECT ' + fieldNames + ' FROM ' + recordApiName + ' WHERE Id = :recordId';
            SObject record = Database.query(query);
            return JSON.serialize(record);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getRecordsInfo(String recordApiName, String recordIds, String fieldNames){
        try {
            List<String> recIds = (List<String>)JSON.deserialize(recordIds, List<String>.class);
            String query = 'SELECT ' + fieldNames + ' FROM ' + recordApiName + ' WHERE Id IN :recIds';
            List<SObject> records = Database.query(query);
            return JSON.serialize(records);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    // public static String getTemplatePreview(String templateId, String recordId) {
    public static String getTemplatePreview(String templateId, String recordIds) {
        System.debug('Start to generate preview for the record ids ' + recordIds + ' and template id ' + templateId);

        // Get the template, extract subject and body
        EmailTemplate template = P2C_EmailTemplateUtils.getEmailTemplateById(templateId);
        List<String> recIds = (List<String>)JSON.deserialize(recordIds, List<String>.class);
        String subjectSource = template.Subject;
        String bodySource = '';
        String emailHtml = template.HtmlValue;
        String emailBody = template.Body;
        String emailMarkup = template.Markup;
        if (emailHtml == null || emailHtml.length() < 1) {
            if (emailBody == null || emailBody.length() < 1) {
                if (emailMarkup != null) {
                    bodySource = emailMarkup;
                } else {
                    bodySource = '';
                }
            } else {
                bodySource = emailBody;
            }
        } else {
            bodySource = emailHtml;
        }

        // Find all mergefields in subject
        List<P2C_TemplateUtils.MergeFieldItem> mergeFields = P2C_TemplateUtils.parseMergeFieldsFor(subjectSource);
        // Find all mergefields in used body
        mergeFields.addAll(P2C_TemplateUtils.parseMergeFieldsFor(bodySource));

        // Find all List merge tags in body
        List<P2C_TemplateUtils.MergeListItem> mergeLists = P2C_TemplateUtils.parseMergeListFor(bodySource);

        // Simplify the mergefields results to fieldnames part by objects
        Map<String, List<String>> fieldsByObject = P2C_TemplateUtils.getFieldsByObjects(mergeFields);

        Map<String, Map<String, String>> fieldsLabelsByObject = new Map<String, Map<String, String>>();
        for (String obj: fieldsByObject.keySet()) {
            fieldsLabelsByObject.put(obj, P2C_SObjectUtils.getObjectFieldLabels(obj, fieldsByObject.get(obj)));
        }
        // Build final map of mergefields / values for replacement
        Map<String, Map<String, String>> stringifiedMergefieldsValues = new Map<String, Map<String, String>>();
        for (String objectApiName : fieldsByObject.keySet()) {
            switch on objectApiName {
                when 'User' {
                    String userId = UserInfo.getUserId();
                    if (!stringifiedMergefieldsValues.containsKey(userId)) {
                        stringifiedMergefieldsValues.put(userId, new Map<String, String>());
                    }
                    Map<String, Object> fieldsValues = P2C_SObjectUtils.getObjectsFieldsValues('User', new List<String>{userId}, fieldsByObject.get(objectApiName)).get(userId);
                    for (String fieldName : fieldsValues.keySet()) {
                        String fieldValueString = String.valueOf(fieldsValues.get(fieldName));
                        stringifiedMergefieldsValues.get(userId).put('{!User.' + fieldName + '}', fieldValueString);
                    }
                }
                when else {
                    Map<String, Map<String, Object>> fieldsValuesMap = P2C_SObjectUtils.getObjectsFieldsValues(objectApiName, recIds, fieldsByObject.get(objectApiName));
                    for (String recId : recIds) {
                        if (!stringifiedMergefieldsValues.containsKey(recId)) {
                            stringifiedMergefieldsValues.put(recId, new Map<String, String>());
                        }

                        Map<String, Object> fieldsValues = fieldsValuesMap.get(recId);
                        for (String fieldName : fieldsValues.keySet()) {
                            String fieldValueString = String.valueOf(fieldsValues.get(fieldName));
                            stringifiedMergefieldsValues.get(recId).put('{!' + objectApiName + '.' + fieldName + '}', fieldValueString);
                        }
                    }
                }
            }
        }

        // Replace merge fields occurences in subject and body
        String previewSubject = subjectSource;
        String previewBody = bodySource;
        if (mergeLists.size() > 0) {
            for (P2C_TemplateUtils.MergeListItem listItem : mergeLists) {
                String substituteTable = '<table border="1">';
                substituteTable += '<thead><tr>';
                for (String fieldKey : listItem.mergeKeys) {
                    String obj = fieldKey.substring(2, fieldKey.indexOf('.'));
                    String fld = fieldKey.substring(fieldKey.indexOf('.') + 1, fieldKey.lastIndexOf('}'));
                    if (fieldsLabelsByObject.containsKey(obj)) {
                        String label = fieldsLabelsByObject.get(obj).containsKey(fld) ? fieldsLabelsByObject.get(obj).get(fld) : fld;
                        substituteTable += '<th>' + label + '</th>';
                    } else {
                        substituteTable += '<th>' + fld + '</th>';
                    }
                }
                substituteTable += '</tr></thead><tbody>';
                for (String recId : recIds){
                    String row = '<tr>';
                    for (String fieldKey : listItem.mergeKeys) {
                        row += '<td>';
                        if (stringifiedMergefieldsValues.get(recId).get(fieldKey) != null) {
                            row += stringifiedMergefieldsValues.get(recId).get(fieldKey);
                        } else {
                            System.debug('stringified merge fields null for ' + fieldKey);
                            row += '-';
                            // row += fieldKey;
                        }
                        row += '</td>';
                    }
                    row += '</tr>';
                    substituteTable += row;
                }
                substituteTable += '</tbody></table>';
                previewBody = previewBody.replace(listItem.mergeKey, substituteTable);
            }
        }

        List<String> keys = new List<String>();
        keys.add(UserInfo.getUserId());
        keys.add(recIds.get(0));
        for (String Key : keys) {
            if (stringifiedMergefieldsValues.containsKey(key)) {
                Map<String, String> mFieldsValues = stringifiedMergefieldsValues.get(key);
                for (String mergeKey : mFieldsValues.keySet()) {
                    if (mFieldsValues.get(mergeKey) != null) {
                        previewSubject = previewSubject.replace(mergeKey, mFieldsValues.get(mergeKey));
                        previewBody = previewBody.replace(mergeKey, mFieldsValues.get(mergeKey));
                    } else {
                        previewSubject = previewSubject.replace(mergeKey, '-');
                        previewBody = previewBody.replace(mergeKey, '-');
                        System.debug('stringified merge fields null for ' + mergeKey);
                        System.debug(mFieldsValues.get(mergeKey));
                    }
                }
            }
        }

        PreviewTemplate preview = new PreviewTemplate();
        preview.subject = previewSubject;
        preview.body = previewBody;
        return JSON.serialize(preview);
    }

    public class PreviewTemplate {
        public String subject;
        public String body;
    }

    @AuraEnabled
    public static string getQuotesFilesForOppty(String recordIds){
        try {
            Map<String, FolderFileStructure> opptyDirs = new Map<String, FolderFileStructure>();
            List<String> recIds = (List<String>)JSON.deserialize(recordIds, List<String>.class);
            for (Opportunity opp : [SELECT Id, Name, CreatedDate FROM Opportunity WHERE Id IN :recIds]){
                if (!opptyDirs.containsKey(opp.Id)) {
                    FolderFileStructure opptyDir = new FolderFileStructure();
                    opptyDir.Id = opp.Id;
                    opptyDir.Name = opp.Name;
                    opptyDir.CreatedDate = opp.CreatedDate;
                    opptyDirs.put(opp.Id, opptyDir);
                }
            }

            for (Quote quote : [SELECT Id, QuoteNumber, Name, CreatedDate, OpportunityId FROM Quote WHERE OpportunityId IN :recIds ORDER BY OpportunityId, CreatedDate DESC]) {
                if (opptyDirs.get(quote.OpportunityId).Children == null) {
                    opptyDirs.get(quote.OpportunityId).Children = new List<FolderFileStructure>();
                }
                FolderFileStructure quoteDir = new FolderFileStructure();
                quoteDir.Id = quote.Id;
                quoteDir.Name = quote.Name;
                quoteDir.FileNumber = quote.QuoteNumber;
                quoteDir.CreatedDate = quote.CreatedDate;

                List<FolderFileStructure> quoteFiles = getFilesFor(quote.Id);
                if (!quoteFiles.isEmpty()) {
                    quoteDir.Children = new List<FolderFileStructure>();
                    quoteDir.Children.addAll(quoteFiles);
                }
                opptyDirs.get(quote.OpportunityId).Children.add(quoteDir);
            }
            return JSON.serialize(opptyDirs.values());
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class FolderFileStructure {
        public String Id;
        public String Name;
        public String FileNumber;
        public DateTime CreatedDate;
        public boolean IsFile;
        public List<FolderFileStructure> Children;
    }

    public static List<FolderFileStructure> getFilesFor(String recordId){
        try {
            List<FolderFileStructure> results = new List<FolderFileStructure>();
            List<Id> documentIds = new List<Id>();
            for (ContentDocumentLink cdl : [SELECT Id, ContentDocumentId  FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]) {
                documentIds.add(cdl.ContentDocumentId);
            }
            for (ContentVersion cv : [SELECT Id, Title, PathOnClient, FileType, FileExtension, CreatedDate FROM ContentVersion WHERE ContentDocumentId IN :documentIds ORDER BY CreatedDate DESC]) {
                FolderFileStructure file = new FolderFileStructure();
                file.Id = cv.Id;
                file.Name = cv.Title;
                file.CreatedDate = cv.CreatedDate;
                file.IsFile = true;

                results.add(file);
            }

            return results;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String generateQuoteFile(String quoteId){
        try {
            Quote q = [SELECT Id, Name, QuoteNumber, Opportunity.Name FROM Quote WHERE Id = :quoteId];
            Blob fileContent;
            if (Test.isRunningTest()) {
                fileContent = Blob.valueOf('testContent');
            } else {
                PageReference pageRef = Page.DCE_Page_Visualiser_Devis_Suite;
                pageRef.getParameters().put('Id', quoteId);
                fileContent = pageRef.getContentAsPdf();
            }

            // create the attachment against the quote
            ContentVersion cv 			= new ContentVersion();
            cv.ContentLocation 			= 'S';
            cv.VersionData    			= fileContent;

            /** Modified by : EL KEISSA AIT SELLAMET 
            *   Description : Mettre comme nom du devis Numéro de devis + Nom de l'opportunité
            */
            cv.Title 					= q.QuoteNumber+'-'+q.opportunity.Name+'.pdf';
            cv.PathOnClient 			= q.QuoteNumber+'.pdf';
            //cv.FirstPublishLocationId 	= devis.id;
            insert cv;
            
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId 	= [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
            cdl.LinkedEntityId 		= q.id;
            cdl.ShareType 			= 'V';
            cdl.Visibility 			= 'AllUsers'; 
            insert cdl;

            return cv.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string sendEmails(String jsonEmailData){
        try {
            System.debug('process email send with input: ' + jsonEmailData);

            List<String> successOppIds = new List<String>();
            List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
            Map<Integer, List<String>> sentRecIds = new Map<Integer, List<String>>();
            List<EmailData> data = (List<EmailData>)JSON.deserialize(jsonEmailData, List<EmailData>.class);
            Integer indexMsg = 0;
            for (EmailData emailData : data) {
                //skip untagged emails
                if (emailData.send == null || !emailData.send) continue;
                
                if (!sentRecIds.containsKey(indexMsg)) sentRecIds.put(indexMsg, new List<String>());
                sentRecIds.get(indexMsg).addAll(emailData.recordIds);
                indexMsg++;

                List<String> tos = new List<String>();
                List<String> ccs = new List<String>();
                List<String> bccs = new List<String>();
                if (emailData.toEmails != null && emailData.toEmails.length() > 0) {
                    if (emailData.toEmails.contains(',')) {
                        for (String mail : emailData.toEmails.split(',')) {
                            tos.add(mail.trim());
                        }
                    }else {
                        tos.add(emailData.toEmails.trim());
                    }
                }
                if (emailData.ccEmails != null && emailData.ccEmails.length() > 0) {
                    if (emailData.ccEmails.contains(',')) {
                        for (String mail : emailData.ccEmails.split(',')) {
                            ccs.add(mail.trim());
                        }
                    }else {
                        ccs.add(emailData.ccEmails.trim());
                    }
                }
                if (emailData.bccEmails != null && emailData.bccEmails.length() > 0) {
                    if (emailData.bccEmails.contains(',')) {
                        for (String mail : emailData.bccEmails.split(',')) {
                            bccs.add(mail.trim());
                        }
                    }else {
                        bccs.add(emailData.bccEmails.trim());
                    }
                }

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(tos);
                if (!ccs.isEmpty()) mail.setBccAddresses(ccs);
                if (!bccs.isEmpty()) mail.setCcAddresses(bccs);
                mail.setSubject(emailData.subject);
                mail.setHtmlBody(emailData.body);
                if (emailData.attachmentId != null && emailData.attachmentId.length() > 0) {
                    mail.setEntityAttachments(new List<Id>{emailData.attachmentId});
                }
                // messages.put(emailData.recordId, mail);
                messages.add(mail);
            }

            //send emails and collect success
            if (!messages.isEmpty()) {
                List<ClosingEmailLog__c> emailLogs = new List<ClosingEmailLog__c>();

                System.debug('will send emails for recIds: ' + sentRecIds.values());
                List<Messaging.SendEmailResult> results = Messaging.sendEmail(messages, false);
                for (Integer resultIndex = 0; resultIndex < results.size(); resultIndex++) {
                    ClosingEmailLog__c mailLog = new ClosingEmailLog__c();
                    mailLog.EmailFrom__c = UserInfo.getUserEmail();
                    mailLog.EmailTo__c = String.join(messages.get(resultIndex).toaddresses, ',');
                    mailLog.EmailData__c = JSON.serialize(data.get(resultIndex));

                    System.debug('Email idx: ' + resultIndex + ' status: ' + results.get(resultIndex).isSuccess());
                    if (results.get(resultIndex).isSuccess()) {
                        successOppIds.addAll(sentRecIds.get(resultIndex));
                        mailLog.SendResult__c = 'Successfully sent from apex';
                    } else {
                        String error = '';
                        for (Messaging.SendEmailError err : results.get(resultIndex).getErrors()) {
                            error += err.getMessage() + '\n';
                        }
                        mailLog.SendResult__c = error;
                    }
                    emailLogs.add(mailLog);
                }

                if (!emailLogs.isEmpty()) {
                    ClosingEmailLogSettings__c setting = ClosingEmailLogSettings__c.getInstance(UserInfo.getProfileId());
                    if (setting != null && setting.LogClosingEmailSending__c) insert emailLogs;
                }
            }

            return JSON.serialize(successOppIds);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class EmailData {
        public Boolean send;
        public String recordId;
        public List<String> recordIds;
        public String body;
        public String subject;
        public String fromEmail;
        public String toEmails;
        public String ccEmails;
        public String bccEmails;
        public String attachmentId;
        public String attachmentName;
    }
}