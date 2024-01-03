import { LightningElement, api, track } from 'lwc';

export default class P2C_ExtandedDatatablePopover extends LightningElement {

    _emptyIndex = 0;
    @api columns;
    @api recordid;
    @api top = 50;
    @api left = 50;
    @api popupwidth;
    @api popupalign;
    @api layout;
    @api recordapiname;

    @track isLoading = true;
    

    get uniqueIndex() {
        let millis = +new Date();
        return millis;
    }

    handleLoaded(event) {
        this.isLoading = undefined;
    }

    connectedCallback() {
        console.log('popover with ' + this.popupwidth + ' size');
    }

    getEmptyIndex() {
        let millis = +new Date();
        return millis;
    }

    get boxClass() { 
        if (this.popupwidth == undefined) {
            return `position: fixed; z-index: 9999; background-color:white; top:${this.top}px; left:${this.left}px;`;
        } else {
            return `position: fixed; z-index: 9999; background-color:white; top:${this.top}px; left:${this.left}px;width: ${this.popupwidth}px;`;
        }
    }    

    get columnClass() {
        if (this.layout) {
            return "slds-col size_1-of-" + this.columns.length;
        } else {
            return "slds-col";
        }
    }

}