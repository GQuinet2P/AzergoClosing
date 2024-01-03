import { LightningElement, api, track } from 'lwc';
import searchRecords from '@salesforce/apex/P2C_CustomLookupInputFieldController.searchRecords';

export default class P2C_CustomMultiLookupInputField extends LightningElement {

    @api objectapiname;
    @api fieldapiname;
    @api label;
    @api value;
    @api isrequired;
    @api isdisabled;
    @api iconname;
    @api selectionfieldapiname;
    
    @track selectedRecords = [];
    @track records = [];
    @track isOpen = false;
    @track isOpening = false;
    @track hasEventListener = false;
    @track searchPlaceHolder;
    @track showLabel = undefined;
    @track variant;

    
    connectedCallback() {
        this.searchPlaceHolder = 'Search ' + this.objectapiname + '...';
        if (this.iconname === undefined && this.objectapiname !== undefined) {
            this.iconname = 'standard:' + this.objectapiname.toLowerCase();
        }
        if (this.label !== undefined && this.label.length > 0) {
            this.showLabel = true;
            this.variant = 'label-stacked';
        } else {
            this.variant = 'label-hidden';
        }
        this.startClickOutsideEventListener();
    }

    handleSearch(event) {
        var searchVal = event.detail.value;
        if (searchVal.length < 2) {
            return;
        }

        let fieldNames = this.fieldapiname;
        if (this.selectionfieldapiname !== undefined) {
            fieldNames = fieldNames + ', ' + this.selectionfieldapiname;
        }
        searchRecords({
            objectApiName   : this.objectapiname,
            fieldApiName : fieldNames,
            searchKey : searchVal
        })
        .then( data => {
            if ( data ) {
                // this.records = [];
                this.records.length = 0;
                let parsedResponse = JSON.parse(data);
                let searchRecordList = parsedResponse[0];
                for ( let i=0; i < searchRecordList.length; i++ ) {
                      let record = searchRecordList[i];
                      record.Name = record[this.fieldapiname];
                      if (this.selectionfieldapiname !== undefined) {
                        record.Name = record.Name + '<' + record[this.selectionfieldapiname] + '>';
                    }
                }
                this.records = searchRecordList;

                console.log(JSON.stringify(this.records));
            }
        })
        .catch( error => {
            window.console.log(' error ', error);
        });
    }

    get noOptions() {
        return this.records.length === 0;
    }

    get dropdownClasses() {
        let dropdownClasses = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        
        if (this.isOpen) {
            dropdownClasses += ' slds-is-open';
        }

        return dropdownClasses;
    }

    handleSelectOption(event) {
        let selectedValue = event.currentTarget.dataset.value;
        let selectedLabel = event.currentTarget.dataset.label;

        let record = {};
        this.isOpen = false;
        record.label = selectedLabel;
        record.value = selectedValue;
        this.selectedRecords.push(record);

        this.publishSelectionToParent();
    }
    
    publishSelectionToParent() {
        const searchFieldEvent = new CustomEvent("getselectedlookupvalue", {
            detail: this.selectedRecords
        });
    
        try {
            this.dispatchEvent(searchFieldEvent);
        } catch (error) {
            console.log('failed to dispatch lookup result');
            console.log(error);
        }
    }

    handleListClick(event) {
        this.clickFromList = true;
    }

    handleKeyPress(event) {
        if(event.keyCode === 13){
            const newEmail = this.template.querySelector('lightning-input[data-id="searchinput"]');

            let record = {};
            this.isOpen = false;
            record.label = newEmail.value;
            record.value = newEmail.value;
            this.selectedRecords.push(record);
            // this.template.querySelector('lightning-input[data-id="searchinput]"').value = undefined;

            this.publishSelectionToParent();
        }
    }

    // @api
    // addRecordToSelection(record) {
    //     console.log('add new record to selection from parent component');
    //     this.isOpen = false;
    //     this.selectedRecords.push(record);

    //     this.publishSelectionToParent();
    // }

    @api
    setSelectedRecords(records) {
        console.log('set selection from parent component');
        this.isOpen = false;
        this.selectedRecords.length = 0;
        // this.selectedRecords.push(...records);
        records.forEach(rec => {
            let record = {};
            record.label = rec.label;
            record.value = rec.value;
            this.selectedRecords.push(record);
        });

        // this.publishSelectionToParent();
    }

    // @api
    // clearSelected() {
    //     console.log('parent requestes to clear selection');
    //     this.selectedRecords.length = 0;
    //     this.records.length = 0;
    //     // this.template.querySelector('lightning-input[data-id="searchinput]"').reset();
    //     // this.template.querySelector('lightning-input[data-id="searchinput]"').value = undefined;
    // }

    startClickOutsideEventListener(event) {
        const current = this;
        
        if (this.hasEventListener !== true) {
            this.hasEventListener = true;
            document.addEventListener('mouseup', function(e) {
                if (current.isOpening !== true && current.isOpen === true && current.clickFromList !== true) {
                    console.log('     -> close');
                    current.closeList();
                }
                current.clickFromList = false;
                current.isOpening = false;
            });
        }
    }

    closeList() {
        this.isOpen = false;
        this.clickFromList = false;
    }

    handleFocus() {
        this.isFocussed = true;
        this.isOpen = true;
        this.isOpening = true;
    }

    removeRecord(event) {
        let selectedRecs = [];
        for(let i = 0; i < this.selectedRecords.length; i++){
            if(event.detail.name !== this.selectedRecords[i].value)
            selectedRecs.push(this.selectedRecords[i]);
        }
        this.selectedRecords.length = 0;
        this.selectedRecords.push(...selectedRecs);

        const searchFieldEvent = new CustomEvent("getselectedlookupvalue", {
            detail: this.selectedRecords
        });

        try {
            this.dispatchEvent(searchFieldEvent);
        } catch (error) {
            console.log('failed to dispatch lookup result');
            console.log(error);
        }
    }
}