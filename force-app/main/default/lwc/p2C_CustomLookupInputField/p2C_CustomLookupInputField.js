import { LightningElement, api, track } from 'lwc';
import searchRecords from '@salesforce/apex/P2C_CustomLookupInputFieldController.searchRecords';
const DELAY = 10;

export default class P2C_CustomLookupInputField extends LightningElement {

    @api objectapiname;
    @api fieldapiname;
    @api label;
    @api value;
    @api isrequired;
    @api isdisabled;
    
    @track dataInputId;
    @track selectValue;
    @track records = [];
    @track isOpen = false;
    @track isOpening = false;
    @track hasEventListener = false;
    @track searchPlaceHolder;
    @track showLabel = undefined;
    @track variant;

    delayTimeout;
    validity = true;
    valid = true;
    
    connectedCallback() {
        // console.log('lookup field loaded');
        this.searchPlaceHolder = 'Search ' + this.objectapiname + '...';
        if (this.label !== undefined && this.label.length > 0) {
            this.showLabel = true;
            this.variant = 'label-stacked';
        } else {
            this.variant = 'label-hidden';
        }

        if (this.value !== undefined && this.value.length > 0) {
            // console.log('init value selected: ' + this.value);
            this.selectValue = this.value;
        } else {
            console.log('no value passed from master component');
        }
        if (this.dataInputId === undefined) this.dataInputId = "saerchinput";
        
        this.startClickOutsideEventListener();
    }

    handleKeyUp(event) {
        event.preventDefault();
    }

    handleSearch(event) {
        event.preventDefault();

        // console.log('launch search...');
        window.clearTimeout(this.delayTimeout);
        var searchVal = event.detail.value;
        if (searchVal.length < 2) {
            return;
        }

        this.delayTimeout = setTimeout(() => {
            searchRecords({
                objectApiName   : this.objectapiname,
                fieldApiName : this.fieldapiname,
                searchKey : searchVal
            })
            .then( data => {
                if ( data ) {
                    this.records = [];
                    let parsedResponse = JSON.parse(data);
                    let searchRecordList = parsedResponse[0];
                    for ( let i=0; i < searchRecordList.length; i++ ) {
                        let record = searchRecordList[i];
                        record.Name = record[this.fieldapiname];
                    }
                    //window.console.log(' data ', searchRecordList);
                    this.records = searchRecordList;
                }
            })
            .catch( error => {
                window.console.log(' error ', error);
            });
        }, DELAY);
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
        // console.log('lookupcomponent sel value');
        // console.log(JSON.stringify(event.currentTarget.dataset));
        let selectedValue = event.currentTarget.dataset.value;
        let selectedLabel = event.currentTarget.dataset.label;

        this.isOpen = false;
        this.selectValue = selectedLabel;

        const inpfield = this.template.querySelector('lightning-input[data-id="' + this.dataInputId + '"]');
        // inpfield.value = "";
        inpfield.value = selectedLabel;

        const resultValue = "" + selectedValue;
        const searchFieldEvent = new CustomEvent("getselectedlookupvalue", {
            detail: resultValue
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

    startClickOutsideEventListener(event) {
        // console.log('Start mouse click listener');
        const current = this;
        
        if (this.hasEventListener !== true) {
            this.hasEventListener = true;
            document.addEventListener('mouseup', function(e) {
                if (current.isOpening !== true && current.isOpen === true && current.clickFromList !== true) {
                    // console.log('     -> close');
                    current.closeList();
                }
                current.clickFromList = false;
                current.isOpening = false;
            });
        }
    }

    closeList() {
        // console.log(' .  cl');
        this.isOpen = false;
        this.clickFromList = false;
    }

    handleFocus(event) {
        event.target.className = event.target.className.replace('slds-has-error', '');
        // console.log('got focus');
        this.isFocussed = true;
        this.isOpen = true;
        this.isOpening = true;
    }

}