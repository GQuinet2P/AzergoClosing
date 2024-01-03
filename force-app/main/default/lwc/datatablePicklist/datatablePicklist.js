import { LightningElement, api, track } from 'lwc';
import { RefreshEvent } from 'lightning/refresh';

export default class DatatablePicklist extends LightningElement {

    @api label;
    @api placeholder;
    @api options;
    @api value;
    @api editedValue;
    @api context;
    @api contextName;
    @api fieldName;
    @api allowEdit;

    @api
    get reset() {
        return this.value;
    }
    set reset(value) {
        if (this.baseValue) this.value = this.baseValue;
    }

    @track baseValue;
    @track editMode;
    @track applyToAll;

    get updatedValue(){
        if (this.editedValue) return this.editedValue;
        return this.value;
    };

    get editPopupStyle() {
        let lookupSelector = this.template.querySelector('div[data-id="datatablePicklist"]');
        const rect = lookupSelector.getBoundingClientRect();
        const editY = rect.y;
        const editX = rect.x;
        // const editY = rect.top  + window.scrollY;
        // const editX = rect.left + window.scrollX;
        return 'z-index: 9100; background-color: white; margin-top: 1px; display: block; position: fixed; left: ' + editX + 'px; right: auto; top: ' + editY + 'px;'
    }

    handleSwitchMode() {
        if (this.editMode) {
            this.editMode = undefined;
        } else {
            this.editMode = true;
            setTimeout(()=>this.template.querySelector('lightning-combobox').focus());
        }
    }

    handleKey(event) {
        if (event.key === "Escape" || event.key === "Esc" || event.keyCode === 27) {
            this.searchVal = undefined;
            this.editMode = undefined;
        }
    }

    handleClickOutside() {
        if (this.editMode) this.editMode = undefined;
    }

    connectedCallback() {
        this.baseValue = this.value;
        // if (this.options) {
        //     console.log('got options');
        //     console.log(JSON.stringify(this.options));
        //     let listKey = Object.keys(this.options);
        //     let finalOptions = [];
        //     listKey.forEach(key => {
        //         console.log('convert ' + this.options[key]);
        //         let opt = {};
        //         opt.label = this.options[key].label;
        //         opt.value = this.options[key].value;
        //         opt.key = this.context + opt.value;
        //         finalOptions.push(opt);
        //     })
        //     this.options = finalOptions;
        // } else {
        //     console.log('got no options');
        //     this.options = [];
        // }
    }

    handleApplyToAll(event) {
        if (event.target.checked) {
            this.applyToAll = true;
        } else {
            this.applyToAll = undefined;
        }
    }

    handleChange(event) {
        console.log('cellchange');
        //show the selected value on UI
        this.value = event.detail.value;
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
                fieldName: this.fieldName,
                draftValues: draftValues
            }
        }));
        this.editMode = undefined;
        this.applyToAll = undefined;

        //Dispatch the refresh event
        this.dispatchEvent(new RefreshEvent());
    }

    @api
    resetField(row, field){
        if (this.context === row && this.contextName === field) {
            console.log('reset this.value');
            this.value = this.baseValue;
        }
    }
}