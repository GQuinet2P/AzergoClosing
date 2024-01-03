import { LightningElement, api, track, wire } from 'lwc';
import getTemplateFolders from '@salesforce/apex/P2C_ClosingSendEmailController.getTemplateFolders';
import getEmailTemplates from '@salesforce/apex/P2C_ClosingSendEmailController.getEmailTemplates';
import getTemplatePreview from '@salesforce/apex/P2C_ClosingSendEmailController.getTemplatePreview';
import getQuotesFilesForOppty from '@salesforce/apex/P2C_ClosingSendEmailController.getQuotesFilesForOppty';
import generateQuoteFile from '@salesforce/apex/P2C_ClosingSendEmailController.generateQuoteFile';
import getRecordsInfo from '@salesforce/apex/P2C_ClosingSendEmailController.getRecordsInfo';
import sendEmails from '@salesforce/apex/P2C_ClosingSendEmailController.sendEmails';
import Id from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import UserNameFIELD from '@salesforce/schema/User.Name';
import userEmailFIELD from '@salesforce/schema/User.Email';
import {FlowAttributeChangeEvent,FlowNavigationNextEvent,} from 'lightning/flowSupport';
import closingEmail_defaultFolder from '@salesforce/label/c.closingEmail_defaultFolder';
import closingEmail_PreviewTitle from '@salesforce/label/c.closingEmail_PreviewTitle';
import closingEmail_SendSwitchLabel from '@salesforce/label/c.closingEmail_SendSwitchLabel';
import closingEmail_SendSwitchAuto from '@salesforce/label/c.closingEmail_SendSwitchAuto';
import closingEmail_SendSwitchManual from '@salesforce/label/c.closingEmail_SendSwitchManual';
import closingEmail_PickerListTitle from '@salesforce/label/c.closingEmail_PickerListTitle';
import closingEmail_ContentLabel from '@salesforce/label/c.closingEmail_ContentLabel';
import closingEmail_SubjectLabel from '@salesforce/label/c.closingEmail_SubjectLabel';
import closingEmail_TemplateFileLabel from '@salesforce/label/c.closingEmail_TemplateFileLabel';
import closingEmail_TemplateFolderLabel from '@salesforce/label/c.closingEmail_TemplateFolderLabel';
import closingEmail_InputBccLabel from '@salesforce/label/c.closingEmail_InputBccLabel';
import closingEmail_InputCcLabel from '@salesforce/label/c.closingEmail_InputCcLabel';
import closingEmail_PrevButtonAlt from '@salesforce/label/c.closingEmail_PrevButtonAlt';
import closingEmail_NextButtonAlt from '@salesforce/label/c.closingEmail_NextButtonAlt';
import closingEmail_SendEmailButtonLabel from '@salesforce/label/c.closingEmail_SendEmailButtonLabel';

export default class P2c_ClosingSendEmail extends LightningElement {

    @api recordIds;
    @api recordApiName;
    @api toEmailApiFieldName;
    @api ccEmailApiFieldName;
    @api bccEmailApiFieldName;
    @api groupRecordsByApiFieldName;
    @api successRecordIds;
    @api failedRecordIds;

    @api sentEmailRecordIds  // deprecated

    @track isLoading;
    @track emailFrom;
    @track emailTo;
    @track emailCc;
    @track emailBcc;
    @track emailWhatId;
    @track showCc = undefined;
    @track showBcc = undefined;
    @track templateOptions;
    @track templateFolderOptions;
    @track emailSubjectValue;
    @track emailBodyValue;

    @track currentGroupIndex;
    @track currentGroupName;
    @track currentGroupSend;

    // @track currentRecordId;
    // @track currentRecordName;
    // @track currentRecordSend;

    @track opptyFilesStruct;
    @track attachedFileName;
    @track attachedFileId;
    @track selectedTemplateId;
    @track selectedFolderName;
    @track selectedFolderId;

    @track userId = Id;
    @track userEmail;
    @track userName;
    @track error;

    recordIndex = 0;
    emailsProcess = new Map();
    templates = new Map();
    mergeFieldsMap = new Map();

