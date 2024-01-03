import { LightningElement, api, track } from 'lwc';
import executeQuery from '@salesforce/apex/P2C_EnhancedListView.executeQuery';
import executeQueryCount from '@salesforce/apex/P2C_EnhancedListView.executeQueryCount';
import getObjectInfoFromApiName from '@salesforce/apex/P2C_EnhancedListView.getObjectInfoFromApiName';
import getObjectFieldsNamesSorted from '@salesforce/apex/P2C_EnhancedListView.getObjectFieldsNamesSorted';
import getListviewConfig from '@salesforce/apex/P2C_EnhancedListView.getListviewConfig';
import getListview from '@salesforce/apex/P2C_EnhancedListView.getListview';
import pinUnpinListview from '@salesforce/apex/P2C_EnhancedListView.pinUnpinListview';
import updateUserPrefListviewSorters from '@salesforce/apex/P2C_EnhancedListView.updateUserPrefListviewSorters';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import { loadStyle } from 'lightning/platformResourceLoader';
import HideLWCAppHeader from '@salesforce/resourceUrl/HideLWCAppHeader';
import results from '@salesforce/label/c.enhancedListview_results';
import selected from '@salesforce/label/c.enhancedListview_selected';
import cancelRowUpdate from '@salesforce/label/c.enhancedListview_cancelRowUpdate';
import errorMessageSuffix from '@salesforce/label/c.enhancedListview_errorMessageSuffix';
import errorMessageTitle from '@salesforce/label/c.enhancedListview_errorMessageTitle';
import successMessageTitle from '@salesforce/label/c.enhancedListview_successMessageTitle';
import successMessageSuffix from '@salesforce/label/c.enhancedListview_successMessageSuffix';
import saveButton from '@salesforce/label/c.enhancedListview_saveButton';
import saveButtonAlt from '@salesforce/label/c.enhancedListview_saveButtonAlt';
import cancelButton from '@salesforce/label/c.enhancedListview_cancelButton';
import cancelButtonAlt from '@salesforce/label/c.enhancedListview_cancelButtonAlt';
import loading from '@salesforce/label/c.enhancedListview_loading';
import pinListview from '@salesforce/label/c.enhancedListview_pinListview';
import unpinListview from '@salesforce/label/c.enhancedListview_unpinListview';
import switchListview from '@salesforce/label/c.enhancedListview_switchListview';
import closeButton from '@salesforce/label/c.enhancedListview_closeButton';
import configureOrder from '@salesforce/label/c.enhancedListview_configureOrder';
import configureFilters from '@salesforce/label/c.enhancedListview_configureFilters';
import refreshList from '@salesforce/label/c.enhancedListview_refreshList';
import settings from '@salesforce/label/c.enhancedListview_settings';
import searchInputHolder from '@salesforce/label/c.enhancedListview_searchInputHoldeer';
import activeOrdersLabel from '@salesforce/label/c.enhancedListview_activeSortersLabel';
import additionalOrdersLabel from '@salesforce/label/c.enhancedListview_additionalOrdersLabel';
import additionalOrdersTooltip from '@salesforce/label/c.enhancedListview_additionalOrdersTooltip';

export default class P2C_EnhancedListView extends LightningElement {

    @api listviewConfigName;
    
    @track objectApiName;
    @track objectLabel;
    @track fieldFilters;
    @track fieldFiltersLogic;
    @track fieldOrders;
    @track availableFieldOrders;
    @track defaultFieldOrders;
    @track listviewsSorters;
    
    //filter edition fields
    @track selectedPickerFieldName;
    @track selectedPickerCondition;
    @track pickerValue;
    
    @track listContent;
    @track unfilteredListContent;
    @track columns = [];
    @track sortDirection;
    
    @track showAddFilter;
    @track filterspopupX;
    @track filterspopupY;
    @track filterFieldOptions;
    
    @track showAddOrderBy;
    @track orderspopupX;
    @track orderspopupY;
    @track orderFieldOptions;
    
    @track rowDetailId;
	@track rowDetailLeft;
	@track rowDetailTop;
	@track rowDetailWidth;
	@track rowDetailAlign;
	@track rowDetailColumns;
    @track showRowDetails;
    @track rowDetailObjectApiName;
    @track selectedRowCount;
    @track selectedRows;
    
    @track listPageSize;
    @track listRowsIndex;
    @track listItemsCount;
    @track listItemsCountTotal;
    @track listviewTitle;
    @track listviewIcon;
    @track listviewCardTitle;
    @track listviewCardIcon;

    @track showSwitchListview;
    @track stdListviewsOptions;
    @track lvSwitchpopupX;
    @track lvSwitchpopupY;

    @track isLoading;
    @track isPinnedListview;
    @track showChangeActionBar;

    itemOrderDragged;

    selectedListviewConfig;
    stdListviews = new Map();
    picklistOptions = new Map();
    columnDetailsLayouts = new Map();
    describedFields = [];
    listviewConfig;
    masterListviewConfig;
    pinnedListviewConfig;
    actionOptions;
    draftValues;
    rowActions = [
        { label: cancelRowUpdate, name: "resetDraft", iconName: 'utility:refresh' },
        // { label: "Enregistrer la ligne", name: "saveRowDraft", iconName: 'utility:save' }
    ]
    queryFields;
    queryObject;
    queryFilters;
    queryOrders;
    queryScope;
    flowStart;
    flowApiName;

    get lvOptionsClass() {
        if (this.stdListviewsOptions) {
            return 'slds-dropdown slds-dropdown_length-' + this.stdListviewsOptions.length.toString() + ' slds-dropdown_fluid';
        } else {
            return 'slds-dropdown slds-dropdown_fluid';
        }
    }

    get lvTableContainerClass() {
        let containreSelector = this.template.querySelector('div[data-id="extendedDatatableContainer"]');
        const rect = containreSelector.getBoundingClientRect();
        let tableHeight = window.innerHeight - rect.y - 30;
        if (this.showChangeActionBar) tableHeight = tableHeight - 40;
        return "height: " + tableHeight + "px;"
    }

    label = {
        results,
        selected,
        cancelRowUpdate,
        errorMessageSuffix,
        errorMessageTitle,
        successMessageSuffix,
        successMessageTitle,
        cancelButton,
        cancelButtonAlt,
        saveButton,
        saveButtonAlt,
        loading,
        pinListview,
        unpinListview,
        switchListview,
        closeButton,
        configureOrder,
        configureFilters,
        refreshList,
        settings,
        searchInputHolder,
        activeOrdersLabel,
        additionalOrdersLabel,
        additionalOrdersTooltip
    };

