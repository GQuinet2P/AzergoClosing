import { LightningElement, api, track } from 'lwc';
import filterEditorTitle from '@salesforce/label/c.enhancedListview_filterEditorTitle';

export default class P2C_EnhancedListViewFiltersConfig extends LightningElement {

    @api describedFields;
    @api objectApiName;
    @api posX;
    @api posY;
    @api filters;
    @api filtersLogic;
    @track isLoading = true;

    @track filtersGroups = [];
    @track filterLogic;
    
        //filter edition fields
    @track selectedFieldName = 'Id';
    @track selectedCondition;
    @track value;
    
    label = {
        filterEditorTitle
    }

    queryFilters;
    newFilters;
    conditionOptions = [
        {label: "Equals", value: "= '{value}'"},
        {label: "Not equals", value: "<> '{value}'"},
        {label: "Not contains", value: "not like '%{value}%'"},
        {label: "Contains", value: "like '%{value}%'"},
        {label: "Starts with", value: "like '{value}%'"},
        {label: "Ends with", value: "like '%{value}'"},
        {label: "In", value: "in ({value})"},
        {label: "Greater than", value: "> {value}"},
        {label: "Less than", value: "< {value}"}
    ]

    connectedCallback() {
        let tempOpts = [];
        this.describedFields.forEach(desc => {
            tempOpts.push({label: desc.label, value: desc.value});
        });
        this.describedFields = tempOpts;
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
                filters: this.filters,
                queryFilters: this.queryFilters
            }
        }));
    }

    get boxClass() { 
        return `position: fixed; z-index: 9100; background-color:white; top:${this.posY}px; left:${this.posX}px;width: 300px; height: 500px; overflow-x: hidden; overflow-y: scroll;`;
    }

    handleChangeField(event) {
        console.log('fldpick: ' + event.target.value);
        this.selectedFieldName = event.target.value;
    }

    handleChangeOption(event) {
        this.selectedCondition = event.target.value;
    }

    handelChangeValue(event) {
        this.value = event.target.value;
    }

    handleAddFilter(event) {
        if (this.selectedFieldName && this.selectedCondition && this.value) {
            let soqlfilter = this.selectedFieldName + ' ' + this.selectedCondition.replace('{value}', this.value);
            if (this.filters) this.newFilters = [...this.filters];
            if (this.newFilters == undefined) this.newFilters = [];

            if (this.newFilters.find((filt) => filt.fieldName === this.selectedFieldName)) {
                //TODO Add confirm update
            }

            let fieldDesc = this.describedFields.find((fldDef) => fldDef.value == this.selectedFieldName);
            let filterItem = {fieldName: this.selectedFieldName, condition: this.selectedCondition, value: this.value, label: soqlfilter};
            if (fieldDesc) {
                filterItem.fieldLabel = fieldDesc.label;
            } else {
                filterItem.fieldLabel = this.selectedFieldName;
            }
            this.newFilters.push(filterItem);

            if (this.newFilters && this.newFilters.length > 0) {
                this.queryFilters = ' WHERE ';
                this.newFilters.forEach(filt => {
                    this.queryFilters += filt.label + ' AND ';
                });
                if (this.queryFilters.lastIndexOf(' AND ') > 0) {
                    this.queryFilters = this.queryFilters.substring(0, this.queryFilters.lastIndexOf(' AND '));
                }
            }

            console.log('fire event updfilt');
            this.dispatchEvent(new CustomEvent('updatefilters', {
                detail: {
                    filters: this.newFilters,
                    queryFilters: this.queryFilters
                }
            }));
        }
    }
}