    bodyFormats = [
        'font',
        'size',
        'bold',
        'italic',
        'underline',
        'strike',
        'list',
        'indent',
        'align',
        'link',
        'image',
        'clean',
        'table',
        'header',
        'color',
    ];

    label = {
        closingEmail_defaultFolder,
        closingEmail_PreviewTitle,
        closingEmail_SendSwitchLabel,
        closingEmail_SendSwitchAuto,
        closingEmail_SendSwitchManual,
        closingEmail_PickerListTitle,
        closingEmail_ContentLabel,
        closingEmail_SubjectLabel,
        closingEmail_TemplateFileLabel,
        closingEmail_TemplateFolderLabel,
        closingEmail_InputBccLabel,
        closingEmail_InputCcLabel,
        closingEmail_PrevButtonAlt,
        closingEmail_NextButtonAlt,
        closingEmail_SendEmailButtonLabel
    };

    @wire(getRecord, { recordId: Id, fields: [UserNameFIELD, userEmailFIELD ]}) 
    currentUserInfo({error, data}) {
        if (data) {
            this.currentUserName = data.fields.Name.value;
            this.currentUserEmail = data.fields.Email.value;

            this.initComponent();
        } else if (error) {
            console.log('got an error loading user infos: ' + error);
            this.error = error ;
        }
    }

    get hasShowOption() {
        return this.showBcc == undefined || this.showCc == undefined;
    }

    get ccStyle() {
        if (this.showBcc == undefined) {
            return "float: left;";
        } else {
            return "";
        }
    }

    get hasNoPreviousGroup() {
        let hasPrevious = new Number(this.currentGroupIndex) >= 1;
        return !hasPrevious;
    }

    get hasNoNextGroup() {
        let hasNext = new Number(this.currentGroupIndex) < (this.emailsProcess.size - 1);
        return !hasNext;
    }

    // connectedCallback() {
    initComponent() {
        console.log('defaulte template: ' + this.label.closingEmail_defaultFolder);
        if (this.recordIds !== undefined) {
            this.recordIds = JSON.parse(this.recordIds);
            this.recordIndex = 0;
    
            this.getRecordsInfoAndGroups();
        }

        this.isLoading = true;
        getTemplateFolders()
        .then(result => {
            this.templateFolderOptions = [];
            let tempList = [];
            let jsonResults = JSON.parse(result);
            // let selectedFolderId;
            jsonResults.forEach(folder => {
                let item = {};
                item.label = folder.Name;
                item.value = folder.Id;
                console.log('compare fld name: ' + folder.Name + ' with default fld name: ' + this.label.closingEmail_defaultFolder);
                if (this.label.closingEmail_defaultFolder && folder.Name === this.label.closingEmail_defaultFolder) {
                    this.selectedFolderId = folder.Id;
                    this.selectedFolderName = folder.Name;
                    console.log('set option as selected');
                    item.selected = true;
                }
                tempList.push(item);
            });

            this.templateFolderOptions = tempList;

            if (this.selectedFolderId) {
                console.log('load templates from default folder');
                this.loadTemplateFolderTemplates(this.selectedFolderId);
            }
            this.isLoading = undefined;
        })
        .catch(error => {
            console.log('error:' + error);
            this.isLoading = undefined;
        });
    }

    handleToEmail(event) {
        let emailProcMapKey = Array.from(this.emailsProcess.keys())[this.currentGroupIndex];
        let emailProc = this.emailsProcess.get(emailProcMapKey);
        emailProc.toEmails = event.target.value;
        this.emailsProcess.set(emailProcMapKey, emailProc);
    }

    handleCcEmail(event) {
        let emailProcMapKey = Array.from(this.emailsProcess.keys())[this.currentGroupIndex];
        let emailProc = this.emailsProcess.get(emailProcMapKey);
        emailProc.ccEmails = event.target.value;
        this.emailsProcess.set(emailProcMapKey, emailProc);
    }

    handleBccEmail(event) {
        let emailProcMapKey = Array.from(this.emailsProcess.keys())[this.currentGroupIndex];
        let emailProc = this.emailsProcess.get(emailProcMapKey);
        emailProc.bccEmails = event.target.value;
        this.emailsProcess.set(emailProcMapKey, emailProc);
    }