    connectedCallback() {
        loadStyle(this, HideLWCAppHeader);
        this.draftValues = [];
        if (this.listviewConfigName !== undefined) {
            this.isLoading = true;
            getListviewConfig({configName: this.listviewConfigName})
            .then(config => {
                this.listviewConfig = JSON.parse(config);
                this.listviewTitle = this.listviewConfig.listviewTitle;
                this.listviewIcon = this.listviewConfig.listviewIcon;
                this.selectedListviewConfig = this.listviewConfig.configId;
                this.masterListviewConfig = this.listviewConfig.configId;
                this.listPageSize = this.listviewConfig.rowsPerPage;
                this.defaultFieldOrders = this.listviewConfig.defaultSorters;
                this.listviewsSorters = this.listviewConfig.listviewsSorters;
                this.listRowsIndex = 0;

                getObjectInfoFromApiName({objectApiName: this.listviewConfig.objectApiName})
                .then(infos=>{
                    let jsonNfo = JSON.parse(infos);
                    this.objectApiName = jsonNfo.value;
                    this.objectLabel = jsonNfo.label;
                    this.listviewCardTitle = this.listviewConfigName;
                    this.listviewCardIcon = 'standard:' + this.objectApiName.toLowerCase();
    
                    getObjectFieldsNamesSorted({objectApiName: this.listviewConfig.objectApiName})
                    .then(fields=>{
                        this.describedFields = JSON.parse(fields);
                        this.picklistOptions = new Map();
                        this.filterFieldOptions = [];

                        this.describedFields.forEach(describe => {
                            if (describe.type == 'picklist' && describe.restrictedValues) {
                                let fieldChoices = [];
                                describe.restrictedValues.forEach(restrictedValue => {
                                    let choice = {
                                        label: restrictedValue.label,
                                        value: restrictedValue.value
                                        // name: restrictedValue.value
                                    };
                                    fieldChoices.push(choice);
                                });
                                this.picklistOptions.set(describe.value, fieldChoices);
                            }
                            let fieldOption = {label: describe.label, value: describe.value};
                            this.filterFieldOptions.push(fieldOption);
                        });

                        getListview({objectApiName: this.listviewConfig.objectApiName, masterConfigId: this.listviewConfig.configId})
                        .then(result => {
                            let sdtLvs = JSON.parse(result);
                            this.stdListviewsOptions = undefined;
                            let tempLvOptions = [];

                            let listviewConfig = {value: this.listviewConfig.configId, label: this.listviewConfig.configName};
                            tempLvOptions.push(listviewConfig);
                            this.stdListviews.set(this.listviewConfig.configId, this.listviewConfig);

                            if (sdtLvs && sdtLvs.length > 0) {
                                this.stdListviewsOptions = [];
                                sdtLvs.forEach(stdLv => {
                                    this.stdListviews.set(stdLv.configId, stdLv);
                                    tempLvOptions.push({value: stdLv.configId, label: stdLv.configName});
                                })
                            }
                            if (tempLvOptions.length > 0) this.stdListviewsOptions = tempLvOptions;

                            if (this.listviewConfig.userPrefs) { 
                                if (this.listviewConfig.userPrefs.rowsPerPage) {
                                    this.listPageSize = this.listviewConfig.userPrefs.rowsPerPage;
                                }
                                if (this.listviewConfig.userPrefs.pinnedListviewId) {
                                    if (this.stdListviews.has(this.listviewConfig.userPrefs.pinnedListviewId)) {
                                        this.pinnedListviewConfig = this.listviewConfig.userPrefs.pinnedListviewId;
                                        this.selectedListviewConfig = this.listviewConfig.userPrefs.pinnedListviewId;
                                        this.isPinnedListview = true;
                                    }
                                }
                                if (this.listviewConfig.userPrefs.defaultSorters) {
                                    this.defaultFieldOrders = this.listviewConfig.userPrefs.defaultSorters;
                                    this.listviewsSorters = this.listviewConfig.userPrefs.listviewsSorters;
                                }
                            }
                            this.initComponent();
                        })
                        .catch(error => {
                            console.log(error);
                        });
                        // console.log('final fieldsoptions:');
                        // console.log(this.picklistOptions);
                    })
                    .catch(error => {
                        this.isLoading = undefined;
                        console.log(error);
                    });
                })
                .catch(error => {
                    this.isLoading = undefined;
                    console.log(error);
                });
            })
            .catch(error=> {
                this.isLoading = undefined;
                console.log(error);
            });
        }
    }
    
