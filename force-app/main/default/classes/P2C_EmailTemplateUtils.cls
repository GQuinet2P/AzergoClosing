public with sharing class P2C_EmailTemplateUtils {

    public static List<Folder> getTemplateFolders(){
        List<Folder> folders = [SELECT Id, Name, DeveloperName, AccessType, Type from Folder where Type = 'Email'];
        return folders;
    }

    public static List<EmailTemplate> getFolderEmailTemplates(String folderId){
        List<EmailTemplate> templates = [SELECT Id, Name, DeveloperName, FolderId, IsActive, TemplateType, Description, Subject, HtmlValue, Body, Markup from EmailTemplate WHERE FolderId = :folderId];
        return templates;
    }

    public static EmailTemplate getEmailTemplateById(String templateId){
        EmailTemplate[] template = [SELECT Id, Subject, HtmlValue, Body, Markup from EmailTemplate WHERE Id = :templateId];
        return template.size() > 0 ? template[0] : null;
    }


}