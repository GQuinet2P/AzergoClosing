import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

export default class DatatableLookupEdit extends LightningElement {

    @api editedValue;
    @api fieldName;
    @api lookupFieldToDisplay;
    @api lookupRecordApiName;
    @api allowEdit;
    @api context;
    @api contextName;

    @track editMode;
    @track cellLookupInputId;

    fields;

    @wire(getRecord, {
        recordId: "$editedValue",
        fields: "$fields",
        optionalFields: [],
    })
    editRecord;

    // get actualValue() {
    //     if (this.editedValue) {
    //         return this.editedValue;
    //     } else {
    //         if (this.lookupFieldToDisplay) {
    //             return this.lookupFieldToDisplay;
    //         }
    //         return this.value;
    //     }
    // }

    get fieldValue() {
        console.log('edit? ' + this.editedValue);
        console.log('record? ' + this.record);
        if (this.editedValue) return getFieldValue(this.editRecord.data, this.fields[0]);
        return this.editedValue;
    }

    handleSelect(event) {
        console.log('selected value: ' + event.detail);
        this.editedValue = event.detail;

        let draftValue = {};
        draftValue[this.contextName] = typeof(this.context) == 'number' ? this.context.toString() : this.context;
        draftValue[this.fieldName] = this.value;
        // draftValue[this.fieldName] = this.editedValue;
        let draftValues = [];
        draftValues.push(draftValue);

        //fire event to send context and selected value to the data table
        this.dispatchEvent(new CustomEvent('cellchange', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                draftValues: draftValues
            }
        }));

        this.editMode = undefined;
    }

    connectedCallback() {
        console.log('')
        this.fields = [];
        this.fields.push(this.lookupRecordApiName + '.' + this.lookupFieldToDisplay);
        this.cellLookupInputId = 'lookupInput' + this.lookupFieldToDisplay + '-' + this.context;
        console.log('recid: ' + this.editedValue);
        console.log('recfld: ' + this.fields);
        console.log('recfldnam: ' + this.fieldName);
    }

}