    initComponent() {
        let fields = 'Id, Name';
        let where = '';
        let orderby = '';
        this.queryScope = ' USING SCOPE everything ';

        if (this.stdListviews.has(this.selectedListviewConfig) && this.listviewConfig.configName !== this.selectedListviewConfig) {
            // console.log('init component to config ' + this.selectedListviewConfig);
            this.listviewConfig = this.stdListviews.get(this.selectedListviewConfig);
            this.listviewConfigName = this.listviewConfig.configName;
            this.listviewCardTitle = this.listviewConfigName;
            this.selectedRows = undefined;
            this.selectedRowCount = undefined;
        }
    
        this.queryObject = this.listviewConfig.objectApiName;
        if (this.listviewConfig.scope) {
            this.queryScope = ' USING SCOPE ' + this.listviewConfig.scope + ' ';
        }
        if (this.listviewConfig.defaultFields !== undefined && this.listviewConfig.defaultFields.length > 0) {
            this.columns = [];
            let newCols = [];

            this.listviewConfig.defaultFields.forEach(field => {
                if (fields.indexOf(field.fieldApiName) == -1) {
                    fields += ', ' + field.fieldApiName;
                }
                if (field.isLinkToRecord) {
                    if (field.fieldApiName.endsWith('__c') && field.lookupFieldToDisplay) {
                        let lookupfld = ', ' + field.fieldApiName.substring(0,field.fieldApiName.length - 1) + 'r.' + field.lookupFieldToDisplay;
                        // fields += ', ' + field.fieldApiName.substring(0,field.fieldApiName.length - 1) + 'r.';
                        if (fields.indexOf(lookupfld) == -1) {
                            fields += lookupfld;
                        }
                    }
                    if (field.fieldApiName.endsWith('Id') && field.lookupFieldToDisplay) {
                        let lookupfld = ', ' + field.fieldApiName.substring(0,field.fieldApiName.length - 2) + '.' + field.lookupFieldToDisplay;
                        if (fields.indexOf(lookupfld) == -1) {
                            fields += lookupfld;
                        }
                    }
                } else if (field.lookupFieldToDisplay && fields.indexOf(field.lookupFieldToDisplay) == -1) {
                    fields += ', ' + field.lookupFieldToDisplay;
                }

                let match = this.describedFields.find((fldDef) => fldDef.value == field.fieldApiName);
                
                let canEdit = field.isEditable;

                if (match) {
                    let tableLabel = match.label;
                    if (field.fieldColumnLabel !== undefined && field.fieldColumnLabel.length > 0) {
                        tableLabel = field.fieldColumnLabel;
                    }
                    let column;
                    // column.hideDefaultActions = true;
                    if (match.type == 'picklist') {
                        let fieldOptions = [];
                        this.picklistOptions.get(match.value).forEach(option => {
                            fieldOptions.push({label: option.label, value: option.value});
                        });

                        column = {
                            label: match.label, 
                            fieldName: match.value, 
                            type: 'picklistColumn',
                            // cellAttributes: { alignment: 'right' },
                            typeAttributes: {
                                label: tableLabel,
                                fieldName: match.value,
                                placeholder: 'Select ' + tableLabel, 
                                options: fieldOptions, 
                                value: { fieldName: match.value }, // default value for picklist,
                                contextName: 'Id',
                                context: { fieldName: 'Id' }
                            }
                        };
                        if (canEdit) {
                            // column.editable = true;
                            column.typeAttributes.allowEdit = true;
                        }
                    } else if (match.type == 'richtext') {
                        // console.log('field ' + field.label + ' is richtext');
                        column = {
                            label: tableLabel, 
                            fieldName: match.value, 
                            type: 'richTextColumn', 
                            typeAttributes: {
                                label: match.value,
                                value: { fieldName: match.value },
                                context: { fieldName: 'Id' },
                                contextName: 'Id',
                                fieldName: match.value,
                                popupAlign: 'left',
                                popupWidth: 800,
                                recordApiName: this.queryObject
                            }, 
                            dataMassSelection: false
                            // sortable: true
                        };
                        if (canEdit) {
                            column.editable = true;
                        }
                        if (field.linkHoverShowDetails) {
                            // console.log('hover lookup');
                            // console.log('got ' + field.popupWidth + ' for width');
                            if (field.popupAlign) column.typeAttributes.popupAlign = field.popupAlign;
                            if (field.popupWidth) column.typeAttributes.popupWidth = field.popupWidth;
                            column.typeAttributes.fireHoverEvents = true;
                            if (!this.columnDetailsLayouts.has(match.value)) {
                                this.columnDetailsLayouts.set(match.value, JSON.parse(field.showDetailsLayout));
                            }
                        }
                    } else if (match.type == 'lookup') {
                        // console.log('field ' + field.label + ' is lookup');
                        // console.log ('    hover? ' + field.linkHoverShowDetails);
                        // console.log ('    details? ' + field.showDetailsLayout);
                        let colValue = match.value;
                        if (field.lookupFieldToDisplay) colValue = field.lookupFieldToDisplay;
                        column = {
                            label: tableLabel,
                            fieldName: match.value, 
                            type: 'lookupColumn', 
                            // cellAttributes: {
                            //     alignment: 'right',
                            //     // class: 'slds-cell-edit slds-truncate slds-grid_align-end',
                            // },
                            typeAttributes: {
                                value: { fieldName: field.fieldApiName },
                                lookupFieldToDisplay: field.lookupFieldToDisplay,
                                lookupRecordApiName: match.referenceTargets[0].value,
                                context: { fieldName: 'Id' },
                                contextName: 'Id',
                                fieldName: match.value,
                                popupAlign: 'left',
                                popupWidth: 800
                            }, 
                            // cellAttributes: { alignment: 'right' }, 
                            // sortable: true
                        };
                        if (field.linkHoverShowDetails) {
                            if (field.popupAlign) column.typeAttributes.popupAlign = field.popupAlign;
                            if (field.popupWidth) column.typeAttributes.popupWidth = field.popupWidth;

                            column.typeAttributes.fireHoverEvents = true;
                            if (!this.columnDetailsLayouts.has(match.value)) {
                                this.columnDetailsLayouts.set(match.value, JSON.parse(field.showDetailsLayout));
                            }
                        }
                        if (canEdit) {
                            column.typeAttributes.allowEdit = true;
                            // column.editable = true;
                        }
                    } else {
                        if (field.isLinkToRecord) {
                            console.log('lookup hover to ' + this.queryObject);
                            column = {
                                label: tableLabel, 
                                fieldName: match.value, 
                                type: 'hoverLinkColumn', 
                                typeAttributes: {
                                    label: match.value,
                                    value: { fieldName: match.value },
                                    lookupRecordApiName: this.queryObject,
                                    context: { fieldName: 'Id' },
                                    contextName: 'Id',
                                    fieldName: match.value,
                                    popupAlign: 'left',
                                    popupWidth: 800
                                }, 
                                // sortable: true
                            };
                            if (field.linkHoverShowDetails) {
                                // console.log('hover lookup');
                                // console.log('got ' + field.popupWidth + ' for width');
                                if (field.popupAlign) column.typeAttributes.popupAlign = field.popupAlign;
                                if (field.popupWidth) column.typeAttributes.popupWidth = field.popupWidth;
                                column.typeAttributes.fireHoverEvents = true;
                                if (!this.columnDetailsLayouts.has(match.value)) {
                                    this.columnDetailsLayouts.set(match.value, JSON.parse(field.showDetailsLayout));
                                }
                            }
                        } else {
                            column = {label: tableLabel, fieldName: match.value, type: match.type}; //wrapText: true, sortable: true
                        }
                        
                        if (canEdit) {
                            column.editable = true;
                        }
                    }
                    // column.sortable = true;
                    // column.sortDirection = 'desc';
                    column.sortable = false;

                    newCols.push(column);
                } else {
                    let column = {label: field.fieldColumnLabel, fieldName: field.fieldApiName, type: 'text'}; //, sortable: true
                    if (canEdit) {
                        column.editable = true;
                    }
                    newCols.push(column);
                }
            });
            // newCols.push({ type: 'action', typeAttributes: {rowActions: this.getRowActions} });
            newCols.push({ type: 'action', typeAttributes: {rowActions: this.rowActions} });
            this.queryFields = fields;
            this.columns = newCols;
        }
        if (this.listviewConfig.defaultFilters !== undefined && this.listviewConfig.defaultFilters.length > 0) {
            this.fieldFilters = [];
            this.fieldFiltersLogic = undefined;
            let bldWhere = this.buildRecusriveWhere(this.listviewConfig.defaultFilters, '', 0);
            where = bldWhere.where;

            this.queryFilters = where;
        } else {
            where = '';
            this.queryFilters = undefined;
            this.fieldFilters = undefined;
        }

        //manage listview sorting
        // get default sort fields if any defined in configuration
        // if none defined, get any order specified in the listview if any
        let orderSorters;
        if (this.defaultFieldOrders != undefined && this.defaultFieldOrders != null && this.defaultFieldOrders.length > 0)
            orderSorters = this.defaultFieldOrders;
        if ((orderSorters == undefined || orderSorters.length == 0 || orderSorters == null) && this.listviewConfig.defaultSorters !== undefined && this.listviewConfig.defaultSorters.length > 0)
            orderSorters = this.listviewConfig.defaultSorters;
        if (this.listviewsSorters !== undefined && this.listviewsSorters != null && this.listviewsSorters.length > 0) {
            let lvSortersIdx = this.listviewsSorters.findIndex((lvSorters) => String(lvSorters.listviewId) == String(this.selectedListviewConfig));
            if (lvSortersIdx >= 0) orderSorters = this.listviewsSorters.at(lvSortersIdx).listviewSorters;
        }

        // build the effective sort fields list and prepare available sort fields
        if (orderSorters !== undefined && orderSorters.length > 0) {
            this.fieldOrders = [];
            this.availableFieldOrders = [];
            orderby = ' ORDER BY ';

            let tempOrders = [];
            orderSorters.forEach(sorter => {
                orderby += sorter.soqlValue + ' ';
                let fieldDesc = this.describedFields.find((fldDef) => fldDef.value == sorter.fieldApiName);
                let orderItem = {fieldName: sorter.fieldApiName, direction: sorter.direction, sortOrder: sorter.sortOrder, label: sorter.soqlValue};
                if (fieldDesc) {
                    orderItem.fieldLabel = fieldDesc.label;
                } else {
                    orderItem.fieldLabel = sorter.fieldApiName;
                }
                if (sorter.direction.toLowerCase() === 'asc') {
                    orderItem.directionIcon = 'utility:arrowup';
                } else {
                    orderItem.directionIcon = 'utility:arrowdown';
                }
                orderby += ', ';
                tempOrders.push(orderItem);
                // this.fieldOrders.push(orderItem);
            })
            tempOrders.at(0).isFirst = true;
            tempOrders.at(tempOrders.length - 1).isLast = true;
            this.fieldOrders = tempOrders

            if (orderby.lastIndexOf(', ') > 1) {
                orderby = orderby.substring(0, orderby.lastIndexOf(', '));
            }
            this.queryOrders = orderby;
        } else {
            this.fieldOrders = undefined;
        }

        //add shown fields in table to the available sort field list if some are missing
        let lastOrder;
        if (this.availableFieldOrders != undefined && this.availableFieldOrders.length > 0) {
            lastOrder = Number(this.availableFieldOrders.at(this.availableFieldOrders.length - 1).sortOrder) + 1;
        }
        if (lastOrder == undefined) lastOrder = 0;
        this.listviewConfig.defaultFields.forEach(field => {
            let hasMatch = this.availableFieldOrders.find((orderedFld) => orderedFld.fieldName === field.fieldApiName);
            let hasUsed;
            if (this.fieldOrders != null && this.fieldOrders != undefined) hasUsed = this.fieldOrders.find((orderedFld) => orderedFld.fieldName === field.fieldApiName);

            if ((hasMatch == undefined || hasMatch ==  null) && (hasUsed == null || hasUsed == undefined)) {
                let fieldDesc = this.describedFields.find((fldDef) => fldDef.value == field.fieldApiName);
                let soql = field.fieldApiName + ' ASC';
                let orderItem = {fieldName: field.fieldApiName, direction: 'ASC', directionIcon : 'utility:arrowup', sortOrder: lastOrder++, label: soql};
                if (fieldDesc) {
                    orderItem.fieldLabel = fieldDesc.label;
                    if (fieldDesc.isSortable) orderItem.sortable = true;
                } else {
                    orderItem.fieldLabel = field.fieldApiName;
                }
                if (orderItem.sortable) this.availableFieldOrders.unshift(orderItem);
            }

            let newAvailOrder = 0;
            this.availableFieldOrders.forEach(ordItem => {
                ordItem.sortOrder = newAvailOrder
                newAvailOrder++;
            });
        });

        this.refreshTableResults();
    }