    showCcZone() {
        this.showCc = true;
    }

    showBccZone() {
        this.showBcc = true;
    }

    handleTemplateFolderChange(event) {
        let folderId = event.target.value;

        this.loadTemplateFolderTemplates(folderId);
    }

    loadTemplateFolderTemplates(folderId) {
        this.isLoading = true;
        getEmailTemplates({folderId: folderId})
        .then(result =>{
            let jsonResults = JSON.parse(result);

            this.templateOptions = [];
            this.templates = new Map();
            let tempOptions = [];
            jsonResults.forEach(template => {
                this.templates.set(template.Id, template);
                let item = {};
                item.label = template.Name;
                item.value = template.Id;
                tempOptions.push(item);
            })

            this.templateOptions = tempOptions;
            this.isLoading = undefined;
        })
        .catch(error => {
            console.log(error);
            this.isLoading = undefined;
        });
    }

    handleTemplateChange(event) {
        this.selectedTemplateId = event.target.value;

        if (this.currentGroupIndex !== undefined) {
            this.loadEmailData();
        }
    }

    loadEmailData() {
        let emailProcMapKey = Array.from(this.emailsProcess.keys())[this.currentGroupIndex];
        let emailProc = this.emailsProcess.get(emailProcMapKey);
        if (this.selectedTemplateId !== undefined && (emailProc.templateId == undefined || emailProc.templateId !== this.selectedTemplateId)) {
            console.log('loadEmail with templateId: ' + this.selectedTemplateId);
            console.log('   recordIds: ' + emailProc.recordIds);
            emailProc.templateId = this.selectedTemplateId;

            this.isLoading = true;
            getTemplatePreview({templateId: this.selectedTemplateId, recordIds: JSON.stringify(emailProc.recordIds)})
            .then(result => {
                console.log('apex template preview gives');
                console.log(result);
                let jsonResult = JSON.parse(result);

                this.emailSubjectValue = jsonResult.subject.replace(/\n/g, "<br>");
                this.emailBodyValue = jsonResult.body.replace(/\n/g, "<br>");

                emailProc.body = this.emailBodyValue;
                emailProc.subject = this.emailSubjectValue;
                
                this.emailsProcess.set(emailProcMapKey, emailProc);
                this.isLoading = undefined;
            })
            .catch(error => {
                console.log('error on loadEmailData');
                console.log(error);
                this.isLoading = undefined;
            });
        } else {
            this.emailBodyValue = emailProc.body;
            this.emailSubjectValue = emailProc.subject;
        }
    }

    handleSubjectChange(event) {
        let emailProcMapKey = Array.from(this.emailsProcess.keys())[this.currentGroupIndex];
        let emailProc = this.emailsProcess.get(emailProcMapKey);
        emailProc.subject = event.target.value;
        this.emailsProcess.set(emailProcMapKey, emailProc);
    }

    handleContentChange(event) {
        let emailProcMapKey = Array.from(this.emailsProcess.keys())[this.currentGroupIndex];
        let emailProc = this.emailsProcess.get(emailProcMapKey);
        emailProc.body = event.target.value;
        this.emailsProcess.set(emailProcMapKey, emailProc);
    }

