import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { RefreshEvent } from 'lightning/refresh';
import searchRecords from '@salesforce/apex/P2C_CustomLookupInputFieldController.searchRecords';
const DELAY = 10;

export default class DatatableLookup extends NavigationMixin(LightningElement) {

    @api value;
    // @api editedValue;
    @api fieldName;
    @api lookupFieldToDisplay;
    @api lookupRecordApiName;
    @api allowEdit;
    @api context;
    @api contextName;
    @api fireHoverEvents;
    @api popupWidth = 800;
    @api popupAlign = 'Left';

    @track editMode;
    @track linkUrl;
    @track applyToAll;

    fields;

    dataInputId = 'lookupsearch';
    @track selectValue;
    @track searchResults;

    handleApplyToAll(event) {
        if (event.target.checked) {
            this.applyToAll = true;
        } else {
            this.applyToAll = undefined;
        }
    }

    handleKey(event) {
        if (event.key === "Escape" || event.key === "Esc" || event.keyCode === 27) {
            this.searchVal = undefined;
            this.editMode = undefined;
        }
    }

    handleClickOutside() {
        this.handleBlur();
    }

    handleBlur(event) {
        if (this.searchVal) this.searchVal = undefined;
        if (this.editMode) this.editMode = undefined;
    }
    
    handleSearch(event) {
        window.clearTimeout(this.delayTimeout);
        var searchVal = event.target.value;
        if (searchVal.length < 2) {
            return;
        }

        this.delayTimeout = setTimeout(() => {
            searchRecords({
                objectApiName   : this.lookupRecordApiName,
                fieldApiName : this.lookupFieldToDisplay,
                searchKey : searchVal
            })
            .then( data => {
                if ( data ) {
                    this.searchResults = [];
                    let parsedResponse = JSON.parse(data);
                    let searchRecordList = parsedResponse[0];
                    for ( let i=0; i < searchRecordList.length; i++ ) {
                        let record = searchRecordList[i];
                        record.Name = record[this.lookupFieldToDisplay];
                    }
                    this.searchResults = searchRecordList;
                }
            })
            .catch( error => {
                window.console.log(' error ', error);
            });
        }, DELAY);
    }

    get searchPlaceHolder() {
        return 'Select a contact';
    }

    @wire(getRecord, {
        recordId: "$value",
        fields: "$fields",
        optionalFields: [],
    })
    record;

    get fieldValue() {
        if (this.record) return getFieldValue(this.record.data, this.fields[0]);
        return this.value;
    }

    get editPopupStyle() {
        let lookupSelector = this.template.querySelector('div[data-id="datatableLookup"]');
        const rect = lookupSelector.getBoundingClientRect();
        const editY = rect.y;
        let editX = rect.x;

        if ((rect.x + 300) > (window.innerWidth - 29)) {
            let posx = (rect.x + 300) - (window.innerWidth - 29);
            editX = rect.x - posx;
        }
        return 'z-index: 9100; background-color: white; margin-top: 1px; display: block; position: fixed; width: 300px; left: ' + editX + 'px; right: auto; top: ' + editY + 'px;'
    }

    handleSelect(event) {
        this.value = event.currentTarget.dataset.itemid;

        let draftValue = {};
        draftValue[this.contextName] = typeof(this.context) == 'number' ? this.context.toString() : this.context;
        draftValue[this.fieldName] = this.value;
        let draftValues = [];
        draftValues.push(draftValue);

        //fire event to send context and selected value to the data table
        this.dispatchEvent(new CustomEvent('cellchange', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                applyToAll: this.applyToAll,
                draftValues: draftValues,
                recordId: this.value,
                fieldName: this.fieldName,
                context: this.context
            }
        }));
        
        this.searchResults = undefined;
        this.editMode = undefined;
        this.applyToAll = undefined;
        
        //Dispatch the refresh event
        this.dispatchEvent(new RefreshEvent());
    }

    handleSwitchMode(event) {
        if (this.editMode) {
            this.editMode = undefined;
        } else {
            this.editMode = true;
        }
    }

    connectedCallback() {
        this.fields = [];
        this.fields.push(this.lookupRecordApiName + '.' + this.lookupFieldToDisplay);
        this.linkUrl = '/' + this.value;
    }

    navigateToUrl() {
        // Navigate to the Account home page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.value,
                actionName: 'view',
            },
        });
    }

    handleMouseOverLink(event){
        if (this.fireHoverEvents) {
            let targetId = this.value;

            const rect = event.target.getBoundingClientRect();
            const y = rect.y + rect.height;
            const x = rect.x;

            this.dispatchEvent(new CustomEvent('showdetailpopup', {
                composed: true,
                bubbles: true,
                detail: {
                    fieldName: this.fieldName,
                    objectApiName: this.lookupRecordApiName,
                    recordId: targetId,
                    context: this.context,
                    popupWidth: this.popupWidth,
                    popupAlign: this.popupAlign,
                    posX: x,
                    posY: y
                }
            }));
        }
    }

    handleMouseOutLink() {
        if (this.fireHoverEvents) {
            let objId = this.context;
            if (this.lookupId) objId = this.lookupId;
            this.dispatchEvent(new CustomEvent('hidedetailpopup', {
                composed: true,
                bubbles: true,
                detail: {
                    fieldName: this.fieldName,
                    recordId: objId
                }
            }));
        }
    }
}
