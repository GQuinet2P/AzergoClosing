/**
 * @File Name          : ALS_CL_01_CYCLE_ESSAI.cls
 * @description        : 
 * @author             : ??
 * @ Modified By       : Bertrand Leymarios
 * @Modified On        : 20/3/2020 23:26:18
 * @modified : Saamiyah - 15 march 2023 - TMA0003 - Sync SF / Outlook events
 * Modified by         : Marianne ASSOGBAVI 03/05/2022
 * Test class          : ALS_CL_01_CYCLE_ESSAI_TEST 
**/
public class ALS_CL_01_CYCLE_ESSAI{
    // Code Legacy 06/04/2020
    public static boolean  runOnceFlagCreation= false;
   	public static Boolean bypassTrigger = false; // Saamiyah K - mia- Added if statement - SOQL limit issue 19 April 2023
    /**
     * @param newList : liste des ALS_Cycle_Essai__c à insérer
     * @description Création d'un EVT pour la mise en Essai, et d'un RDV pour le retour d'Essai
     */
    public static void creationEvenement(List<ALS_Cycle_Essai__c> newList) {
        if(bypassTrigger == false){
             List<Event> evtsACreer = new List<Event>();
            // Miaa - SK - TMA0003 - Sync salesforce Events with Outlook
            Set<Id> oppId = new Set<Id>(); // MIAAA
            String opportunityId;
            String cycleId;
            Boolean createEvent= false; // miaa- SK|10.03.2023|TMA0046|Do not create event if checkbox(Ne_pas_cree_RDV__c) is checked.
            //TMA0085 - Saamiyah K. 6 Sep 2023 - Do not display contacts if all is null
            String autreIntervenantTxt = '';
            String infirmierTxt = '';
            String utilisateurTxt = '';
            String ergonomeTxt = '';
            String referentHandicapTxt = '';
            String interlocuteurDevisTxt = '';
            String referentInterneTxt = '';
            String medecinTxt = '';
        
            Opportunity opp = new Opportunity();
            for (ALS_Cycle_Essai__c cycle : newList){
                oppId.add(cycle.opportunite__c);
                opportunityId = cycle.opportunite__c;
                createEvent = cycle.Ne_pas_cree_RDV__c;
            }
            if(createEvent == false){
                //create event if not checked
                String fullUrlToOpp = URL.getSalesforceBaseUrl().toExternalForm() +  '/' + opportunityId;
                String fullUrlToCycleEssai = URL.getSalesforceBaseUrl().toExternalForm() +  '/' + cycleId;
                //29/07/2023 TMA_0075 LB - Modified query to return options only
                List<OpportunityLineItem> oppLineItem = [SELECT Id, Product2.Name, Quantity, Statut__c, ProductCode, N_ligne_Niveau_1__c,
                                                         Type__c, Article_hors_config_STD__c, Infos_Interne__c
                                                        FROM OpportunityLineItem
                                                        WHERE OpportunityId IN: oppId
                                                        AND (Type__c = 'Base' OR (Type__c = 'Option' AND Article_hors_config_STD__c = true))];
                System.debug(LoggingLevel.DEBUG, 'OpplineItems check ### : ' + oppLineItem);                                         
                String productAddtoEvent;
                Integer i = 1;
                Decimal previousNiveau = 0;
                for(OpportunityLineItem oppline : oppLineItem){
                    // first time
                    if(i != 1) {
                        if(oppline.N_ligne_Niveau_1__c != previousNiveau){
                            productAddtoEvent +='\n\n';
                        }
                        else{
                            productAddtoEvent += '\n';
                        }
                    }
                    //29/07/2023 TMA_0075 LB
                    productAddtoEvent += oppline.Quantity + ' | ' + oppline.Statut__c + ' | ' + oppline.ProductCode +'- '+ oppline.Product2.Name + ' | ' + oppline.Infos_Interne__c;   
                    //productAddtoEvent += oppline.Quantity + ' | ' + oppline.Statut__c + ' | ' + oppline.ProductCode +'- '+ oppline.Product2.Name;      
                    productAddtoEvent = productAddtoEvent.remove('null');
                    previousNiveau = oppline.N_ligne_Niveau_1__c;
                    i = i +1;
                }
                //On récupère les infos de l'opportunité associée
                if(!oppId.isEmpty()){
                    opp = [Select ID,Name, OwnerId,Adresse_de_livraison_Rue__c,Adresse_de_livraison_Code_postal__c,Adresse_de_livraison_Ville__c,
                                        Nom_du_compte__c, // miaaa
                                        Medecin_du_travail__c,Medecin_du_travail__r.MobilePhone,Medecin_du_travail__r.Name,
                                        Infirmiere__c, Infirmiere__r.MobilePhone,Infirmiere__r.Name,
                                        Ergonome__c, Ergonome__r.MobilePhone,Ergonome__r.Name,
                                        SAMETH_Referent_handicap__c, SAMETH_Referent_handicap__r.Email,SAMETH_Referent_handicap__r.MobilePhone, SAMETH_Referent_handicap__r.Name, 
                                        Interlocuteur_Devis_Commande_Facture__c, Interlocuteur_Devis_Commande_Facture__r.MobilePhone, Interlocuteur_Devis_Commande_Facture__r.Name,
                                        Referent_interne__c, Referent_interne__r.MobilePhone, Referent_interne__r.Name,
                                        Autre_intervenant__c,Autre_intervenant__r.Email, Autre_intervenant__r.MobilePhone, Autre_intervenant__r.Name,
                                        Utilisateur__c
                                        From Opportunity
                                        Where ID IN: oppId];
                    //Pour éviter de trouver des valeurs 'null' dans l'emplacement
                    If (opp.Adresse_de_livraison_Rue__c == null){
                        opp.Adresse_de_livraison_Rue__c = '';
                    }
                    If (opp.Adresse_de_livraison_Code_postal__c == null){
                        opp.Adresse_de_livraison_Code_postal__c = '';
                    } 
                    If (opp.Adresse_de_livraison_Ville__c == null){
                        opp.Adresse_de_livraison_Ville__c = '';
                    }
                    // Saamiyah - 4 Sep 2023 - TMA0085
                    if(opp.Autre_intervenant__r.Name != null || opp.Autre_intervenant__r.Email != null || opp.Autre_intervenant__r.MobilePhone != null ){
                        autreIntervenantTxt = 'Autre intervenant : ' + opp.Autre_intervenant__r.Name + ' / ' + opp.Autre_intervenant__r.Email + ' / ' + opp.Autre_intervenant__r.MobilePhone + '\n';
                    }
                }
                
                for (ALS_Cycle_Essai__c cycle : newList){
                    //1.Mise en Essai
                    IF  (cycle.Date_Mise_en_essai__c != null){
                        // Saamiyah - 4 Sep 2023 - TMA0085 - do not display contacts if all is Null
                        if(cycle.nom_complet_utilisateur__c != null || cycle.Email_utilisateur__c != null || cycle.FORM_Telephone_de_l_utilisateur__c != null || cycle.FORM_Telephone_mobile_utilisateur__c != null){
                            utilisateurTxt = 'Contact utilisateur : ' + cycle.nom_complet_utilisateur__c + ' / ' + cycle.Email_utilisateur__c + ' / ' + cycle.FORM_Telephone_de_l_utilisateur__c + ' / ' + cycle.FORM_Telephone_mobile_utilisateur__c  + '\n';
                        }
                        if(opp.Medecin_du_travail__r.Name != null || cycle.Email_Medecin_de_travail__c != null || opp.Medecin_du_travail__r.MobilePhone != null){
                            medecinTxt = 'Medecin du travail : ' +  opp.Medecin_du_travail__r.Name + ' / ' + cycle.Email_Medecin_de_travail__c + ' / ' + opp.Medecin_du_travail__r.MobilePhone + '\n';
                        }
                        if(opp.Infirmiere__r.Name != null || cycle.Email_infirimiere__c != null || opp.Infirmiere__r.MobilePhone != null){
                            infirmierTxt = 'Infirmière : ' + opp.Infirmiere__r.Name + ' / ' + cycle.Email_infirimiere__c + ' / ' + opp.Infirmiere__r.MobilePhone + '\n';
                        }
                        if(opp.Ergonome__r.Name != null || cycle.Email_Ergonome__c != null || opp.Ergonome__r.MobilePhone != null){
                            ergonomeTxt = 'Ergonome : ' + opp.Ergonome__r.Name + ' / ' + cycle.Email_Ergonome__c + ' / ' +opp.Ergonome__r.MobilePhone + '\n';
                        }
                        if(opp.SAMETH_Referent_handicap__r.Name != null || cycle.Email_Referent_handicap__c != null || opp.SAMETH_Referent_handicap__r.MobilePhone != null){
                            referentHandicapTxt = 'SAMETH Référent handicap : ' + opp.SAMETH_Referent_handicap__r.Name + ' / ' + cycle.Email_Referent_handicap__c + ' / ' + opp.SAMETH_Referent_handicap__r.MobilePhone + '\n';
                        }
                        if(opp.Interlocuteur_Devis_Commande_Facture__r.Name != null || cycle.Email_interlocuteur_Facture__c != null ||  opp.Interlocuteur_Devis_Commande_Facture__r.MobilePhone != null){
                            interlocuteurDevisTxt = 'Interlocuteur Devis Commande Facture : ' + opp.Interlocuteur_Devis_Commande_Facture__r.Name + ' / ' + cycle.Email_interlocuteur_Facture__c + ' / ' +  opp.Interlocuteur_Devis_Commande_Facture__r.MobilePhone + '\n';
                        }
                        if(opp.Referent_interne__r.Name != null || cycle.Email_Referent_interne__c != null || opp.Referent_interne__r.MobilePhone != null){
                            referentInterneTxt = 'Referent interne : ' + opp.Referent_interne__r.Name + ' / ' + cycle.Email_Referent_interne__c + ' / ' + opp.Referent_interne__r.MobilePhone + '\n\n\n' ;
                        }
                        // END mia

                        //1.1 Si la durée de l'évenement est connue :
                        If( (cycle.isRDV_de_Mise_en_Essai_cree__c == false) && (cycle.Duree_RDV_Mise_en_essai_min__c != null)){
                            Event e = new Event(
                                StartDateTime = cycle.Date_Mise_en_essai__c,
                                EndDateTime = cycle.Date_Mise_en_essai__c.addMinutes(cycle.Duree_RDV_Mise_en_essai_min__c.intValue()),
                                OwnerId = opp.OwnerId,
                                Subject = opp.Name + '- Mise en essai',
                                WhatId = cycle.id,
                                Location = opp.Adresse_de_livraison_Rue__c
                                +' '+ opp.Adresse_de_livraison_Code_postal__c
                                +' '+ opp.Adresse_de_livraison_Ville__c,
        
                                Description = 'Lien du cycle d\'essai: ' + fullUrlToOpp + '\n' +
                                                '----------------------------------------------------------------------------------------' + '\n'+
                                                'ATTENTION, TOUTES LES MODIFICATIONS DOIVENT SE FAIRE PAR LE CYCLE D\'ESSAI.' + '\n' + 
                                                '----------------------------------------------------------------------------------------' + '\n'+
                                                'Lien de l\'opportunité : ' + fullUrlToCycleEssai + '\n' +
                                                'Nom du compte : ' + cycle.Nom_du_compte__c + '\n' +
                                                'Info Outlook : ' + cycle.Info_Outlook__c + '\n\n' +
                                                utilisateurTxt + medecinTxt + infirmierTxt + ergonomeTxt +referentHandicapTxt +
                                                interlocuteurDevisTxt + autreIntervenantTxt + referentInterneTxt +
                                                'Produits de l\'opportunité: ' + '\n' + 
                                                '----------------------------------------------------' + '\n'+
                                                'Quantité | Statut | Nom du produit | Infos internes' + '\n' +
                                                '----------------------------------------------------' + '\n'+
                                                productAddtoEvent
        
                            );
                            // MIIAAA END
                            evtsACreer.add(e);
                            cycle.isRDV_de_Mise_en_Essai_cree__c = true;
                        }
                        //1.2 Si la durée de l'évenement est inconnue
                        If( (cycle.isRDV_de_Mise_en_Essai_cree__c == false) && (cycle.Duree_RDV_Mise_en_essai_min__c == null)){
                            Event e = new Event(
                                                StartDateTime = cycle.Date_Mise_en_essai__c,
                                                IsAllDayEvent = True,                  
                                                OwnerId = opp.OwnerId,
                                                Subject = opp.Name + '- Mise en essai',
                                                WhatId = cycle.id,
                                                Location = opp.Adresse_de_livraison_Rue__c
                                                +' '+ opp.Adresse_de_livraison_Code_postal__c
                                                +' '+ opp.Adresse_de_livraison_Ville__c,
                                                Description = 'Lien du cycle d\'essai: ' + fullUrlToOpp + '\n' +
                                                                '----------------------------------------------------------------------------------------' + '\n'+
                                                                'ATTENTION, TOUTES LES MODIFICATIONS DOIVENT SE FAIRE PAR LE CYCLE D\'ESSAI.' + '\n' + 
                                                                '----------------------------------------------------------------------------------------' + '\n'+
                                                                'Nom du compte : ' + cycle.Nom_du_compte__c + '\n' +
                                                                'Info Outlook : ' + cycle.Info_Outlook__c + '\n\n' +
                                                                utilisateurTxt + medecinTxt + infirmierTxt + ergonomeTxt +referentHandicapTxt +
                                                                interlocuteurDevisTxt + autreIntervenantTxt + referentInterneTxt +
                                                                'Produits de l\'opportunité: ' + '\n' + 
                                                                '----------------------------------------------------' + '\n'+
                                                                'Quantité | Statut | Nom du produit | Infos internes' + '\n' +
                                                                '----------------------------------------------------' + '\n'+
                                                                productAddtoEvent                        );
                            evtsACreer.add(e);
                            cycle.isRDV_de_Mise_en_Essai_cree__c = true;
                        }
                    }
                }
                System.debug(LoggingLevel.DEBUG,'#### mia event to create: ' + evtsACreer);
                database.insert(evtsACreer);
            }
        }
    }
    /**
     * @description stopCycleEssaiCreation
     * @param listCyclesDEssai
     */
    public static void stopCycleEssaiCreation(List<ALS_Cycle_Essai__c> listCyclesDEssai){
        map<id,boolean> mapOpportunities = new  map<id,boolean>();
        System.debug(LoggingLevel.DEBUG, 'stopCycleEssaiCreation $$$$$$ ');
        for(ALS_Cycle_Essai__c ce : listCyclesDEssai){
            mapOpportunities.put(ce.Opportunite__c, false);
        }
        List<ALS_Cycle_Essai__c> listCyclesEssaiOuverts = [SELECT id,Statut_global__c,Opportunite__c
                                                           FROM ALS_Cycle_Essai__c
                                                           WHERE Statut_global__c = 'Ouvert'
                                                           AND Opportunite__c IN :mapOpportunities.keySet()];
        if(listCyclesEssaiOuverts.size() > 0){
            for(ALS_Cycle_Essai__c ce : listCyclesEssaiOuverts){
                if(mapOpportunities.get(ce.Opportunite__c) != true){
                    mapOpportunities.put(ce.Opportunite__c, true);
                }
            }
            for(ALS_Cycle_Essai__c ce : listCyclesDEssai){
                if(mapOpportunities.get(ce.Opportunite__c) == true){
                    ce.addError('Vous ne pouvez pas créer de nouveau cycle d\'essai tant que vous avez un cycle d\'essai ouvert');
                }
            }
        }
    }
    /**
     * @description create Checklist
     * @param listCyclesDEssai
     */
    public static void createChecklist(List<ALS_Cycle_Essai__c> listCyclesDEssai){
        //Liste des lignes d'opportunités
        List<OpportunityLineItem> oppProductsAll = new List<OpportunityLineItem>();
        List<OpportunityLineItem> oppProductsNotOnPlace = new List <OpportunityLineItem>();
        map<id, map<string,list<OpportunityLineItem>>> mapOppProducts = new map<id, map<string,list<OpportunityLineItem>>>();        
        map<ID,ID> mapidProductsALL = new map<ID,ID>();
        map<ID,ID> mapidProductsNotInPlace = new map<ID,ID>();
        map<ID,ALS_Cycle_Essai__c> mapCycleEssai = new map<ID,ALS_Cycle_Essai__c>();
        map<id,list<Product2>> mapCycleEssaiProductAll = new  map<id,list<Product2>>();
        map<id,list<Product2>> mapCycleEssaiProductNotOnPlace = new  map<id,list<Product2>>();             
        Map<ID,ID> mapChecklistsGammes = mapChecklistsGammes ();
        List<ALS_Checklist__c> checklistsAcreer = new List<ALS_Checklist__c>();

        Integer nbreOppLinesProduitDeBaseAll = 0;
        Integer nbreOppLinesProduitDeBaseNotInPlace = 0;
        Integer nbreTotalOppLinesProduitsDeBaseOuOptionCommeBase = 0;
        
        for(ALS_Cycle_Essai__c ce : listCyclesDEssai)
        {
            map<string,list<OpportunityLineItem>> mapOpportunityLineItem = new  map<string,list<OpportunityLineItem>>();
            mapOpportunityLineItem.put('ALL', new List<OpportunityLineItem>());
            mapOpportunityLineItem.put('NotInPlace', new List<OpportunityLineItem>());
            mapOppProducts.put(ce.Opportunite__c, mapOpportunityLineItem);   
            mapCycleEssai.put(ce.Opportunite__c, ce);
            mapCycleEssaiProductAll.put(ce.id, new list<Product2>());
            mapCycleEssaiProductNotOnPlace.put(ce.id, new list<Product2>());
        }
        oppProductsAll = [SELECT id, PricebookEntry.Product2Id, OpportunityId,Quantity, statut__c, Description, PricebookEntry.Product2.Type__c, PricebookEntry.Product2.Option_comme_produit_de_base__c
                          FROM OpportunityLineItem 
                          WHERE OpportunityId IN: mapOppProducts.keySet()
                          AND  isMateriel_sur_place__c = true];

        System.debug(LoggingLevel.DEBUG, 'oppProductsAll ' + oppProductsAll);
        
        oppProductsNotOnPlace = [Select id, PricebookEntry.Product2Id, OpportunityId,Quantity, statut__c, Description, PricebookEntry.Product2.Type__c, PricebookEntry.Product2.Option_comme_produit_de_base__c
                                 From OpportunityLineItem 
                                 Where OpportunityId in :  mapOppProducts.keySet()
                                 And isMateriel_sur_place__c =: false ];  
        
        System.debug(LoggingLevel.DEBUG,'oppProductsNotOnPlace ' + oppProductsNotOnPlace);
        if(oppProductsAll.size() >  0)
        {
            for(OpportunityLineItem oppLI : oppProductsAll)
            {
                mapOppProducts.get(oppLI.OpportunityId).get('ALL').add(oppLI);
                mapidProductsALL.put(oppLI.PricebookEntry.Product2Id,oppLI.OpportunityId);

                if(oppLI.PricebookEntry.Product2.Type__c == 'Base' || oppLI.PricebookEntry.Product2.Option_comme_produit_de_base__c == TRUE){ 
                    nbreOppLinesProduitDeBaseAll++;
                }
            }
        }
        System.debug(LoggingLevel.DEBUG,'mapOppProducts ' + mapOppProducts);
        System.debug(LoggingLevel.DEBUG,'mapidProductsALL ' + mapidProductsALL);
        System.debug(LoggingLevel.DEBUG,'nbreOppLinesProduitDeBaseAll ' + nbreOppLinesProduitDeBaseAll);

        if(oppProductsNotOnPlace.size() >  0)
        {
            for(OpportunityLineItem oppLI : oppProductsNotOnPlace)
            {
                mapOppProducts.get(oppLI.OpportunityId).get('NotInPlace').add(oppLI);
                
                mapidProductsNotInPlace.put(oppLI.PricebookEntry.Product2Id,oppLI.OpportunityId);

                if(oppLI.PricebookEntry.Product2.Type__c == 'Base' || oppLI.PricebookEntry.Product2.Option_comme_produit_de_base__c == TRUE){ 
                    nbreOppLinesProduitDeBaseNotInPlace++;
                }
            }
        }
        
        System.debug(LoggingLevel.DEBUG,'mapidProductsNotInPlace ' + mapidProductsNotInPlace);
        nbreTotalOppLinesProduitsDeBaseOuOptionCommeBase = nbreOppLinesProduitDeBaseAll + nbreOppLinesProduitDeBaseNotInPlace;
        System.debug(LoggingLevel.DEBUG,'nbreOppLinesProduitDeBaseNotInPlace ' + nbreOppLinesProduitDeBaseNotInPlace);
        System.debug(LoggingLevel.DEBUG,'nbreTotalOppLinesProduitsDeBaseOuOptionCommeBase ' + nbreTotalOppLinesProduitsDeBaseOuOptionCommeBase);

        list<ALS_Cycle_Essai__c> ListCycleEssai = [SELECT id, Statut_global__c, Dernier_Cycle_d_essai__c, Opportunite__c
                                                    FROM ALS_Cycle_Essai__c
                                                    WHERE  Opportunite__c = : mapCycleEssai.keySet() ORDER BY CreatedDate ASC];
        
        System.debug(LoggingLevel.DEBUG,'ListCycleEssai ' + ListCycleEssai);
        Map<Id, ALS_Cycle_Essai__c> mapIdOppAvantDernierCycleEssai = new Map<Id, ALS_Cycle_Essai__c>();
        //Récupérer l'avant dernier cycle d'essai sur chaque opportunité
        if(ListCycleEssai.size() >= 2){
            for(Id oppID : mapCycleEssai.keySet()){
                mapIdOppAvantDernierCycleEssai.put(ListCycleEssai[ListCycleEssai.size()-2].Opportunite__c, ListCycleEssai[ListCycleEssai.size()-2]);
            }
        }
        System.debug(LoggingLevel.DEBUG,'mapIdOppAvantDernierCycleEssai ' + mapIdOppAvantDernierCycleEssai);
        Map<Id, List<ALS_Checklist__c>> mapIdOppListChecklist = new Map<Id, List<ALS_Checklist__c>>();
        //Pour chaque opportunité et son avant dernier cycle d'essai, je renseigne les checklists de ce cycle d'essai
        for(ALS_Checklist__c checklist : [SELECT Commentaire__c, Conclusion__c, Cycle_d_essai__c, Cycle_d_essai__r.Opportunite__c, Produit__c 
                                            FROM ALS_Checklist__c
                                            WHERE Cycle_d_essai__r.Opportunite__c in :mapIdOppAvantDernierCycleEssai.keySet()
                                            AND Cycle_d_essai__c =: mapIdOppAvantDernierCycleEssai.values()]){

            if(mapIdOppListChecklist.containsKey(checklist.Cycle_d_essai__r.Opportunite__c)){
                mapIdOppListChecklist.get(checklist.Cycle_d_essai__r.Opportunite__c).add(checklist);
            }else{
                mapIdOppListChecklist.put(checklist.Cycle_d_essai__r.Opportunite__c, new List<ALS_Checklist__c>());
                mapIdOppListChecklist.get(checklist.Cycle_d_essai__r.Opportunite__c).add(checklist);
            }                            
        }
        System.debug(LoggingLevel.DEBUG,'mapIdOppListChecklist ' + mapIdOppListChecklist);
        //Listes des champs nécessaires sur Product2
        List<Product2> produitsALL = [SELECT ID,Name,Description,Type__c,Gamme__c,Gamme__r.Name,Gamme__r.Texte_type__c,Option_comme_produit_de_base__c 
                                      FROM Product2
                                      WHERE ID IN : mapidProductsALL.keySet() AND (Type__c = 'Base' OR Option_comme_produit_de_base__c = TRUE)];
        List<Product2> ProductsNotInPlace = [Select ID,
                                             Name,
                                             Description,
                                             Type__c,
                                             Gamme__c,
                                             Gamme__r.Name,
                                             Gamme__r.Texte_type__c, 
                                             Option_comme_produit_de_base__c
                                             From Product2
                                             Where ID In : mapidProductsNotInPlace.keySet() AND (Type__c = 'Base' OR Option_comme_produit_de_base__c = TRUE)];
        if(produitsALL.size() > 0)
        {
            for(Product2 produit : produitsALL)
            {
                if(mapidProductsALL.get(produit.id) != null)
                {
                    mapCycleEssaiProductAll.get(mapCycleEssai.get(mapidProductsALL.get(produit.id)).id).add(produit);
                }
            }
        }
        
        if(ProductsNotInPlace.size() > 0)
        {
            for(Product2 produit : ProductsNotInPlace)
            {
                
                if(mapidProductsNotInPlace.get(produit.id) != null)
                {
                    mapCycleEssaiProductNotOnPlace.get(mapCycleEssai.get(mapidProductsNotInPlace.get(produit.id)).id).add(produit);
                }
            }
        }
        for(ALS_Cycle_Essai__c ce : listCyclesDEssai)
        {            if(mapCycleEssaiProductAll.get(ce.id).size() > 0 )
        {               
            Map<ID,Product2> CurentProducts = mapProduitsConcernes(mapCycleEssaiProductAll.get(ce.id));
            if(mapOppProducts.get(Ce.Opportunite__c).get('ALL').size() > 0)
            {
                for(OpportunityLineItem Litem : mapOppProducts.get(Ce.Opportunite__c).get('ALL'))
                {
                    
                    String strNomChecklist;
                    String tempCarac = '';
                    Integer number_characters = 0;
                    String strNomChecklist_Troncated = ''; //Champ permettant de récupérer les 80 premiers caractères du nom uniquement Modified by Marianne  ASSOGBAVI 25/10/2021
                    Product2 produit= CurentProducts.get(Litem.PricebookEntry.Product2Id);
                    
                    if(produit != null)
                    {                            
                       ID checklistRecordType = mapChecklistsGammes.get(produit.Gamme__c);
                       if(produit.Name.length() <= 80){
                        strNomChecklist = produit.Name;
                       }else {
                           do{
                                tempCarac = produit.Name.substring(number_characters, number_characters + 1);
                               strNomChecklist_Troncated += produit.Name.substring(number_characters, number_characters + 1);
                               number_characters++;
                           }while(number_characters < 80);
                           strNomChecklist = strNomChecklist_Troncated;
                       }
                       
                        ALS_Checklist__c checklist = new ALS_Checklist__c( Cycle_d_essai__c                     = ce.id,
                                                                          Name                                  = strNomChecklist,
                                                                          Produit__c                            = produit.Id,
                                                                          //RecordTypeId = checklistRecordType,
                                                                          isMateriel_en_essai__c                = true,
                                                                          Ligne_d_opportunit_ID__c              = Litem.id,
                                                                          statut__c                             = Litem.statut__c,
                                                                          Quantity__c                           = litem.Quantity,
                                                                          Description_de_la_ligne__c            = litem.Description);
                        
                        System.debug(LoggingLevel.DEBUG,'checklist ' + checklist);
                        /**Mettre sur chaque nouvelle checklist les informations de la checklist correspondante sur l'avant dernier cycle d'essai
                        * lorsqu'il existe un avant dernier cycle d'essai et qu'un nouveau produit a été ajouté avant la création de ce nouveau cycle d'essai */
                        if(mapIdOppListChecklist != null && mapIdOppListChecklist.get(Ce.Opportunite__c) != null){
                            if(nbreTotalOppLinesProduitsDeBaseOuOptionCommeBase > mapIdOppListChecklist.get(Ce.Opportunite__c).size()){
                                if(mapIdOppListChecklist.containsKey(Ce.Opportunite__c)){
                                    for(ALS_Checklist__c check : mapIdOppListChecklist.get(Ce.Opportunite__c)){
                                        if(check.Produit__c == checklist.Produit__c){
                                            checklist.Commentaire__c = check.Commentaire__c;
                                            checklist.Conclusion__c = check.Conclusion__c;
                                        }
                                    }
                                }
                            }
                        }
                        checklistsAcreer.add(checklist);
                        System.debug(LoggingLevel.DEBUG,'checklist 2' + checklist);
                    }                    
                }                    
            }                
        }
         
         if(mapCycleEssaiProductNotOnPlace.get(ce.id).size() > 0 )
         { 
             Map<ID,Product2> CurentProducts = mapProduitsConcernes(mapCycleEssaiProductNotOnPlace.get(ce.id));
             
             if(mapOppProducts.get(Ce.Opportunite__c).get('NotInPlace').size() > 0)
             {
                 
                 for(OpportunityLineItem Litem : mapOppProducts.get(Ce.Opportunite__c).get('NotInPlace'))
                 {                        
                     Product2 produit= CurentProducts.get(Litem.PricebookEntry.Product2Id);
                     
                     if(produit != null)
                     {
                         ID checklistRecordType =  mapChecklistsGammes.get(produit.Gamme__c);
                         String strNomChecklist = produit.Name;
                         String tempCarac = '';
                        Integer number_characters = 0;
                        String strNomChecklist_Troncated = ''; //Champ permettant de récupérer les 80 premiers caractères du nom uniquement Modified by Marianne  ASSOGBAVI 25/10/2021
                   
                        if(produit.Name.length() <= 80){
                            strNomChecklist = produit.Name;
                        }else {
                               do{
                                    tempCarac = produit.Name.substring(number_characters, number_characters + 1);
                                    strNomChecklist_Troncated += produit.Name.substring(number_characters, number_characters + 1);
                                    number_characters++;
                               }while(number_characters < 80);
                               strNomChecklist = strNomChecklist_Troncated;
                        }

                         ALS_Checklist__c checklist = new ALS_Checklist__c( Cycle_d_essai__c            = ce.id,
                                                                           Name                               = strNomChecklist,
                                                                           Produit__c                     = produit.Id,
                                                                           isMateriel_en_essai__c   = false,
                                                                           Ligne_d_opportunit_ID__c = Litem.id,
                                                                           statut__c                      = Litem.statut__c,
                                                                           Quantity__c                    = litem.Quantity,
                                                                           Description_de_la_ligne__c   = litem.Description);

                        System.debug(LoggingLevel.DEBUG, 'checklist ' + checklist);
                        /**Mettre sur chaque nouvelle checklist les informations de la checklist correspondante sur l'avant dernier cycle d'essai
                        * lorsqu'il existe un avant dernier cycle d'essai et qu'un nouveau produit a été ajouté avant la création de ce nouveau cycle d'essai */
                        if(mapIdOppListChecklist != null && mapIdOppListChecklist.get(Ce.Opportunite__c) != null){
                            if(nbreTotalOppLinesProduitsDeBaseOuOptionCommeBase > mapIdOppListChecklist.get(Ce.Opportunite__c).size()){
                                if(mapIdOppListChecklist.containsKey(Ce.Opportunite__c)){
                                    for(ALS_Checklist__c check : mapIdOppListChecklist.get(Ce.Opportunite__c)){
                                        if(check.Produit__c == checklist.Produit__c){
                                            checklist.Commentaire__c = check.Commentaire__c;
                                            checklist.Conclusion__c = check.Conclusion__c;
                                        }
                                    }
                                }
                            }
                        }                                        
                         checklistsAcreer.add(checklist);
                         System.debug(LoggingLevel.DEBUG,'checklist ' + checklist);
                    }
                 }                    
             } 
         } 
        }
        database.insert(checklistsAcreer, true);  
    }
    /**
     * @description Methode retournant une Map de correspondance entre les gammes et les type d'enregistrements de checklist
     * @return mapChecklistsGammes
     */
    public static Map<ID,ID> mapChecklistsGammes (){
        //Map des type d'enregistrements Checklists
        Map<String,ID> mapTypeEnregChecklist = new Map<String,ID>();
        for(RecordType typeEnregistrement : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType='ALS_Checklist__c']){
            mapTypeEnregChecklist.put(typeEnregistrement.DeveloperName, typeEnregistrement.ID);
        }
        //Map de correspondance entre les gammes et les type d'enregistrements de checklist
        Map<ID,ID> mapChecklistsGammes = new Map<ID,ID>();
        for (TECH_Correspondance_Checklists_Gammes__c correspondance :
             [Select Nom_du_type_d_enregistrement_checklist__c, Gamme__r.Id
              From TECH_Correspondance_Checklists_Gammes__c]){
                  ID idTypeChecklist = mapTypeEnregChecklist.get(correspondance.Nom_du_type_d_enregistrement_checklist__c);
                  mapChecklistsGammes.put(correspondance.Gamme__r.Id, idTypeChecklist);                          
              }
        return mapChecklistsGammes;
    }    
    /**
     * @description map Produits Concernes
     * @param produits
     * @return mapProduits
     */
    public static  Map<ID,Product2> mapProduitsConcernes (List<Product2> produits){
        Map<ID,Product2> mapProduits = new Map<ID,Product2>();
        for(Product2 prod : produits){
            mapProduits.put(prod.ID,prod);
        }
        return mapProduits;
    }
    /**
     * @description update Last Cycle
     * @param listCyclesDEssai
     */
    public static void updateLastCycle(list<ALS_Cycle_Essai__c> listCyclesDEssai)
    {
        map<id, ALS_Cycle_Essai__c> mapOppCycleEssai = new  map<id, ALS_Cycle_Essai__c>();
        list<ALS_Cycle_Essai__c> listCyclesEssaiToUpdate= new list<ALS_Cycle_Essai__c>();       
        
        for(ALS_Cycle_Essai__c ce : listCyclesDEssai)
        {
            mapOppCycleEssai.put(ce.Opportunite__c, ce);
        }
        
        list<ALS_Cycle_Essai__c> listCyclesEssaiv2 = [select id, Opportunite__c, Dernier_Cycle_d_essai__c from ALS_Cycle_Essai__c where Opportunite__c in : mapOppCycleEssai.keySet()];
        
        
        if(listCyclesEssaiv2.size() > 0)
        {
            for(ALS_Cycle_Essai__c ce : listCyclesDEssai)
            {
                for (Integer i = listCyclesEssaiv2.size() - 1; i >= 0 ; --i) {
                    
                    if (listCyclesEssaiv2.get(i) == ce || listCyclesEssaiv2.get(i).get('id') == ce.get('id')) {
                        
                        listCyclesEssaiv2.remove(i);
                        
                    }                    
                }
                
            }
            
            if(listCyclesEssaiv2.size() > 0)
            {
                for(ALS_Cycle_Essai__c ce : listCyclesEssaiv2)
                {
                    ce.Dernier_Cycle_d_essai__c = false;
                    listCyclesEssaiToUpdate.add(ce);
                }
                if(listCyclesEssaiToUpdate.size() > 0)
                {
                    ALS_Utils_Bypass.bypass('ALS_TR_CycleEssai',true);                    
                    update listCyclesEssaiToUpdate;
                    ALS_Utils_Bypass.bypass('ALS_TR_CycleEssai',false);
                }
            }
        }
        
    }
    /**
     * @description update Statut Global
     * @param listCyclesDEssai
     */
    public static void updateStatutGlobal(list<ALS_Cycle_Essai__c> listCyclesDEssai)
    {       
        for(ALS_Cycle_Essai__c ce : listCyclesDEssai)
        {
            if(ce.Statut_global__c == null)
                ce.Statut_global__c  = 'Ouvert';
            
            ce.Dernier_Cycle_d_essai__c = true;                     
        }
    }
    /**
     * @description Update Emails method
     * @param listCyclesDEssai
     */
    public static void updateEmails(list<ALS_Cycle_Essai__c> listCyclesDEssai)
    {
        map<id,opportunity> mapOpp = new map<id,opportunity>();
        
        for(ALS_Cycle_Essai__c ce : listCyclesDEssai)
        {
            mapOpp.put(ce.Opportunite__c, new opportunity());
        }
        
        list<opportunity> opportunityList = [select id, StageName, Utilisateur_contact__r.email,SAMETH_Referent_handicap__r.email,
                                             Referent_interne__r.email,Medecin_du_travail__r.email,
                                             Interlocuteur_Devis_Commande_Facture__r.email, Infirmiere__r.email,
                                             Ergonome__r.email, Compte_Revendeur__c
                                             from opportunity where id in : mapOpp.keySet()];
        
        for(opportunity opp : opportunityList)
        {
            mapOpp.put(opp.id, opp);
        }
        
        for(ALS_Cycle_Essai__c ce : listCyclesDEssai)
        {
            if(mapOpp.get(ce.Opportunite__c).Ergonome__r.email != null){
                ce.Email_Ergonome__c = mapOpp.get(ce.Opportunite__c).Ergonome__r.email;
            }
            if(mapOpp.get(ce.Opportunite__c).Utilisateur_contact__r.email != null){
                ce.Email_utilisateur__c = mapOpp.get(ce.Opportunite__c).Utilisateur_contact__r.email;
            }
            if(mapOpp.get(ce.Opportunite__c).Infirmiere__r.email != null){
                ce.Email_infirimiere__c = mapOpp.get(ce.Opportunite__c).Infirmiere__r.email;
            } 
            if(mapOpp.get(ce.Opportunite__c).Interlocuteur_Devis_Commande_Facture__r.email != null){
                ce.Email_interlocuteur_Facture__c = mapOpp.get(ce.Opportunite__c). Interlocuteur_Devis_Commande_Facture__r.email;
            }
            if(mapOpp.get(ce.Opportunite__c).Referent_interne__r.email != null){
                ce.Email_Referent_interne__c = mapOpp.get(ce.Opportunite__c).Referent_interne__r.email;
            }  
            if(mapOpp.get(ce.Opportunite__c).Medecin_du_travail__r.email != null){
                ce.Email_Medecin_de_travail__c = mapOpp.get(ce.Opportunite__c).Medecin_du_travail__r.email;
            }
            if(mapOpp.get(ce.Opportunite__c).SAMETH_Referent_handicap__r.email != null){
                ce.Email_Referent_handicap__c = mapOpp.get(ce.Opportunite__c).SAMETH_Referent_handicap__r.email;
            }
            
            //Si le partenaire Azergo est renseigné au moment de la création cocher automatiquement la case
            //Désactiver mails automatiques suivi essai;
            if(mapOpp.get(ce.Opportunite__c).Compte_Revendeur__c != null){
                ce.Activer_le_questionnaire_de_satisfaction__c = TRUE;
            }   
        }        
    }
    /**
     * @description Permet de mettre à jour le champ "Commentaire mail synthèse d’intervention" sur l'opportunité
     * @param listNew
     * @param mapOld
     **/
    public static void updateCommentaireSyntheseIntervetionOpportunity(List<ALS_Cycle_Essai__c> listNew, Map<Id,ALS_Cycle_Essai__c> mapOld){
        Map<Id, ALS_Cycle_Essai__c> mapOpportunityDernierCycleEssai = new Map<Id, ALS_Cycle_Essai__c>();
        Map<Id,ALS_Cycle_Essai__c> mapOpportunityCycleFerme   = new Map<Id, ALS_Cycle_Essai__c>();
        
        for(ALS_Cycle_Essai__c cycle : listNew){
            //Les cycles d'essai ouvert
            if(cycle.Dernier_Cycle_d_essai__c == true && ( mapOld == null || mapOld.get(cycle.id).Commentaire_mail_synthese_d_intervention__c != cycle.Commentaire_mail_synthese_d_intervention__c)){
                mapOpportunityDernierCycleEssai.put(cycle.Opportunite__c, cycle);                       
            }
        }
        
        //Copier la valeur du champ "Commentaire mail synthèse d’intervention" sur les opportunités associées aux cycles d'essais ouverts
        if( ! mapOpportunityDernierCycleEssai.isEmpty()){
            List<Opportunity> listOpportunityWithCycleOuvert = [Select id, Commentaire_mail_synthese_d_intervention__c from Opportunity where id IN: mapOpportunityDernierCycleEssai.keySet()];
            for(Opportunity opp : listOpportunityWithCycleOuvert){
                if(String.isNotBlank(mapOpportunityDernierCycleEssai.get(opp.Id).Commentaire_mail_synthese_d_intervention__c)){
                    opp.Commentaire_mail_synthese_d_intervention__c = mapOpportunityDernierCycleEssai.get(opp.Id).Commentaire_mail_synthese_d_intervention__c;
                }
                
            }
            Update listOpportunityWithCycleOuvert;
        }
    }
    
    /**
     * @author Saamiyah Khodadin
     * @description Method to update an event - TMA0003
     * @param listNew
     * @param mapOld
	**/
    public static void updateEvent(List<ALS_Cycle_Essai__c> listNew, Map<Id,ALS_Cycle_Essai__c> mapOld){
        if(bypassTrigger == false){ // Saamiyah K - mia- Added if statement - SOQL limit issue 19 April 2023
            Set<Id> cycleId = new Set<Id>();
            String opportunityId;
            DateTime modifiedDate;
            Double duration;
            Boolean dateModified = false;
            Boolean infoModified = false;
            Boolean bypassRunOnce = false;
            System.debug(LoggingLevel.DEBUG, '#### Inside method update event');
            for(ALS_Cycle_Essai__c cycle : listNew){
                if(cycle.Date_Mise_en_essai__c != mapOld.get(cycle.id).Date_Mise_en_essai__c){
                    cycleId.add(cycle.Id);
                    modifiedDate = cycle.Date_Mise_en_essai__c;
                    duration = cycle.Duree_RDV_Mise_en_essai_min__c;
                    dateModified = true;
                }
                if(cycle.Info_Outlook__c != mapOld.get(cycle.id).Info_Outlook__c ){
                    infoModified = true;
                    cycleId.add(cycle.Id);
                    opportunityId = cycle.opportunite__c;
                }
            }
            if(cycleId.size() > 0 && dateModified == true){
                List<Event> evt = new list<Event>();  // 17 July 2023
                evt = [SELECT Id,StartDateTime,EndDateTime FROM Event WHERE WhatId In: cycleId];
                if(evt.size() > 0){
                    evt[0].StartDateTime = modifiedDate;
                    evt[0].EndDateTime = modifiedDate.addMinutes(duration.intValue());
                    Database.update(evt);
                }
               
            }
            if(cycleId.size() > 0 && infoModified == true){
                List<Event> evt = new list<Event>();   // 17 July 2023
                evt = [SELECT Id, Description FROM Event WHERE WhatId In: cycleId];
                if(evt.size() > 0){
                    evt[0].Description = updateDescriptionEvent(listNew, opportunityId); 
                    Database.update(evt);
                }
                
            }
            bypassRunOnce =true;
        }    
    }
    /**
     * @author Saamiyah Khodadin
     * @description method to update the description of an event - TMA0003
     * @param listNew
     * @param oppId
     * @return string description
	*/
    public static String updateDescriptionEvent(List<ALS_Cycle_Essai__c> listNew, String oppId){
        bypassTrigger=false;// Saamiyah K - mia- Added if statement - SOQL limit issue 19 April 2023
        if(bypassTrigger == false){
            List <String> lstToUpdate = new List<String>();        
            String fullUrlToOpp = URL.getSalesforceBaseUrl().toExternalForm() +  '/' + oppId ;
            String urlToCycleEssai = URL.getSalesforceBaseUrl().toExternalForm() +  '/';
            String newDescription='';
            //TMA0085 - Saamiyah K. 6 Sep 2023
            String autreIntervenantTxt = '';
            String infirmierTxt = '';
            String utilisateurTxt = '';
            String ergonomeTxt = '';
            String referentHandicapTxt = '';
            String interlocuteurDevisTxt = '';
            String referentInterneTxt = '';
            String medecinTxt = '';
            //29/07/2023 TMA_0075 LB - Modified query to return options only
            List<OpportunityLineItem> oppLineItem = [SELECT Id, Product2.Name, Quantity, Statut__c, ProductCode, N_ligne_Niveau_1__c,
                                                     Type__c, Article_hors_config_STD__c, Infos_Interne__c
                                                        FROM OpportunityLineItem
                                                        WHERE OpportunityId =: oppId 
                                                        AND (Type__c = 'Base' OR (Type__c = 'Option' AND Article_hors_config_STD__c = true))];
            System.debug(LoggingLevel.DEBUG, 'OpplineItems check ### : ' + oppLineItem);                                         
            String productAddtoEvent;
            Integer i = 1;
            Decimal previousNiveau = 0;
            for(OpportunityLineItem oppline : oppLineItem){
                // first time
                if(i != 1) {
                    if(oppline.N_ligne_Niveau_1__c != previousNiveau ){
                        productAddtoEvent +='\n\n';
                    }
                    else{
                        productAddtoEvent += '\n';
                    }
                }
                //29/07/2023 TMA_0075 LB
                productAddtoEvent += oppline.Quantity + ' | ' + oppline.Statut__c + ' | ' + oppline.ProductCode +'- '+ oppline.Product2.Name + ' | ' + oppline.Infos_Interne__c;      
                productAddtoEvent = productAddtoEvent.remove('null');
                previousNiveau = oppline.N_ligne_Niveau_1__c;
                i = i +1;
            }
            Opportunity opp = [Select ID,Name,
                                    OwnerId,
                                    Adresse_de_livraison_Rue__c,
                                    Adresse_de_livraison_Code_postal__c,
                                    Adresse_de_livraison_Ville__c,
                                    Nom_du_compte__c, // miaaa
                                    Medecin_du_travail__c,Medecin_du_travail__r.MobilePhone,Medecin_du_travail__r.Name,
                                    Infirmiere__c, Infirmiere__r.MobilePhone,Infirmiere__r.Name,
                                    Ergonome__c, Ergonome__r.MobilePhone,Ergonome__r.Name,
                                    SAMETH_Referent_handicap__c, SAMETH_Referent_handicap__r.Email,SAMETH_Referent_handicap__r.MobilePhone, SAMETH_Referent_handicap__r.Name, 
                                    Interlocuteur_Devis_Commande_Facture__c, Interlocuteur_Devis_Commande_Facture__r.MobilePhone, Interlocuteur_Devis_Commande_Facture__r.Name,
                                    Referent_interne__c, Referent_interne__r.MobilePhone, Referent_interne__r.Name,
                                    Autre_intervenant__c,Autre_intervenant__r.Email, Autre_intervenant__r.MobilePhone, Autre_intervenant__r.Name,
                                    Utilisateur__c
                                    From Opportunity
                                    Where ID =: oppId];
           
            for (ALS_Cycle_Essai__c cycle : listNew){
                 // Saamiyah - 4 Sep 2023 - TMA0085
                 if(cycle.nom_complet_utilisateur__c != null || cycle.Email_utilisateur__c != null || cycle.FORM_Telephone_de_l_utilisateur__c != null || cycle.FORM_Telephone_mobile_utilisateur__c != null){
                    utilisateurTxt = 'Contact utilisateur : ' + cycle.nom_complet_utilisateur__c + ' / ' + cycle.Email_utilisateur__c + ' / ' + cycle.FORM_Telephone_de_l_utilisateur__c + ' / ' + cycle.FORM_Telephone_mobile_utilisateur__c  + '\n';
                }
                if(opp.Medecin_du_travail__r.Name != null || cycle.Email_Medecin_de_travail__c != null || opp.Medecin_du_travail__r.MobilePhone != null){
                    medecinTxt = 'Medecin du travail : ' +  opp.Medecin_du_travail__r.Name + ' / ' + cycle.Email_Medecin_de_travail__c + ' / ' + opp.Medecin_du_travail__r.MobilePhone + '\n';
                }
                if(opp.Infirmiere__r.Name != null || cycle.Email_infirimiere__c != null || opp.Infirmiere__r.MobilePhone != null){
                    infirmierTxt = 'Infirmière : ' + opp.Infirmiere__r.Name + ' / ' + cycle.Email_infirimiere__c + ' / ' + opp.Infirmiere__r.MobilePhone + '\n';
                }
                if(opp.Ergonome__r.Name != null || cycle.Email_Ergonome__c != null || opp.Ergonome__r.MobilePhone != null){
                    ergonomeTxt = 'Ergonome : ' + opp.Ergonome__r.Name + ' / ' + cycle.Email_Ergonome__c + ' / ' +opp.Ergonome__r.MobilePhone + '\n';
                }
                if(opp.SAMETH_Referent_handicap__r.Name != null || cycle.Email_Referent_handicap__c != null || opp.SAMETH_Referent_handicap__r.MobilePhone != null){
                    referentHandicapTxt = 'SAMETH Référent handicap : ' + opp.SAMETH_Referent_handicap__r.Name + ' / ' + cycle.Email_Referent_handicap__c + ' / ' + opp.SAMETH_Referent_handicap__r.MobilePhone + '\n';
                }
                if(opp.Interlocuteur_Devis_Commande_Facture__r.Name != null || cycle.Email_interlocuteur_Facture__c != null ||  opp.Interlocuteur_Devis_Commande_Facture__r.MobilePhone != null){
                    interlocuteurDevisTxt = 'Interlocuteur Devis Commande Facture : ' + opp.Interlocuteur_Devis_Commande_Facture__r.Name + ' / ' + cycle.Email_interlocuteur_Facture__c + ' / ' +  opp.Interlocuteur_Devis_Commande_Facture__r.MobilePhone + '\n';
                }
                if(opp.Referent_interne__r.Name != null || cycle.Email_Referent_interne__c != null || opp.Referent_interne__r.MobilePhone != null){
                    referentInterneTxt = 'Referent interne : ' + opp.Referent_interne__r.Name + ' / ' + cycle.Email_Referent_interne__c + ' / ' + opp.Referent_interne__r.MobilePhone + '\n\n\n' ;
                }
                if(opp.Autre_intervenant__r.Name != null || opp.Autre_intervenant__r.Email != null || opp.Autre_intervenant__r.MobilePhone != null ){
                    autreIntervenantTxt = 'Autre intervenant : ' + opp.Autre_intervenant__r.Name + ' / ' + opp.Autre_intervenant__r.Email + ' / ' + opp.Autre_intervenant__r.MobilePhone + '\n';
                }
                // END mia
                newDescription = 'Lien du cycle d\'essai: ' + urlToCycleEssai + cycle.Id + '\n' +
                                    '----------------------------------------------------------------------------------------' + '\n'+
                                    'ATTENTION, TOUTES LES MODIFICATIONS DOIVENT SE FAIRE PAR LE CYCLE D\'ESSAI.' + '\n' + 
                                    '----------------------------------------------------------------------------------------' + '\n'+
                                    'Lien de l\'opportunité : ' + fullUrlToOpp + '\n' +
                                    'Nom du compte : ' + cycle.Nom_du_compte__c + '\n' +
                                    'Info Outlook : ' + cycle.Info_Outlook__c + '\n\n' +
                                    utilisateurTxt + medecinTxt + infirmierTxt + ergonomeTxt +
                                    referentHandicapTxt + interlocuteurDevisTxt + autreIntervenantTxt + referentInterneTxt +
                                    'Produits de l\'opportunité: ' + '\n' + 
                                    '----------------------------------------------------' + '\n'+
                                    'Quantité | Statut | Nom du produit | Infos internes' + '\n' +
                                    '----------------------------------------------------' + '\n'+
                                    productAddtoEvent;
            }
            bypassTrigger = true;
            return newDescription;
        }
        return null;
        
    }
    
    /**
     * @description Permet de mettre à jour une case à cocher 'Envoyer la synthèse d'intervention' qui permet de 
     * déclencher un workflow qui envoie l'email de synthèse d'intervention
     * @param listNew
     * @param  mapOld
    **/
    public static void sendSyntheseIntervetion(List<ALS_Cycle_Essai__c> listNew, Map<Id,ALS_Cycle_Essai__c> mapOld){
        Set<Id> setIdOpportunityToUpdate = new Set<Id>();
        for(ALS_Cycle_Essai__c cycle : listNew){
            //Récupérer les id des cycles d'essais qui ont la case à cocher "Envoyer la synthèse d'intervention" égale à vrai
            if(cycle.Envoyer_la_synthese_intervention__c == true && (mapOld==null || mapOld.get(cycle.Id).Envoyer_la_synthese_intervention__c != cycle.Envoyer_la_synthese_intervention__c)){
                setIdOpportunityToUpdate.add(cycle.Opportunite__c);          
            }
        }
        if( setIdOpportunityToUpdate.size() > 0){
            list<Opportunity> listOpp = [Select id, Envoyer_la_synthese_d_intervention__c from Opportunity where id IN: setIdOpportunityToUpdate];
            for(Opportunity opp : listOpp){
                opp.Envoyer_la_synthese_d_intervention__c = true;
            }
            //mettre à jour les opportunités
            update listOpp;
        }
    }
    /**
     * @description Permet de mettre à jour le champ tech_dernier_cycle_Essai sur l'opportunité 
     * @param listNew
    **/
    public static void updateOppotunityWithTheLastCycleEssai(List<ALS_Cycle_Essai__c> listNew){
         
        map<id,ALS_Cycle_Essai__c> mapIdOppCycleEssai = new map<id,ALS_Cycle_Essai__c>();
        for(ALS_Cycle_Essai__c ce : listNew)
        {
            if(ce.Statut_global__c == 'Ouvert')
            {
                mapIdOppCycleEssai.put(ce.Opportunite__c, ce);                
            }
        }
       if(mapIdOppCycleEssai.size() > 0)
       {
           list<opportunity> listOpps = new list<opportunity>();
           for(opportunity opp : [select id,Tech_Dernier_Cycle_d_essai__c,URL_Survey__c,Duree_planifiee__c,
                                  Date_de_fin_d_essai_sans_heure__c
                                  from opportunity where id in : mapIdOppCycleEssai.keyset()])
           {
               if(mapIdOppCycleEssai.get(opp.id) != null)
               {
                   opp.Tech_Dernier_Cycle_d_essai__c = mapIdOppCycleEssai.get(opp.id).id;
                   opp.URL_Survey__c = mapIdOppCycleEssai.get(opp.id).URL_Survey__c;
                   opp.Duree_planifiee__c = mapIdOppCycleEssai.get(opp.id).Duree_planifiee__c;
                   opp.Date_de_fin_d_essai_sans_heure__c = mapIdOppCycleEssai.get(opp.id).Date_de_Retour_d_essai__c;
                   
                   listOpps.add(opp);
               }
           }
           if(listOpps.size() > 0)
           {
               ALS_Utils_Bypass.bypass('ALS_TR_Opportunity',true);
               ALS_Utils_Bypass.bypass('SRD_SharingRuels_Opportunity',true);               
               update listOpps;
               ALS_Utils_Bypass.bypass('ALS_TR_Opportunity',false);
               ALS_Utils_Bypass.bypass('SRD_SharingRuels_Opportunity',false);
           }
       }
    }
    /**
     * @author Saamiyah.B Khodadin
     * @description Permet avant la suppression du cycle d'essai de s'assurer que son statut est bien ouvert
     * @param listOld
    **/
    public static void verificationbeforedeletionofCycleEssai(List<ALS_Cycle_Essai__c> listOld){ 
        Set<Id> cycleOppId = new Set<Id>();
        for(ALS_Cycle_Essai__c ce : listOld){
            cycleOppId.add(ce.Opportunite__c);
        }
        List<Opportunity> listOpp = [SELECT Id, Tech_CheckDelete_CE__c FROM Opportunity WHERE id IN :cycleOppId];
        System.debug(LoggingLevel.DEBUG, 'ListOpp #### : ' + listOpp);
        for(Opportunity opp : listOpp){
            opp.Tech_CheckDelete_CE__c = true;
            update opp;
        }
        Id profileId=userinfo.getProfileId();
        //Saamiyah.B Khodadin - TMA0068 - Bloquer la suppression d'un cycle d'essai, sauf si on est Admin
        for(ALS_Cycle_Essai__c ce : listOld){
            if(profileId != Label.CL_SystemAdministrator && (ce.Statut_global__c == 'Fermé non validé' || ce.Statut_global__c == 'Fermé validé' )){     
                ce.addError(Label.CL_ErrorMessage_CycleEssai);
           	}
        }
    }
     /**
      * @author Saamiyah khodadin 11 April 2023
     * @description Delete an event
     * @param listNew
     * @param mapOld
    **/
   	public static void updateEventDeletion(List<ALS_Cycle_Essai__c> listNew, Map<Id,ALS_Cycle_Essai__c> mapOld){
        Set<Id> cycleId = new Set<Id>();
        Boolean deleteEvent = false;
        Boolean createEvent = false;
        System.debug(LoggingLevel.DEBUG, '### IN METHOD TO Delete event ####');
        for(ALS_Cycle_Essai__c cycle : listNew){
            if(cycle.Ne_pas_cree_RDV__c == true && (mapOld==null || mapOld.get(cycle.Id).Ne_pas_cree_RDV__c != cycle.Ne_pas_cree_RDV__c)){
                //delete event associated
                cycleId.add(cycle.Id);
                deleteEvent = true;
            }
            if(cycle.Ne_pas_cree_RDV__c == false && (mapOld==null || mapOld.get(cycle.Id).Ne_pas_cree_RDV__c != cycle.Ne_pas_cree_RDV__c)){
                cycleId.add(cycle.Id);
                createEvent = true;
            }
        }
        if(deleteEvent == true){
            Event evt = [SELECT Id,StartDateTime,EndDateTime FROM Event WHERE WhatId In: cycleId];
            Database.delete(evt);

            List<ALS_Cycle_Essai__c> cycle = [SELECT Id FROM ALS_Cycle_Essai__c WHERE Id IN :trigger.new];
            for(ALS_Cycle_Essai__c cEssai : cycle){
                cEssai.isRDV_de_Mise_en_Essai_cree__c = false;
            } 
            database.update(cycle);
        }
        if(createEvent == true){
            creationEvenement(listNew);
        }
    }
}