    getRecordsInfoAndGroups() {
        let fields = 'Id, Name';
        if (this.toEmailApiFieldName) {
            fields = fields + ', ' + this.toEmailApiFieldName;
        }
        if (this.ccEmailApiFieldName) {
            fields = fields + ', ' + this.ccEmailApiFieldName;
        }
        if (this.bccEmailApiFieldName) {
            fields = fields + ', ' + this.bccEmailApiFieldName;
        }
        if (this.groupRecordsByApiFieldName && fields.indexOf(this.groupRecordsByApiFieldName) == -1) {
            fields = fields + ', ' + this.groupRecordsByApiFieldName;
        }
        this.isLoading = true;
        getRecordsInfo({recordApiName: this.recordApiName, recordIds: JSON.stringify(this.recordIds), fieldNames: fields})
        .then(result => {
            let jsonResult = JSON.parse(result);

            jsonResult.forEach(item => {
                let mapKey = item.Id;
                if (this.groupRecordsByApiFieldName !== undefined) {
                    mapKey = item[this.groupRecordsByApiFieldName];
                }
                if (!this.emailsProcess.has(mapKey)) {
                    let processItem = {};
                    processItem.send = true;
                    processItem.recordIds = [];
                    processItem.recordNames = [];
                    processItem.fromEmail = this.currentUserEmail;
                    processItem.toEmails = '';
                    processItem.ccEmails = this.currentUserEmail;
                    processItem.bccEmails = '';

                    this.emailsProcess.set(mapKey, processItem);
                }

                let processItem = this.emailsProcess.get(mapKey);
                processItem.recordIds.push(item.Id);
                processItem.recordNames.push(item.Name);

                let itemTo = item[this.toEmailApiFieldName];
                if (this.toEmailApiFieldName && itemTo) {
                    if (processItem.toEmails && processItem.toEmails.length > 0) {
                        if (processItem.toEmails.indexOf(itemTo) == -1) {
                            processItem.toEmails += ', ' + itemTo;
                        }
                    } else {
                        processItem.toEmails = itemTo;
                    }
                }
                this.emailsProcess.set(mapKey, processItem);
            });

            this.currentGroupIndex = 0;
            this.setPreviewFor(this.currentGroupIndex);
            this.loadEmailData();
            this.isLoading = undefined;
        })
        .catch(error => {
            console.log(error);
            this.isLoading = undefined;
        });
    }

    getFilesForOppty(selected) {
        let emailProcMapKey = Array.from(this.emailsProcess.keys())[this.currentGroupIndex];
        let emailProc = this.emailsProcess.get(emailProcMapKey);
        console.log('call apex to get files for ');
        console.log(JSON.stringify(emailProc.recordIds));

        this.isLoading = true;
        getQuotesFilesForOppty({recordIds: JSON.stringify(emailProc.recordIds)})
        .then(result => {
            console.log('files for oppty ' + this.currentRecordId);
            console.log(result);
            let jsonResult = JSON.parse(result);

            let firstRecId = emailProc.recordIds[0];
            console.log('try to get struct for record id ' + firstRecId);

            if (jsonResult[0]) {
                this.opptyFilesStruct = jsonResult[0];
                console.log(' found struct');
                console.log(JSON.stringify(this.opptyFilesStruct));
    
                if (this.opptyFilesStruct.Children == undefined) {
                    this.opptyFilesStruct.Children = [];
                }
    
                if (selected == undefined) {
                    selected = '';
                }
                let pickerSelector = this.template.querySelector("c-p2-c_-folder-and-files-picker");
                // console.log('selector:');
                // console.log(pickerSelector);
                if (pickerSelector !== undefined && pickerSelector !== null && this.opptyFilesStruct) {
                    console.log('refresh component');
                    pickerSelector.refreshAndSelect(this.opptyFilesStruct, selected);
                }
            } else {
                console.log('results don\'t have struct for this ID');
            }
            this.isLoading = undefined;
        })
        .catch(error => {
            console.log(error);
            this.isLoading = undefined;
        });
    }

    consumeGenQuoteFile(event) {
        let qId = event.detail.id;
        this.isLoading = true;
        generateQuoteFile({quoteId: qId})
        .then(result => {
            this.opptyFilesStruct = [];
            this.getFilesForOppty(result);
        })
        .catch(error => {
            console.log(error);
        });
    }

    handleSendChange(event) {
        if (this.currentGroupSend) {
            this.currentGroupSend = undefined;
        } else {
            this.currentGroupSend = true;
        }
        let emailProcMapKey = Array.from(this.emailsProcess.keys())[this.currentGroupIndex];
        let emailProc = this.emailsProcess.get(emailProcMapKey);
        emailProc.send = this.currentGroupSend;
        this.emailsProcess.set(emailProcMapKey, emailProc);
    }

