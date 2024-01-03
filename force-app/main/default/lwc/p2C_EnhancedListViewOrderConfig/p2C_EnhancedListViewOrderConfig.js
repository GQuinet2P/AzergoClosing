import { LightningElement, api, track } from 'lwc';
import orderEditorTitle from '@salesforce/label/c.enhancedListview_orderEditorTitle';
import addOrder from '@salesforce/label/c.enhancedListview_orderAddButton';
import moveUpOrder from '@salesforce/label/c.enhancedListview_moveUpButton';
import moveDownOrder from '@salesforce/label/c.enhancedListview_moveDownButton';
import removeOrder from '@salesforce/label/c.enhancedListview_removeButton';
import selectFieldHolder from '@salesforce/label/c.enhancedListview_fieldPlaceHolder';
import selectConditionHolder from '@salesforce/label/c.enhancedListview_conditionPlaceHolder';
import conditionLabel from '@salesforce/label/c.enhancedListview_conditionLabel';
import fieldLabel from '@salesforce/label/c.enhancedListview_fieldLabel';

export default class P2C_EnhancedListViewOrderConfig extends LightningElement {

    @api describedFields;
    @api objectApiName;
    @api posX;
    @api posY;
    @api orders;
    @track isLoading = true;
    
    //orderby edition fields
    @track selectedFieldName = 'Id';
    @track selectedCondition;
    @track value;
    
    label = {
        orderEditorTitle,
        addOrder,
        moveDownOrder,
        moveUpOrder,
        removeOrder,
        selectFieldHolder,
        selectConditionHolder,
        conditionLabel,
        fieldLabel
    }

    queryOrders;
    newOrders;
    conditionOptions = [
        {label: "Asc", value: "ASC"},
        {label: "Desc", value: "DESC"}
    ]