    buildRecusriveWhere(filters, where, groupNumber) {
        let needsClosing;
        if (where == undefined || where == '') {
            where = ' WHERE ';
        }

        let prevField = '';
        let prevGrpNumber = 0;
        let prevConjunction;
        filters.forEach(filter => {
            if (filter.soqlValue !== undefined && filter.soqlValue != null) {
                if (prevField != filter.fieldApiName) groupNumber = groupNumber + 1;
                if (prevGrpNumber != groupNumber) {
                    if (this.fieldFiltersLogic == undefined) {
                        this.fieldFiltersLogic = '';
                    }
                    this.fieldFiltersLogic += groupNumber + ' ' + filter.conjunction + ' ';
                    prevGrpNumber = groupNumber;
                }

                if (this.fieldFilters == undefined || this.fieldFilters.length < 1 || this.fieldFilters[this.fieldFilters.length - 1].groupNumber != groupNumber) {
                    let filterGroup = {};
                    filterGroup.filters = [];
                    this.fieldFilters.push(filterGroup);
                }

                prevField = filter.fieldApiName;
                if (this.fieldFilters[this.fieldFilters.length - 1].groupNumber == undefined) this.fieldFilters[this.fieldFilters.length - 1].groupNumber = groupNumber;
                
                let subwhere = filter.soqlValue;
                where += subwhere + ' ' + filter.conjunction + ' ';
    
                let fieldDesc = this.describedFields.find((fldDef) => fldDef.value == filter.fieldApiName);
                let fltValTxt = filter.condition.replace('{value}', filter.value);
                let filterItem = {fieldName: filter.fieldApiName, condition: filter.condition, value: filter.value, valueLabel: fltValTxt, label: filter.soqlValue, conjunction: filter.conjunction, group: groupNumber, filterLevel: groupNumber};
                if (fieldDesc) {
                    filterItem.fieldLabel = fieldDesc.label;
                } else {
                    filterItem.fieldLabel = filter.fieldApiName;
                }
                if (!this.fieldFilters[this.fieldFilters.length - 1].conjunction) this.fieldFilters[this.fieldFilters.length - 1].conjunction = filter.conjunction;

                this.fieldFilters[this.fieldFilters.length - 1].filters.push(filterItem);

                prevConjunction = filter.conjunction;
            }

            if (filter.subFilters) {
                let logicLength = 0;
                if (this.fieldFiltersLogic) logicLength = this.fieldFiltersLogic.length;
                if (prevField != '') this.fieldFiltersLogic += '(';
                if (where.lastIndexOf(' AND ') == where.length - 5) {
                    where += ' (';
                    needsClosing = ' ) AND ';
                }
                if (where.lastIndexOf(' OR ') == where.length - 4) {
                    where += ' (';
                    needsClosing = ' ) OR ';
                }
                let subResult = this.buildRecusriveWhere(filter.subFilters, where, groupNumber);
                where = subResult.where;
                groupNumber = subResult.groupNumber;
                if (prevField != '') {
                    if (this.fieldFiltersLogic.lastIndexOf(' OR ') == this.fieldFiltersLogic.length - 4) {
                        this.fieldFiltersLogic = this.fieldFiltersLogic.substring(0, this.fieldFiltersLogic.lastIndexOf(' OR '));
                    }
                    if (this.fieldFiltersLogic.lastIndexOf(' AND ') == this.fieldFiltersLogic.length - 5) {
                        this.fieldFiltersLogic = this.fieldFiltersLogic.substring(0, this.fieldFiltersLogic.lastIndexOf(' AND '));
                    }

                    if (this.fieldFiltersLogic.lastIndexOf('OR') < logicLength && this.fieldFiltersLogic.lastIndexOf('OR') < logicLength) {
                        this.fieldFiltersLogic = this.fieldFiltersLogic.substring(0, logicLength) + this.fieldFiltersLogic.substring(logicLength + 1, this.fieldFiltersLogic.length);
                    } else {
                        this.fieldFiltersLogic += ')';
                    }
                }
                if (prevConjunction != undefined) this.fieldFiltersLogic += ' ' + prevConjunction + ' ';
            }
            if (needsClosing) {
                where += needsClosing;
                needsClosing = undefined;
            }
        });
        this.fieldFilters.sort( (a,b) => (Number(a.groupNumber) > Number(b.groupNumber)) ? 1 : (Number(b.groupNumber) > Number(a.groupNumber) ? -1 : 0) )
        if (this.fieldFiltersLogic.lastIndexOf(' OR ') == this.fieldFiltersLogic.length - 4) {
            this.fieldFiltersLogic = this.fieldFiltersLogic.substring(0, this.fieldFiltersLogic.lastIndexOf(' OR '));
        }
        if (this.fieldFiltersLogic.lastIndexOf(' AND ') == this.fieldFiltersLogic.length - 5) {
            this.fieldFiltersLogic = this.fieldFiltersLogic.substring(0, this.fieldFiltersLogic.lastIndexOf(' AND '));
        }

        if (where.endsWith(' AND ')) where = where.substring(0, where.lastIndexOf(' AND '));
        if (where.endsWith(' OR ')) where = where.substring(0, where.lastIndexOf(' OR '));
        return {where, groupNumber};
    }

    handleCellChange(event) {
        event.stopPropagation();
        // console.log('onchange event');

        this.showChangeActionBar = true;
        let rowdrafts = event.detail.draftValues;
        let sourceDraft = rowdrafts[0];
        let tableDraft = this.template.querySelector("c-p2-c_-extended-data-table").draftValues;
        let selected = this.template.querySelector("c-p2-c_-extended-data-table").getSelectedRows();

        if (this.selectedRowCount && this.selectedRowCount > 0 && event.detail.applyToAll) {
            selected.forEach(selRow => {
                if (selRow.Id !== sourceDraft.Id) {
                    // const matchDraft = tableDraft.find((cellDraft) => cellDraft.Id === selRow.Id);
                    // console.log('add row ' + selRow.Id + ' drafts');
                    let rowSelDraft = Object.assign({}, sourceDraft);
                    rowSelDraft.Id = selRow.Id;
                    rowdrafts.push(rowSelDraft);

                    selRow[event.detail.fieldName] = sourceDraft[event.detail.fieldName];
                }
            })
        }

        rowdrafts.forEach(rowdraft => {
            const draftIndex = tableDraft.findIndex((cellDraft) => cellDraft.Id === rowdraft.Id);
            if (draftIndex >= 0) {
                tableDraft[draftIndex][event.detail.fieldName] = sourceDraft[event.detail.fieldName];
            } else {
                tableDraft.push(rowdraft);
            }
        })
        this.template.querySelector("c-p2-c_-extended-data-table").draftValues = tableDraft;

        this.draftValues = this.template.querySelector("c-p2-c_-extended-data-table").draftValues;

        //Dispatch the refresh event
        this.dispatchEvent(new RefreshEvent());
    }
    
