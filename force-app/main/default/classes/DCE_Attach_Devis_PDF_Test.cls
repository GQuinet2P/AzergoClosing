/*
* Created by : YSL 10/05/2020
* Permet de tester la classe : DCE_Attach_Devis_PDF
*/
@isTest
public class DCE_Attach_Devis_PDF_Test {
    
    /*
	* Permet de tester la génération d'un devis sans lignes en pièces jointes (file)
	*/
    static testMethod void attachDevisPDF_Without_QuoteLineItem_Test(){
        
        //Créer un compte
        account acc4 = new account(name = 'testacc445');
        
        contact ctc = new contact(Lastname='Testontact3',Email = 'test@gmail.com', phone='06599973454');
        insert ctc;
        
        //Créer une opportunité sans lignes 
        opportunity opp4 = ALS_CL_TEST_HELPER.createOpportunity(acc4.id);
        opp4.Interlocuteur_Devis_Commande_Facture__c = ctc.id;  
        opp4.Methode_de_livraison__c = 'Contacter le responsable de secteur';
        update opp4;
        
        //Créer le devis
        Quote qt = new Quote (OpportunityID = opp4.id, name ='devis4');
        insert qt;  
        
        //Vérifier s'il y a aucun fichier associé à ce devis
        List<ContentDocumentLink> listContentDocumentLink = [Select id,LinkedEntityId from ContentDocumentLink where LinkedEntityId =: qt.Id];
        System.assertEquals(0, listContentDocumentLink.size());     
        
        //Générer le devis en pièce jointe (file) en format PDF
        Test.startTest();        
            PageReference pageRef = Page.DCE_Page_Visualiser_Devis;
            pageRef.getParameters().put('Id', String.valueOf(qt.Id));  
            Test.setCurrentPage(pageRef);
            
            ApexPages.StandardController sc = new ApexPages.StandardController(qt);
            DCE_Attach_Devis_PDF monController = new DCE_Attach_Devis_PDF(sc);
            
            System.assertEquals(qt.id, monController.devis.Id);
            monController.attachDevisPDF();
        Test.stopTest();
        
        //Vérifier s'il y a bien un fichier associé au devis 
        listContentDocumentLink = [Select id,LinkedEntityId, ContentDocument.Title from ContentDocumentLink where LinkedEntityId =: qt.Id];
        System.assertEquals(1, 		listContentDocumentLink.size());
        System.assertEquals(qt.Id, 	listContentDocumentLink[0].LinkedEntityId);

        //MASSO : 19/05/2022 Vérifier que le nom du fichier PDF est Numéro de devis + Nom de l'opportunité 
        for(ContentDocumentLink cdl : listContentDocumentLink){
            System.assertEquals(cdl.ContentDocument.Title, qt.QuoteNumber+'-'+qt.opportunity.Name+'.pdf');
        }
    }    
    