    connectedCallback() {
        let tempOpts = [];
        this.describedFields.forEach(desc => {
            tempOpts.push({label: desc.label, value: desc.value});
        });
        this.describedFields = tempOpts;
        let tmpOrders = [];
        if (this.orders && this.orders.length > 0) {
            this.orders.forEach(orderItem => {
                let tmpOrder = {fieldName: orderItem.fieldName, direction: orderItem.direction, directionIcon: orderItem.directionIcon, sortOrder: orderItem.sortOrder, label: orderItem.label, fieldLabel: orderItem.fieldLabel};
                tmpOrders.push(tmpOrder);
            });
            tmpOrders[0].isFirst = true;
            tmpOrders[tmpOrders.length - 1].isLast = true;
            this.orders = tmpOrders;
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

        this.dispatchEvent(new CustomEvent('closeorderedit', {
            detail: {
                filters: this.filters,
                queryFilters: this.queryFilters
            }
        }));
    }

    get boxClass() { 
        return `position: fixed; z-index: 9100; background-color:white; top:${this.posY}px; left:${this.posX}px;width: 700px;`;
        // return `position: fixed; z-index: 9100; background-color:white; top:${this.posY}px; left:${this.posX}px;width: 800px;`;
    }

    handleChangeField(event) {
        this.selectedFieldName = event.target.value;
    }

    handleChangeOption(event) {
        this.selectedCondition = event.target.value;
    }

    handleMoveUp(event) {
        let sord = event.currentTarget.parentNode.getAttribute("data-id");
        let tempOrders = [...this.orders];
        let toMove = this.orders.at(sord);
        
        tempOrders.splice(sord, 1);
        tempOrders.splice(sord - 1, 0, toMove);

        let newOrder = 0;
        tempOrders.forEach(ordItem => {
            ordItem.sortOrder = newOrder
            ordItem.showDown = undefined;
            ordItem.showUp = undefined;
            newOrder++;
            if (ordItem.sortOrder > 0) ordItem.showUp = true;
            if (ordItem.sortOrder < this.orders.length - 1) ordItem.showDown = true;
        });
        this.newOrders = tempOrders;

        this.buildQueryAndRefresh();
    }

    handleMoveDown(event) {
        let sord = event.currentTarget.parentNode.getAttribute("data-id");
        let tempOrders = [...this.orders];
        let toMove = this.orders.at(sord);
        
        tempOrders.splice(sord, 1);
        tempOrders.splice(sord + 1, 0, toMove);

        let newOrder = 0;
        tempOrders.forEach(ordItem => {
            ordItem.sortOrder = newOrder
            ordItem.showDown = undefined;
            ordItem.showUp = undefined;
            newOrder++;
            if (ordItem.sortOrder > 0) ordItem.showUp = true;
            if (ordItem.sortOrder < this.orders.length - 1) ordItem.showDown = true;
        });
        this.newOrders = tempOrders;

        this.buildQueryAndRefresh();
    }

    handleRemove(event) {
        let sord = event.currentTarget.parentNode.getAttribute("data-id");
        let tempOrders = [...this.orders];
        
        tempOrders.splice(sord, 1);

        let newOrder = 0;
        tempOrders.forEach(ordItem => {
            ordItem.sortOrder = newOrder
            ordItem.showDown = undefined;
            ordItem.showUp = undefined;
            newOrder++;
            if (ordItem.sortOrder > 0) ordItem.showUp = true;
            if (ordItem.sortOrder < this.orders.length - 1) ordItem.showDown = true;
        });
        this.newOrders = tempOrders;

        this.buildQueryAndRefresh();
    }

    handleChangeDirection(event) {
        let sord = event.currentTarget.getAttribute("data-id");
        this.newOrders = [...this.orders];

        let updOrder = this.newOrders.at(sord);
        let otherDir = updOrder.direction;
        if (otherDir.toLowerCase() === 'asc') {
            otherDir = 'DESC';
        }else {
            otherDir = 'ASC';
        }
        updOrder.direction = otherDir;
        updOrder.label = updOrder.fieldName + ' ' + updOrder.direction;
        this.newOrders.splice(sord, 1, updOrder);

        this.buildQueryAndRefresh();
    }

    handleChangeOrderDirection(event) {
        let sord = event.detail.orderChange;
        this.newOrders = [...this.orders];

        let updOrder = this.newOrders.at(sord);
        let otherDir = updOrder.direction;
        if (otherDir.toLowerCase() === 'asc') {
            otherDir = 'DESC';
        }else {
            otherDir = 'ASC';
        }
        updOrder.direction = otherDir;
        updOrder.label = updOrder.fieldName + ' ' + updOrder.direction;
        this.newOrders.splice(sord, 1, updOrder);

        this.buildQueryAndRefresh();
    }

    handleAddOrderBy(event) {
        if (this.selectedFieldName) {
        // if (this.selectedFieldName && this.selectedCondition) {
            let soqlfilter = this.selectedFieldName + ' ASC';
            // let soqlfilter = this.selectedFieldName + ' ' + this.selectedCondition;
            if (this.orders) this.newOrders = [...this.orders];
            if (this.newOrders == undefined) this.newOrders = [];
            let newSortOrder = 0;
            if (this.orders && this.orders.length > 0) {
                let lastOrder = this.orders.at(this.orders.length - 1);
                newSortOrder = lastOrder.sortOrder + 1;
            }

            const isSameField = (fld) => {
                if (fld.fieldName === this.selectedFieldName) return true;
            }
            let matchIndex = this.newOrders.findIndex(isSameField);

            if (matchIndex > -1) {
                let updOrder = this.newOrders.at(matchIndex);
                updOrder.direction = 'ASC';
                // updOrder.direction = this.selectedCondition;
                updOrder.label = soqlfilter;
                this.newOrders.splice(matchIndex, 1, updOrder);
            } else {
                let fieldDesc = this.describedFields.find((fldDef) => fldDef.value == this.selectedFieldName);
                let orderItem = {fieldName: this.selectedFieldName, direction: 'ASC', label: soqlfilter, sortOrder: newSortOrder};
                // let orderItem = {fieldName: this.selectedFieldName, direction: this.selectedCondition, label: soqlfilter, sortOrder: newSortOrder};
                if (fieldDesc) {
                    orderItem.fieldLabel = fieldDesc.label;
                } else {
                    orderItem.fieldLabel = this.selectedFieldName;
                }

                if (orderItem.sortOrder > 0) orderItem.showUp = true;
                if (orderItem.sortOrder < this.orders.length - 1) orderItem.showDown = true;

                this.newOrders.push(orderItem);
            }

            this.buildQueryAndRefresh();
        }
    }

    handleDrop(event) {
        console.log('drop');
        console.log(JSON.stringify(event.detail));
    }

    handleDragStart(event) {
        console.log('drag');
        console.log(JSON.stringify(event.detail));
    }

    buildQueryAndRefresh() {
        if (this.newOrders && this.newOrders.length > 0) {
            this.queryOrders = ' ORDER BY ';
            this.newOrders.forEach(filt => {
                this.queryOrders += filt.label + ', ';
            });
            if (this.queryOrders.lastIndexOf(', ') > 0) {
                this.queryOrders = this.queryOrders.substring(0, this.queryOrders.lastIndexOf(', '));
            }
        }

        // console.log('fire event updorderby');
        this.dispatchEvent(new CustomEvent('updateorderby', {
            detail: {
                fieldOrders: this.newOrders,
                queryOrders: this.queryOrders
            }
        }));
    }
}