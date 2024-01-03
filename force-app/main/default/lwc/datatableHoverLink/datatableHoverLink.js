import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class DatatableHoverLink extends NavigationMixin(LightningElement) {

    @api lookupId;
    @api lookupRecordApiName;
    @api lookupFieldToDisplay;
    // @api label;
    @api value;
    @api editedValue;
    @api context;
    @api contextName;
    @api fieldName;
    // @api name;
    @api fireHoverEvents;
    @api popupWidth;
    @api popupAlign;
    
    @track linkUrl;

    get actualValue() {
        if (this.editedValue) {
            return this.editedValue;
        } else {
            if (this.lookupFieldToDisplay) {
                return this.lookupFieldToDisplay;
            }
            return this.value;
        }
    }
    
    connectedCallback() {
        this.linkUrl = '/' + this.context;
    }

    navigateToUrl() {
        // Navigate to the Account home page
        let objId = this.context;
        if (this.lookupId) objId = this.lookupId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: objId,
                actionName: 'view',
            },
        });
    }

    handleChange(event) {
        console.log('cellchange');
        //show the selected value on UI
        // this.editedValue = event.detail.value;
        this.value = event.detail.value;
    }

    handleMouseOverLink(event){
        if (this.fireHoverEvents) {
            const rect = event.target.getBoundingClientRect();
            const y = rect.y + rect.height;
            const x = rect.x;

            this.dispatchEvent(new CustomEvent('showdetailpopup', {
                composed: true,
                bubbles: true,
                detail: {
                    fieldName: this.fieldName,
                    objectApiName: this.lookupRecordApiName,
                    recordId: this.context,
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