    /*
     * Permet de tester la génération d'un devis avec des lignes en pièces jointes (file)
     */
    static testMethod void attachDevisPDF_With_QuoteLineItem_Test(){
        Account accTest = ALS_CL_TEST_HELPER.createAccount();
        
        //get standard pricebook
        Pricebook2 standardPb = new PriceBook2(Id = Test.getStandardPricebookId());
        
        //Créer deux gammes
        ALS_Gamme__c gammeTest = new ALS_Gamme__c(Name = 'Produits test');        
        ALS_Gamme__c optionsGammeTest = new ALS_Gamme__c(Name = 'Options Produits test');
        
        List<ALS_Gamme__c> listGamme = new List<ALS_Gamme__c>{gammeTest, optionsGammeTest};
        insert listGamme;
        
        Ecotaxe__c ecotaxe1 = new Ecotaxe__c(Name = 'ETT', Prix_unitaire_ecotaxe__c = 0.070);
        Ecotaxe__c ecotaxe2 = new Ecotaxe__c(Name = 'ETR', Prix_unitaire_ecotaxe__c = 0.080);
        List<Ecotaxe__c> listEcotaxes = new List<Ecotaxe__c>{ecotaxe1, ecotaxe2};
        insert listEcotaxes;
        
        //Créer deux produits
        Product2 prodTest1 = new Product2(
            Name        = 'Fauteuil super confort',
            Description = 'Fauteuil super confort',
            Type__c     = 'Base',
            Gamme__c    = gammeTest.Id,
            ProductCode = 'P1',
            isActive    = true,
            Poids__c    = 5,
            TVA__c      = 20,
            Ecotaxe__c  = ecotaxe1.id);
        
        Product2 prodOptionTest = new Product2(
            Name        = 'VERIN 1C',
            Description = 'VERIN 1C',
            Type__c     = 'Option',
            Gamme__c    = optionsGammeTest.Id,
            ProductCode = 'P3',
            isActive    = true,
            TVA__c = 5,
            Poids__c = 10,
            Ecotaxe__c = ecotaxe2.id);
        
        List<Product2> listProduit = new List<Product2>{prodTest1, prodOptionTest};
        insert listProduit;
        
        //Créer deux catalogues
        PricebookEntry pbeTest1 = new PricebookEntry(
            Product2Id   = prodTest1.id,
            Pricebook2Id = standardPb.id,
            UnitPrice    = 500,
            isActive     = true
        );
        
        PricebookEntry pbeTest2 = new PricebookEntry(
            Product2Id   = prodOptionTest.id,
            Pricebook2Id = standardPb.id,
            UnitPrice    = 200,
            isActive     = true
        );
        
        List<PricebookEntry> listPricebookEntry = new List<PricebookEntry>{pbeTest1, pbeTest2};
        insert listPricebookEntry;
        
        contact ctc = new contact(Lastname='Testontact1',Email = 'test@gmail.com', phone='06599973454');
        insert ctc;
        
        //Créer une opportunité
        Opportunity oppTest1 = new Opportunity(
            Name         = 'Test opportunité',
            AccountId    = accTest.Id,
            StageName    = 'A traiter',
            CloseDate    = Date.Today() + 5,
            Pricebook2Id = standardPb.Id, 
            Adresse_de_livraison_Code_postal__c = '69001',
            Interlocuteur_Devis_Commande_Facture__c = ctc.id,
             Methode_de_livraison__c = 'Contacter le responsable de secteur'
        );
        
        insert oppTest1;
        
        //Créer une configuration
        Configuration__c config = new Configuration__c (Name = 'T4000 GAJA NOIR');
        insert config;
        
        //Créer des configurations d'articles
        Configuration_article__c configurationArticleBase   = new Configuration_article__c(Configuration__c = config.id, Produit__c = prodTest1.id ,     Quantite__c = 1, Ordre__c = 0);
        Configuration_article__c configurationArticleOption = new Configuration_article__c(Configuration__c = config.id, Produit__c = prodOptionTest.id ,Quantite__c = 5, Ordre__c = 1);
        List<Configuration_article__c> listConfigurationArticle = new List<Configuration_article__c>{configurationArticleBase, configurationArticleOption};
        insert listConfigurationArticle;
        
        //Créer deux lignes d'opportunité pour l'opportunité oppTest1
        OpportunityLineItem oppLineTest1 = new OpportunityLineItem(
            OpportunityId    = oppTest1.Id,
            PriceBookEntryId = pbeTest1.Id,
            Quantity         = 2,
            Product2Id       = prodTest1.id,
            UnitPrice        = pbeTest1.UnitPrice,
            N_ligne_Niveau_1__c = 100,
            N_ligne_Niveau_2__c = 0,
            TECH_Configuration__c = config.id
        );   
        
        OpportunityLineItem oppLineTest2 = new OpportunityLineItem(
            OpportunityId    = oppTest1.Id,
            PriceBookEntryId = pbeTest2.Id,
            Quantity         = 10,
            Product2Id       = prodOptionTest.id,
            UnitPrice        = pbeTest2.UnitPrice,
            N_ligne_Niveau_1__c = 200,
            N_ligne_Niveau_2__c = 0,
            TECH_Configuration__c = config.id
        );
        List<OpportunityLineItem> listOpportunityLineItem = new List<OpportunityLineItem>{oppLineTest1, oppLineTest2};
        insert listOpportunityLineItem;
        
        //Créer le devis
        Quote qt = new Quote (OpportunityID = oppTest1.id, name ='devis4');
        insert qt;  
        
        //Vérifier s'il y a aucun fichier associé à ce devis
        List<ContentDocumentLink> listContentDocumentLink = [Select id,LinkedEntityId from ContentDocumentLink where LinkedEntityId =: qt.Id];
        System.assertEquals(0, listContentDocumentLink.size());     
        
        //Générer le devis en pièce jointe (file) en format PDF
        Test.startTest();        
            PageReference pageRef = Page.DCE_Page_Visualiser_Devis;
            pageRef.getParameters().put('Id', String.valueOf(qt.Id));  
            Test.setCurrentPage(pageRef);
            
            ApexPages.StandardController sc = new ApexPages.StandardController(qt);
            DCE_Attach_Devis_PDF monController = new DCE_Attach_Devis_PDF(sc);
            
            System.assertEquals(qt.id, monController.devis.Id);
            monController.attachDevisPDF();
        Test.stopTest();
        
        //Vérifier s'il y a bien un fichier associé au devis 
        listContentDocumentLink = [Select id,LinkedEntityId from ContentDocumentLink where LinkedEntityId =: qt.Id];
        System.assertEquals(1, 		listContentDocumentLink.size());
        System.assertEquals(qt.Id, 	listContentDocumentLink[0].LinkedEntityId);
    }
}