    handleRemoveAttachment(event){
        let emailProcMapKey = Array.from(this.emailsProcess.keys())[this.currentGroupIndex];
        let emailProc = this.emailsProcess.get(emailProcMapKey);
        emailProc.attachmentName = undefined;
        emailProc.attachmentId = undefined;
        this.emailsProcess.set(emailProcMapKey, emailProc);

        this.attachedFileId = undefined;
        this.attachedFileName = undefined;
    }

    handleAttachFile(event){
        console.log('attach file to current email group');
        let emailProcMapKey = Array.from(this.emailsProcess.keys())[this.currentGroupIndex];
        let emailProc = this.emailsProcess.get(emailProcMapKey);
        emailProc.attachmentId = event.detail.id;
        emailProc.attachmentName = event.detail.name;
        this.emailsProcess.set(emailProcMapKey, emailProc);

        console.log('preview set of attachment id/name');
        console.log(emailProc.attachmentId + ' / ' + emailProc.attachmentName);

        this.attachedFileId = emailProc.attachmentId;
        this.attachedFileName = emailProc.attachmentName;
    }

    handleNextGroup(event) {
        if (new Number(this.currentGroupIndex) < (this.emailsProcess.size - 1)) {
            this.currentGroupIndex ++;
            this.setPreviewFor(this.currentGroupIndex);
            this.loadEmailData();
        }
    }

    handlePreviousGroup(event){
        if (new Number(this.currentGroupIndex) >= 1) {
            this.currentGroupIndex --;
            this.setPreviewFor(this.currentGroupIndex);
            this.loadEmailData();
        }
    }

    setPreviewFor(groupIndex) {
        console.log('preview for group index ' + groupIndex);
        let emailProcMapKey = Array.from(this.emailsProcess.keys())[groupIndex];
        let emailProc = this.emailsProcess.get(emailProcMapKey);
        this.emailBodyValue = emailProc.body;
        this.emailSubjectValue = emailProc.subject;
        this.emailFrom = emailProc.fromEmail;
        this.emailTo = emailProc.toEmails;
        this.emailCc = emailProc.ccEmails;
        this.emailBcc = emailProc.bccEmails;
        this.currentGroupSend = emailProc.send;
        this.attachedFileId = emailProc.attachmentId;
        this.attachedFileName = emailProc.attachmentName;
        this.currentGroupName = emailProc.recordNames.join(", ");

        if (this.groupRecordsByApiFieldName == undefined) {
            this.getFilesForOppty(this.attachedFileName);
        }
    }

    // @api
    // validate() {
    //     console.log('Validate called, prcs: ');
    //     this.sendEmails();
    //     return { isValid: true };
    // }

    async sendEmails() {
        let procs = [];
        let allRecordIds = [];
        Array.from(this.emailsProcess.values()).forEach(proc => {
            allRecordIds.push(...proc.recordIds);
            if (proc.toEmails && proc.toEmails.length > 0) {
                procs.push(proc);
            } else {
                console.log("won't send email for oppty " + proc.recordNames);
            }
        });
        // console.log(JSON.stringify(procs));

        sendEmails({jsonEmailData: JSON.stringify(procs)})
        .then(result => {
            let jsonResult = JSON.parse(result);
            this.successRecordIds = [];
            jsonResult.forEach(res => {
                this.successRecordIds.push(res);
            });

            this.failedRecordIds = [];
            allRecordIds.forEach(recId => {
                if (!this.successRecordIds.includes(recId)) this.failedRecordIds.push(recId);
            });
            // console.log('succesfuly sent on records: ' + result);
            // console.log('   success res: ' + JSON.stringify(this.successRecordIds));
            // console.log('   failed res: ' + JSON.stringify(this.failedRecordIds));

            setTimeout(() => {
                const attributeChangeEvent = new FlowAttributeChangeEvent(
                    'successRecordIds',
                    this.successRecordIds
                );
                this.dispatchEvent(attributeChangeEvent);
            }, 1);
            setTimeout(() => {
                const attributeChangeEventFail = new FlowAttributeChangeEvent(
                    'failedRecordIds',
                    this.failedRecordIds
                );
                this.dispatchEvent(attributeChangeEventFail);
            }, 1);

            setTimeout(() => {
                const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent);
            }, 1);
        })
        .catch(error => {
            console.log(error);
        });
    }
}