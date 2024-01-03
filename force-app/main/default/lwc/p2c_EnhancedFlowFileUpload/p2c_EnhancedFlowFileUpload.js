import { api, LightningElement, track } from 'lwc';
import createFileAndLinks from '@salesforce/apex/P2C_EnhancedFileUpload.createFileAndLinks';
import EnhancedFileUpload_FileLabel from '@salesforce/label/c.EnhancedFileUpload_FileLabel';
import EnhancedFileUpload_SuccessMsg from '@salesforce/label/c.EnhancedFileUpload_SuccessMsg';
import EnhancedFileUpload_Loader from '@salesforce/label/c.EnhancedFileUpload_Loader';


export default class P2c_EnhancedFlowFileUpload extends LightningElement {
    @api RelatedRecordIds;
    @api AllowMultipleUpload;
    @api FileUploadLabel;

    error;

    @track successMessage;
    @track errorMessage;
    @track loading;
    @track targetObjectName;
    @track numberOfRecordsToCreate = 0;
    @track progress = 100;
    @track loaderTitle;

    jsonData = [];
    fileData = {};

    label = {
        EnhancedFileUpload_FileLabel,
        EnhancedFileUpload_SuccessMsg,
        EnhancedFileUpload_Loader
    };

    renderedCallback() {
    }

    connectedCallback() {
    }

    openfileUpload(event) {
        console.log('onFileUpload start');
        this.successMessage = undefined;
        this.errorMessage = undefined;
        const file = event.target.files[0]
        var reader = new FileReader()
        reader.onload = function(e) {
            this.fileData.fileName = file.name;
            this.fileData.fileType = file.type;
            let contentResult = reader.result;
            const base64 = 'base64,';
            const i = contentResult.indexOf(base64) + base64.length;
            this.fileData.fileDataB64 = contentResult.substring(i);

            let ldr = this.label.EnhancedFileUpload_Loader;
            this.loaderTitle = ldr;
            this.loading = true;

            console.log('xlsdata:');
            this.createRecords();
        }.bind(this);

        reader.onerror = function(ex) {
            console.log(ex);
            this.errorMessage = ex;
        };

        reader.readAsDataURL(file);
    }

    createRecords() {
        console.log(this.fileData);

        createFileAndLinks({jsonRelatedRecordIds: this.RelatedRecordIds, jsonData: JSON.stringify(this.fileData)})
        .then(result => {
            let jsonResult = JSON.parse(result);
        })
        .catch(error => {
            console.log('got error from apex');
            console.log(error);
            this.error = error;
            this.errorMessage = error.body.message;

            this.loading = undefined;
        });
    }    
}
