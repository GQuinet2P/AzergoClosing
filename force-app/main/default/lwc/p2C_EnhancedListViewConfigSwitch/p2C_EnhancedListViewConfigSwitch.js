import { LightningElement, api } from 'lwc';

export default class P2C_EnhancedListViewConfigSwitch extends LightningElement {

    @api stdListviewsOptions;
    @api selectedValue;
    @api posX;
    @api posY;

    get boxClass() { 
        return `position: fixed; z-index: 9100; background-color:white; top:${this.posY}px; left:${this.posX}px;width: 400px;`;
    }

    get lvOptionsClass() {
        if (this.stdListviewsOptions) {
            return 'slds-dropdown slds-dropdown_length-' + this.stdListviewsOptions.length.toString() + ' slds-dropdown_fluid';
        } else {
            return 'slds-dropdown slds-dropdown_fluid';
        }
    }

    handleKey(event) {
        if (event.key === "Escape" || event.key === "Esc" || event.keyCode === 27) {
            this.fireCloseAction();
        }
    }

    handleClickOutside() {
        this.fireCloseAction();
    }

    fireCloseAction() {
        this.selectedCondition = undefined;
        this.selectedFieldName = undefined;
        this.value = undefined;

        this.dispatchEvent(new CustomEvent('closefilteredit', {
            detail: {
                close: true
            }
        }));
    }

    handleSwitchConfig(event) {
        console.log('switch config to');
        let cnfId = String(event.detail.value);
        // let cnfId = String(event.target.id);
        if (cnfId.indexOf('-') > 0) cnfId = cnfId.substring(0, cnfId.indexOf('-'));

        console.log('fire event updfilt');
        this.dispatchEvent(new CustomEvent('switchlistview', {
            detail: {
                configId: cnfId
            }
        }));
    }

}