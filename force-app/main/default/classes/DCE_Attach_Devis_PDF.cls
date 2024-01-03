/*
* Creataed By : YSL 07/05/2020
* Permet de créer le devis en attachement (file) an format PDF
* Si un devis en PDF existe dans les files, on le supprime et on crée un nouveau 
* Sinon, on crée un nouveau devis en pdf
* Classe de test : DCE_Attach_Devis_PDF_Test  

* Modified by : EL KEISSA AIT SELLAMET
*/
public class DCE_Attach_Devis_PDF {
    
    ApexPages.StandardController controller;
    public Quote devis	                {get;set;}
    public Opportunity opportunite      {get;set;}
    public PageReference rtn;
    
    public DCE_Attach_Devis_PDF(ApexPages.StandardController c){
        
        devis = (Quote)c.getRecord();
                        
        rtn = c.view();
        //Permet de télécharger le document avec le numéro du devis dans le nom
        Apexpages.currentPage().getHeaders().put('content-disposition', 'inline; filename='+devis.QuoteNumber+'-'+devis.opportunity.Name+'.pdf');
    }
    
    public PageReference attachDevisPDF() {
        
        /* Get the page definition */        
        PageReference pdfPage = Page.DCE_Page_Visualiser_Devis_Suite;
        pdfPage.getParameters().put('id',devis.id);
        
        Blob pdfBlob;
        /* generate the pdf blob */
        if(! Test.isRunningTest()){
            pdfBlob = pdfPage.getContent();    
        }else{
            pdfBlob = Blob.ValueOf('Bla Bla Bla');
        }
        
        List<ContentDocument> listContentDocument = [SELECT id from ContentDocument 
                                                     WHERE Title LIKE :devis.QuoteNumber+'%.pdf'];
        //Si un devis en PDF existe, on le supprime
        if(listContentDocument.size() == 1){
            Delete listContentDocument[0];
        }
        
        /* create the attachment against the quote */
        ContentVersion cv 			= new ContentVersion();
        cv.ContentLocation 			= 'S';
        cv.VersionData    			= pdfBlob;

        /** Modified by : EL KEISSA AIT SELLAMET 
        *   Description : Mettre comme nom du devis Numéro de devis + Nom de l'opportunité
        */
        cv.Title 					= devis.QuoteNumber+'-'+devis.opportunity.Name+'.pdf';
        cv.PathOnClient 			= devis.QuoteNumber+'.pdf';
        //cv.FirstPublishLocationId 	= devis.id;
        insert cv;
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId 	= [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        cdl.LinkedEntityId 		= devis.id;
        cdl.ShareType 			= 'V';
        cdl.Visibility 			= 'AllUsers'; 
        insert cdl;
        
        
        
        /* send the user back to the offer detail page */
        return pdfPage;
    }
    
    
}