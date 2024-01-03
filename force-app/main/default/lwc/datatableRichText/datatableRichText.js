import { LightningElement, api } from 'lwc';

export default class DatatableRichText extends LightningElement {

    @api value;
    @api context;
    @api recordApiName;
    @api fieldName;

    @api fireHoverEvents;
    @api popupWidth;
    @api popupAlign;


    handleMouseOverLink(event){
        // console.log('span mouseover');
        // console.log('fire? ' + this.fireHoverEvents);
        if (this.fireHoverEvents) {
            const rect = event.target.getBoundingClientRect();
            const y = rect.y + rect.height;
            const x = rect.x;

            this.dispatchEvent(new CustomEvent('showdetailpopup', {
                composed: true,
                bubbles: true,
                detail: {
                    fieldName: this.fieldName,
                    objectApiName: this.recordApiName,
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
            this.dispatchEvent(new CustomEvent('hidedetailpopup', {
                composed: true,
                bubbles: true,
                detail: {
                    fieldName: this.fieldName,
                    recordId: this.context
                }
            }));
        }
    }    
}