    loadTableData() {
        // console.log('load data with ' + this.listPageSize + ' rows');
        // console.log('starting at ' + this.listRowsIndex + ' rows');
        this.isLoading = true;
        executeQuery({objectApiName: this.queryObject, fields: this.queryFields, scope: this.queryScope, whereClause: this.queryFilters, orderClause: this.queryOrders, rowNumber: this.listPageSize, startIndex: this.listRowsIndex})
        .then(result => {
            let jsonResult = JSON.parse(result);
            if (this.listContent) {
                let currentContent = this.listContent;
                const newContent = currentContent.concat(jsonResult);
                this.listContent = newContent;
                this.unfilteredListContent = newContent;
            } else {
                this.listContent = jsonResult;
                this.unfilteredListContent = jsonResult;
            }
            this.showAddFilter = undefined;
            this.listItemsCount = this.listContent.length;
            this.isLoading = undefined;
            if (this.currentSearchKey) this.filterTable(this.currentSearchKey);
        })
        .catch(error => {
            this.isLoading = undefined;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.errorMessageTitle,
                    message: this.label.errorMessageSuffix + error,
                    variant: 'error'
                })
            );
            console.log(error);
        });
    }

    handleLoadMoreData() {
        if (this.listItemsCountTotal && (this.listRowsIndex + this.listPageSize) < this.listItemsCountTotal) {
            this.listRowsIndex = this.listRowsIndex + this.listPageSize;
            this.loadTableData();
        }
    }

    handleSearchTable(event) {
        const searchKey = event.target.value.toLowerCase();
        
        if (searchKey) {
            this.currentSearchKey = searchKey;
            this.filterTable(searchKey);
        } else {
            this.currentSearchKey = undefined;
            this.listContent = this.unfilteredListContent;
            this.listItemsCount = this.listContent.length;
        }
    }

    filterTable(searchKey) {
        let tempContent = [];
        for (let record of this.unfilteredListContent) {
            console.log('recd: ' + JSON.stringify(record));
            let valArray = Object.values(record);
            console.log('vals: ' + JSON.stringify(valArray));
            for (let val of valArray) {
                let strVal = String(val);
                if (strVal && strVal.toLocaleLowerCase().includes(searchKey)) {
                    tempContent.push(record);
                    break;
                }
            }
        }

        this.listContent = tempContent;
        this.listItemsCount = this.listContent.length;
    }

    refreshTableResults() {
        this.listRowsIndex = 0;
        this.showChangeActionBar = undefined;
        this.listContent = undefined;
        this.selectedRows = undefined;
        this.actionOptions = undefined;
        this.selectedRowCount = undefined;
        this.currentSearchKey = undefined;
        executeQueryCount({objectApiName: this.queryObject, whereClause: this.queryFilters, scope: this.queryScope})
        .then(result => {
            let jsonResult = JSON.parse(result);
            // console.log('rowcount result: ' + JSON.stringify(jsonResult));
            this.listItemsCountTotal = jsonResult;

            this.loadTableData();
        })
        .catch(error => {
            this.isLoading = undefined;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.errorMessageTitle,
                    message: this.label.errorMessageSuffix + error,
                    variant: 'error'
                })
            );
            console.log(error);
        });
    }

    handleShowListviewList(event) {
        console.log('open switcher');
        const rect = event.target.getBoundingClientRect();
        this.lvSwitchpopupX = rect.x;
        this.lvSwitchpopupY = rect.y + rect.height;

        this.showSwitchListview = true;
    }

    handleSwitchConfig(event) {
        let cnfId = event.detail.configId;
        this.selectedListviewConfig = cnfId;
        this.showSwitchListview = undefined;

        if (this.pinnedListviewConfig == cnfId) {
            this.isPinnedListview = true;
        } else {
            this.isPinnedListview = undefined;
        }

        this.initComponent();
    }

    handlePinListview(event) {
        pinUnpinListview({listviewId: this.selectedListviewConfig, masterListviewId: this.masterListviewConfig})
        .then(result => {
            if (this.isPinnedListview) {
                this.pinnedListviewConfig = undefined;
                this.isPinnedListview = undefined;
            } else {
                this.pinnedListviewConfig = this.selectedListviewConfig;
                this.isPinnedListview = true;
            }
        })
        .catch(error => {
            new ShowToastEvent({
                title: this.label.errorMessageTitle,
                message: error,
                variant: 'error'
            })
        });
    }

    handleCloseConfigSwitch(event) {
        this.showSwitchListview = undefined;
    }

    handleChangeOrderDirection(event) {
        let sord = event.detail.orderChange;
        // console.log('change sort dir of element at ' + sord);
        let newOrders = [...this.fieldOrders];
        this.fieldOrders = undefined;

        let updOrder = newOrders.at(sord);
        let otherDir = updOrder.direction;
        console.log('otherdir before change: ' + otherDir);
        let otherDirIcon = updOrder.directionIcon;
        if (otherDir.toLowerCase() === 'asc') {
            otherDir = 'DESC';
            otherDirIcon = 'utility:arrowdown';
        }else {
            otherDir = 'ASC';
            otherDirIcon = 'utility:arrowup';
        }
        updOrder.direction = otherDir;
        updOrder.directionIcon = otherDirIcon;
        updOrder.label = updOrder.fieldName + ' ' + updOrder.direction;
        newOrders.splice(sord, 1, updOrder);

        this.fieldOrders = newOrders;

        this.buildQueryOrderAndRefresh();
    }

    // handledDropOrderDeletePending() {
    //     this.template.querySelector('[data-role="deleteOrderItem"]').classList.remove('removeOrderHighlight');
    //     this.template.querySelector('[data-role="deleteOrderItem"]').classList.add('removeOrderPending');
    // }

    // handledDropOrderDeleteHighlight() {
    //     this.template.querySelector('[data-role="deleteOrderItem"]').classList.remove('removeOrderPending');
    //     this.template.querySelector('[data-role="deleteOrderItem"]').classList.add('removeOrderHighlight');
    // }

    handleOrderDragStart(event) {
        this.itemOrderDragged = event.detail.orderToChange;
    }

    handleOrderDragStop(event) {
        this.itemOrderDragged = undefined;
    }

    handleNewOrderDragStart(event) {
        this.newItemOrderDragged = event.detail.orderToChange;
    }

    handleNewOrderDragStop(event) {
        event.preventDefault();
        this.newItemOrderDragged = undefined;
    }

    handledDropNewHide(event) {
        event.preventDefault();
        this.template.querySelector('[data-role="newSortField"]').classList.remove('over');
    }
    
    handledDropNewShow(event) {
        event.preventDefault();
        this.template.querySelector('[data-role="newSortField"]').classList.add('over');
    }

    handleAddFirstOrder(event) {
        event.preventDefault();
        console.log('drop first sorter');
        // let sord = event.detail.orderChange;
        let tempOrders = [];
        let newTempOrders = [...this.availableFieldOrders];
        
        if (this.newItemOrderDragged != undefined) {
            let newItemIdx = this.availableFieldOrders.findIndex((newIt) => Number(newIt.sortOrder) == Number(this.newItemOrderDragged));
            let toMove = this.availableFieldOrders.at(newItemIdx);

            newTempOrders.splice(newItemIdx, 1);
            this.availableFieldOrders = newTempOrders;

            tempOrders.push(toMove);
        }

        let newOrder = 0;
        tempOrders.forEach(ordItem => {
            ordItem.isFirst = undefined;
            ordItem.isLast = undefined;
            ordItem.sortOrder = newOrder
            newOrder++;
        });
        if (tempOrders.length > 0) {
            tempOrders.at(0).isFirst = true;
            tempOrders.at(tempOrders.length - 1).isLast = true;
        }
        this.fieldOrders = tempOrders;

        this.buildQueryOrderAndRefresh();
    }

    handleMoveOrderBefore(event) {
        let sord = event.detail.orderChange;
        let tempOrders = [...this.fieldOrders];
        let newTempOrders = [...this.availableFieldOrders];
        
        if (this.itemOrderDragged != undefined) {
            let toMove = this.fieldOrders.at(this.itemOrderDragged);

            if (this.itemOrderDragged > sord) {
                tempOrders.splice(this.itemOrderDragged, 1);
                tempOrders.splice(sord, 0, toMove);
            } else {
                tempOrders.splice(this.itemOrderDragged, 1);
                tempOrders.splice(sord - 1, 0, toMove);
            }
        } else if (this.newItemOrderDragged != undefined) {
            let newItemIdx = this.availableFieldOrders.findIndex((newIt) => Number(newIt.sortOrder) == Number(this.newItemOrderDragged));
            let toMove = this.availableFieldOrders.at(newItemIdx);

            newTempOrders.splice(newItemIdx, 1);
            this.availableFieldOrders = newTempOrders;

            tempOrders.splice(sord, 0, toMove);
        }

        let newOrder = 0;
        tempOrders.forEach(ordItem => {
            ordItem.isFirst = undefined;
            ordItem.isLast = undefined;
            ordItem.sortOrder = newOrder
            newOrder++;
        });
        if (tempOrders.length > 0) {
            tempOrders.at(0).isFirst = true;
            tempOrders.at(tempOrders.length - 1).isLast = true;
        }
        this.fieldOrders = tempOrders;

        this.buildQueryOrderAndRefresh();
    }

    handleMoveOrderAfter(event) {
        let sord = event.detail.orderChange;
        let tempOrders = [...this.fieldOrders];
        let newTempOrders = [...this.availableFieldOrders];

        if (this.itemOrderDragged != undefined) {
            let toMove = this.fieldOrders.at(this.itemOrderDragged);

            if (this.itemOrderDragged > sord) {
                tempOrders.splice(this.itemOrderDragged, 1);
                tempOrders.splice(sord + 1, 0, toMove);
            } else {
                tempOrders.splice(this.itemOrderDragged, 1);
                tempOrders.splice(sord, 0, toMove);
            }
        } else if (this.newItemOrderDragged != undefined) {
            let newItemIdx = this.availableFieldOrders.findIndex((newIt) => Number(newIt.sortOrder) == Number(this.newItemOrderDragged));
            let toMove = this.availableFieldOrders.at(newItemIdx);

            newTempOrders.splice(newItemIdx, 1);
            this.availableFieldOrders = newTempOrders;

            tempOrders.splice(sord + 1 , 0, toMove);
        }

        let newOrder = 0;
        tempOrders.forEach(ordItem => {
            ordItem.isFirst = undefined;
            ordItem.isLast = undefined;
            ordItem.sortOrder = newOrder
            newOrder++;
        });
        if (tempOrders.length > 0) {
            tempOrders.at(0).isFirst = true;
            tempOrders.at(tempOrders.length - 1).isLast = true;
        }
        this.fieldOrders = tempOrders;

        this.buildQueryOrderAndRefresh();
    }    

    handleDeleteOrderItem(event) {
        let sord = event.detail.order;

        let tempOrders = [...this.fieldOrders];
        let tempNewOrders = [...this.availableFieldOrders];
        this.availableFieldOrders = undefined;
        
        let lastOrder = 0;
        tempNewOrders.forEach(itm => {if (itm.sortOrder > lastOrder) lastOrder = itm.sortOrder});
        let toRemove = this.fieldOrders.at(sord);
        let newItem = {fieldName: toRemove.fieldName, direction: toRemove.direction, directionIcon: toRemove.directionIcon, fieldLabel: toRemove.fieldLabel, sortOrder: lastOrder, label: toRemove.label};
        tempNewOrders.push(newItem);

        let newAvailOrder = 0;
        tempNewOrders.forEach(ordItem => {
            ordItem.sortOrder = newAvailOrder
            newAvailOrder++;
        });
        this.availableFieldOrders = tempNewOrders;
        
        let newOrder = 0;
        tempOrders.splice(sord, 1);
        tempOrders.forEach(ordItem => {
            ordItem.isFirst = undefined;
            ordItem.isLast = undefined;
            ordItem.sortOrder = newOrder
            newOrder++;
        });
        if (tempOrders.length > 0) {
            tempOrders.at(0).isFirst = true;
            tempOrders.at(tempOrders.length - 1).isLast = true;
        }
        if (tempOrders.length > 0) {
            this.fieldOrders = tempOrders;
        } else {
            this.fieldOrders = undefined;
        }

        this.buildQueryOrderAndRefresh();
    }

    buildQueryOrderAndRefresh() {
        if (this.fieldOrders && this.fieldOrders.length > 0) {
            this.queryOrders = ' ORDER BY ';
            this.fieldOrders.forEach(filt => {
                this.queryOrders += filt.label + ', ';
            });
            if (this.queryOrders.lastIndexOf(', ') > 0) {
                this.queryOrders = this.queryOrders.substring(0, this.queryOrders.lastIndexOf(', '));
            }
        }

        if (this.listviewsSorters != undefined && this.listviewsSorters != null) {
            let lvSortersIdx = this.listviewsSorters.findIndex((lvSorters) => String(lvSorters.listviewId) == String(this.selectedListviewConfig));
            if (lvSortersIdx >= 0) {
                this.listviewsSorters.splice(lvSortersIdx, 1);
            }
        } else {
            this.listviewsSorters = [];
        }
        let newSorters = {listviewId: this.selectedListviewConfig, listviewSorters: []};

        if (this.fieldOrders && this.fieldOrders.length > 0) {
            this.fieldOrders.forEach(sorter => {
                let srt = {fieldApiName: sorter.fieldName, direction: sorter.direction, sortOrder: sorter.sortOrder, soqlValue: sorter.label};
                newSorters.listviewSorters.push(srt);
            });
        }
        this.listviewsSorters.push(newSorters);

        updateUserPrefListviewSorters({listviewsSorters: JSON.stringify(this.listviewsSorters), masterListviewId: this.masterListviewConfig})
        .then(result => {
            console.log('User preferences saved');
        })
        .catch(error => {
            new ShowToastEvent({
                title: this.label.errorMessageTitle,
                message: error,
                variant: 'error'
            })
        });

        this.refreshTableResults();
    }

    handleShowAddOrderBy(event) {
        // const rect = event.target.getBoundingClientRect();
        // this.orderspopupX = rect.x - 700 + rect.width;
        // // this.orderspopupX = rect.x - 800;
        // this.orderspopupY = rect.y + rect.height;
        if (this.showAddOrderBy == undefined) {
            this.showAddOrderBy = true;
        } else {
            this.showAddOrderBy = undefined;
        }
    }

    handleUpdateOrderBy(event) {
        console.log('listupdsort');
        console.log(JSON.stringify(event.detail.fieldOrders));

        this.fieldOrders = event.detail.fieldOrders;
        this.queryOrders = event.detail.queryOrders;
        this.refreshTableResults();

        this.showAddOrderBy = undefined;
    }

    handleCloseOrderByEdit() {
        this.showAddOrderBy = undefined;
    }

    // handleRemoveOrderBy(event) {
    //     let orderLabel = event.target.dataset.label;
    //     console.log('remove orderby ' + orderLabel);

    //     let tempSorter = [];
    //     this.fieldOrders.forEach(sorter => {
    //         if (sorter.label.toLowerCase() !== orderLabel.toLowerCase()) {
    //             tempSorter.push(sorter);
    //         }
    //     });

    //     if (tempSorter.length > 0) {
    //         this.fieldOrders = tempSorter;
    //     } else {
    //         this.fieldOrders = undefined;
    //     }

    //     if (this.fieldOrders && this.fieldOrders.length > 0) {
    //         this.queryOrders = ' ORDER BY ';
    //         this.fieldOrders.forEach(filt => {
    //             this.queryOrders += filt.label + ', ';
    //         });
    //         if (this.queryOrders.lastIndexOf(', ') > 0) {
    //             this.queryOrders = this.queryOrders.substring(0, this.queryOrders.lastIndexOf(', '));
    //         }
    //     } else {
    //         this.queryOrders = undefined;
    //     }

    //     this.refreshTableResults();
    // }

    handleShowAddFilter(event) {
        const rect = event.target.getBoundingClientRect();
        // this.filterspopupX = rect.x - 800;
        this.filterspopupX = rect.x - 300 + rect.width;
        this.filterspopupY = rect.y + rect.height;

        this.showAddFilter = true;
    }

    handleUpdateFilters(event) {
        this.fieldOrders = event.detail.filters;
        this.queryFilters = event.detail.queryFilters;
        this.refreshTableResults();

        this.showAddFilter = undefined;
    }

    handleCloseFilterEdit(event) {
        this.showAddFilter = undefined;
    }

    handleRemoveFilter(event) {
        let filterLabel = event.target.dataset.label;
        console.log('remove filter ' + filterLabel);
        // let filterLabel = event.target.label;
        let tempFilter = [];
        this.fieldOrders.forEach(filter => {
            if (filter.label.toLowerCase() !== filterLabel.toLowerCase()) {
                tempFilter.push(filter);
            }
        });

        if (tempFilter.length > 0) {
            this.fieldOrders = tempFilter;
        } else {
            this.fieldOrders = undefined;
        }

        if (this.fieldOrders && this.fieldOrders.length > 0) {
            this.queryFilters = ' WHERE ';
            this.fieldOrders.forEach(filt => {
                this.queryFilters += filt.label + ' AND ';
            });
            if (this.queryFilters.lastIndexOf(' AND ') > 0) {
                this.queryFilters = this.queryFilters.substring(0, this.queryFilters.lastIndexOf(' AND '));
            }
        } else {
            this.queryFilters = undefined;
        }

        this.refreshTableResults();
    }

    handleRowSelection(event) {
        let selected = this.template.querySelector('c-p2-c_-extended-data-table').getSelectedRows();
        if (selected && selected.length > 0) {
            this.selectedRowCount = selected.length;
        } else {
            this.selectedRowCount = undefined;
        }
        this.selectedRows = selected;
        this.refreshActionList();
    }

    handleActionStart(event) {
        let found = this.listviewConfig.actions.find((action) => action.actionTarget == event.target.value);
        console.log(JSON.stringify(found));
        if (found) {
            // console.log('action type: ' + found.actionType);
            // console.log('action name: ' + found.actionTarget);
            if (found.actionType == 'Flow') {
                let inputVars = [];
                // let selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
                let selected = this.template.querySelector('c-p2-c_-extended-data-table').getSelectedRows();
                let idsText = "[";
                selected.forEach(row => {
                    idsText += "'" + row.Id + "',";
                });
                if (idsText.lastIndexOf("',") > 0) {
                    idsText = idsText.substring(0, idsText.lastIndexOf("',"));
                    idsText += "']";
                }
                inputVars.push({name: 'ids', type: 'String', value: idsText});
                inputVars.push({name: 'lvsource', type: 'String', value: this.listviewCardTitle});

                // console.log('flow params');
                // console.log(JSON.stringify(inputVars));
                this.flowInputVariables = inputVars;
                this.flowApiName = found.actionTarget;
                this.flowStart = true;
            }
            this.refreshActionList();
        }
    }

    closeModal(event) {
        this.flowStart = undefined;
        this.flowApiName = undefined;
        this.flowInputVariables = undefined;
    }

    handleFlowStatusChange(event) {
        console.log(event.detail.status);
        if (event.detail.status === 'FINISHED') {
            this.closeModal();
        }
    }

    refreshActionList() {
        let selected = this.template.querySelector('c-p2-c_-extended-data-table').getSelectedRows();

        let selectionSize = selected.length;
        this.actionOptions = undefined;

        if (this.listviewConfig.actions && this.listviewConfig.actions.length > 0) {
        // if (this.listviewConfig.actions !== undefined && this.listviewConfig.actions.length > 0) {
            let tempOptions = [];
            this.listviewConfig.actions.forEach(action => {
                switch (action.showCondition) {
                    case 'Always' :
                        let option = {label: action.actionLabel, value: action.actionTarget}
                        tempOptions.push(option);
                        break;
                    case 'One record is selected' :
                        if (selectionSize == 1) {
                            let option = {label: action.actionLabel, value: action.actionTarget}
                            tempOptions.push(option);
                        }
                        break;
                    case 'One or more records are selected' :
                        if (selectionSize >= 1) {
                            let option = {label: action.actionLabel, value: action.actionTarget}
                            tempOptions.push(option);
                        }
                        break;
                    case 'More than one record is selected' :
                        if (selectionSize > 1) {
                            let option = {label: action.actionLabel, value: action.actionTarget}
                            tempOptions.push(option);
                        }
                        break;
                    case 'Admins Only' :
                        break;
                }
            });

            if (tempOptions.length > 0) {
                this.actionOptions = tempOptions;
            // } else {
            //     this.actionOptions = undefined;
            }
        }
    }

    // getRowActions(row, doneCallback) {
    //     const rowAct = [];
    //     console.log('rowdata');
    //     console.log(JSON.stringify(row));
    //     // let datatableSelector = this.template.querySelector("c-p2-c_-extended-data-table");
    //     // let drafts = datatableSelector.draftValues;
    //     // if (drafts.find((rowDraft) => rowDraft.Id === row.Id)) {
    //     //     rowAct.push({ label: "Annuler les modifications", name: "resetDraft", iconName: 'utility:refresh' });
    //     // } else {
    //         rowAct.push({ label: "Annuler les modifications", name: "resetDraft", iconName: 'utility:refresh', disabled: this.hasDraft });
    //     // }
    //     setTimeout( () => {
    //         doneCallback(rowAct);
    //     }, 200 );
    // }

    // hasDraft(event) {
    //     console.log('hasDraft event');
    //     console.log(json.stringify(event));
    //     let drafts = this.template.querySelector("c-p2-c_-extended-data-table").draftValues
    //     console.log(drafts);
    // }

    handleRowAction(event) {
        const actionToRun = event.detail.action.name;
        const rowData = event.detail.row;
        // console.log('rowdata');
        // console.log(JSON.stringify(event.detail));

        switch (actionToRun) {
            case 'resetDraft':
                console.log('removing drafts from list for row Id ' + rowData.Id);
                let drafts = this.template.querySelector("c-p2-c_-extended-data-table").draftValues;
                let matchDraft = drafts.filter((rowDraft) => rowDraft.Id == rowData.Id);
                console.log('should remove ' + JSON.stringify(matchDraft));
                let restrictedDraft = drafts.filter((rowDraft) => rowDraft.Id != rowData.Id);
                if (restrictedDraft && restrictedDraft.length > 0) {
                    this.template.querySelector("c-p2-c_-extended-data-table").draftValues = restrictedDraft;
                } else {
                    console.log('empty list, reate fake record, with no changes');
                    let newDrafts = [];
                    let drf = {Id: rowData.Id};
                    newDrafts.push(drf);
                    this.template.querySelector("c-p2-c_-extended-data-table").draftValues = newDrafts;
                }
                this.draftValues = this.template.querySelector("c-p2-c_-extended-data-table").draftValues;
                console.log('updated draft values: ' + JSON.stringify(this.draftValues));

                if (this.draftValues.length < 1) this.showChangeActionBar = undefined;
                // let originValues = this.listContent.find((baserow) => baserow.Id === rowData.Id);
                // console.log('orig values:' + JSON.stringify(originValues));
                
                let tempList = JSON.parse(JSON.stringify(this.listContent));
                let tableRowMatchIndex = tempList.findIndex((row) => row.Id === rowData.Id);
                // console.log('rowindex: ' + tableRowMatchIndex);
                tempList[tableRowMatchIndex] = JSON.parse(JSON.stringify(this.listContent[tableRowMatchIndex]));
                this.listContent = [];
                // console.log('updatedlist');
                // console.log(JSON.stringify(tempList));
                this.listContent = JSON.parse(JSON.stringify(tempList));

                //Dispatch the refresh event
                this.dispatchEvent(new RefreshEvent());

                // datatableSelector.resetCustoms();
                // datatableSelector.setFieldValue(rowData.Id, 'StageName', 'A Traiter');
                break;
            case 'saveRowDraft':
                let draftsSave = this.template.querySelector("c-p2-c_-extended-data-table").draftValues;
                let matchDraftSave = draftsSave.filter((rowDraft) => rowDraft.Id == rowData.Id);

                if (matchDraftSave) {
                    const inputsItems = matchDraftSave.slice().map(draft => {
                        const fields = Object.assign({}, matchDraftSave);
                        return { fields };
                    });
                        
                    console.log('inputs');
                    console.log(JSON.stringify(inputsItems));

                    // const promiseSave = updateRecord(fields);
                    const promises = inputsItems.map(recordInput => updateRecord(recordInput));
                    Promise.all(promises).then(res => {
                        console.log('Singel line save results');
                        console.log(res);
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: this.label.successMessageTitle,
                                message: this.label.successMessageSuffix,
                                variant: 'success'
                            })
                        );
                        this.refreshTableResults();
                        let filteredDrafts = draftsSave.filter((rowDraft) => rowDraft.Id !== rowData.Id);
                        this.template.querySelector("c-p2-c_-extended-data-table").draftValues = filteredDrafts;
                        
                        this.draftValues = this.template.querySelector("c-p2-c_-extended-data-table").draftValues;
                        if (this.draftValues.length < 1) this.showChangeActionBar = undefined;

                        // this.template.querySelector("lightning-datatable").draftValues = [];
                    }).catch(error => {
                        console.log('save error');
                        console.log(JSON.stringify(error));
                        let errorMessage = '';
                        error.body.output.errors.forEach(error => {
                            errorMessage += error.message + '\n';
                        });
                        if (errorMessage.lastIndexOf('\n') > 0) {
                            errorMessage = errorMessage.substring(0, errorMessage.lastIndexOf('\n'));
                        }
            
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: this.label.errorMessageTitle,
                                message: errorMessage,
                                variant: 'error'
                            })
                        );
                    });                
                }

                break;
            default:
        }
    }

    handleShowDetails(event) {
        let tableContainerSelector = this.template.querySelector('div[data-id="extendedDatatableContainer"]');
        const containerRect = tableContainerSelector.getBoundingClientRect();
        const rect = event.target.getBoundingClientRect();
        let forceLeft = 0;
        if ((event.detail.posX + event.detail.popupWidth) > containerRect.right) {
            forceLeft = containerRect.right - (event.detail.posX + event.detail.popupWidth);
        }
                
        // console.log('show popup at ' + event.detail.posX + '(X), ' + event.detail.posY + '(Y), ' + event.detail.popupWidth + ' width');
        this.rowDetailLeft = event.detail.posX + forceLeft;
        this.rowDetailTop = event.detail.posY;
        this.rowDetailWidth = event.detail.popupWidth;
        this.rowDetailAlign = event.detail.popupAlign;
        this.rowDetailObjectApiName = event.detail.objectApiName;
        this.rowDetailId = event.detail.recordId;

        let context = event.detail.context;
        let detailFieldName = event.detail.fieldName;
        this.rowDetailColumns = this.columnDetailsLayouts.get(event.detail.fieldName).columns;

        // create indexes for the component to render correctly
        this.rowDetailColumns.forEach((col, colidx) => { 
            col.indexKey = this.rowDetailId + col.label + colidx;
            col.rows.forEach((row, idx) => {
                if (context) {
                    row.indexKey = context;
                } else {
                    row.indexKey = '';
                }
                if (row.fieldName) {
                    row.indexKey += this.rowDetailId + row.fieldName + idx;
                } else {
                    let mills = +new Date();
                    row.indexKey += this.rowDetailId + mills + idx;
                }
            })
        });
    }

    handleHideDetails(event) {
        this.rowDetailId = undefined;
    }

    handleTableReset(event) {
        this.draftValues = undefined;
        this.draftValues = [];
        this.refreshTableResults();
        this.showChangeActionBar = undefined;
    }
    
    handleTableSave(event) {
        // const updatedRecords = event.detail.draftValues;
        console.log(JSON.stringify(this.draftValues));

        const inputsItems = this.draftValues.slice().map(draft => {
            const fields = Object.assign({}, draft);
            return { fields };
        });
 
        console.log('inputs');
        console.log(JSON.stringify(inputsItems));
 
        const promises = inputsItems.map(recordInput => updateRecord(recordInput));
        this.isLoading = true;
        Promise.all(promises).then(res => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.successMessageTitle,
                    message: this.label.successMessageSuffix,
                    variant: 'success'
                })
            );
            this.showChangeActionBar = undefined;
            this.refreshTableResults();
            this.template.querySelector("c-extended-data-table").draftValues = [];
            this.draftValues = undefined;
            this.draftValues = [];
            this.selectedRows = undefined;
            this.template.querySelector("c-extended-data-table").selected = [];
        }).catch(error => {
            if (Object.keys(error).length > 0) {
                console.log('save error');
                console.log(JSON.stringify(error));
                let errorMessage = '';
                error.body.output.errors.forEach(error => {
                    errorMessage += error.message + '\n';
                });
                if (errorMessage.lastIndexOf('\n') > 0) {
                    errorMessage = errorMessage.substring(0, errorMessage.lastIndexOf('\n'));
                }
    
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.label.errorMessageTitle,
                        message: errorMessage,
                        variant: 'error'
                    })
                );
            }
        });
    }
}