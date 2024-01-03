/**
 * @File Name          : ALS_TR_02_CYCLE_ESSAI.trigger
 * @Description        : 
 * @Author             : ??
 * @Group              : 
 * @Last Modified By   : Bertrand Leymarios
 * @Last Modified On   : 20/3/2020 23:24:44
 * 
 * @Modification       : 11/05/2022 by Marianne ASSOGBAVI
**/
trigger ALS_TR_02_CYCLE_ESSAI on ALS_Cycle_Essai__c (before insert, after insert, before update, after update, before delete, after delete) {
    if(ALS_Utils_Bypass.canExecute('ALS_TR_CycleEssai')){
		
        // BEFORE INSERT
        if(trigger.isBefore && trigger.isInsert){
            ALS_CL_01_CYCLE_ESSAI.stopCycleEssaiCreation(trigger.new);
            ALS_CL_01_CYCLE_ESSAI.updateStatutGlobal(trigger.new); 
            ALS_CL_01_CYCLE_ESSAI.updateEmails(trigger.new);             
           // ALS_CL_01_CYCLE_ESSAI.updateEmails(trigger.new, null);     

        // BEFORE UPDATE
        } else if(trigger.isBefore && trigger.isUpdate){
            //ALS_CL_01_CYCLE_ESSAI.updateEmails(trigger.new);  
            //ALS_CL_01_CYCLE_ESSAI.updateEmails(trigger.new, trigger.oldmap);  

        // AFTER INSERT
        } else if(trigger.isAfter && trigger.isInsert){
            ALS_CL_01_CYCLE_ESSAI.runOnceFlagCreation = true; // MIAAAA - SK - TMA0003
            ALS_CL_01_CYCLE_ESSAI.createChecklist(trigger.new);
            ALS_CL_01_CYCLE_ESSAI.updateLastCycle(trigger.new);
            ALS_CL_01_CYCLE_ESSAI.updateOppotunityWithTheLastCycleEssai(trigger.new);
            ALS_CL_01_CYCLE_ESSAI.updateCommentaireSyntheseIntervetionOpportunity(trigger.new, null);
            ALS_CL_01_CYCLE_ESSAI.sendSyntheseIntervetion(trigger.new, null);    
            
        
        // AFTER UPDATE
        } else if(trigger.isAfter && trigger.isUpdate){       
           
            ALS_CL_01_CYCLE_ESSAI.updateCommentaireSyntheseIntervetionOpportunity(trigger.new, trigger.oldmap);
             
            ALS_CL_01_CYCLE_ESSAI.sendSyntheseIntervetion(trigger.new, trigger.oldmap);
            
            ALS_CL_01_CYCLE_ESSAI.updateOppotunityWithTheLastCycleEssai(trigger.new); 
            if(ALS_CL_01_CYCLE_ESSAI.runOnceFlagCreation == false){
            	ALS_CL_01_CYCLE_ESSAI.updateEvent(trigger.new, trigger.oldmap); // MIAAAA - SK - TMA0003
            }
            ALS_CL_01_CYCLE_ESSAI.updateEventDeletion(trigger.new, trigger.oldmap); // MIAAAA - SK - TMA0046
        }
        
        // BEFORE UPDATE
        if(trigger.isBefore && trigger.isUpdate){
            ALS_CL_01_CYCLE_ESSAI.creationEvenement(trigger.new); 
        }
        
        //BEFORE DELETE
        if(trigger.isBefore && trigger.isDelete){
            ALS_CL_01_CYCLE_ESSAI.verificationbeforedeletionofCycleEssai(trigger.old);
            //ALS_CL_01_CYCLE_ESSAI.updateCheckDeleteofCycleEssai(trigger.old); 
        }
        //miaa 
        if(trigger.isAfter && trigger.isDelete){
            //ALS_CL_01_CYCLE_ESSAI.updateCheckDeleteofCycleEssai(trigger.old); 
        }
    }
    
    
}