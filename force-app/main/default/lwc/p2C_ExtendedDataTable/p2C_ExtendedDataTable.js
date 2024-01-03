import LightningDatatable from 'lightning/datatable';
import picklistStatic from './picklistStatic.html';
import picklistTemplate from './picklistTemplate.html';
import hoverLinkTemplate from './hoverLinkTemplate.html';
import hoverLinkEditTemplate from './hoverLinkEditTemplate.html';
import lookupTemplate from './lookupTemplate.html';
import richTextTemplate from './richTextTemplate.html';
import richTextEditTemplate from './richTextEditTemplate.html';
import { loadStyle } from 'lightning/platformResourceLoader';
import DataTableResource from '@salesforce/resourceUrl/CustomDataTable';

import { LightningElement, api, track } from 'lwc';

export default class P2C_ExtendedDataTable extends LightningDatatable {

    static customTypes = {
        picklistColumn: {
            // template: picklistStatic,
            template: picklistTemplate,
            // editTemplate: picklistTemplate,
            standardCellLayout: true,
            // typeAttributes: ['options', 'label', 'value', 'placeholder', 'context', 'contextName', 'fieldName', 'variant', 'name', 'allowEdit']
            typeAttributes: ['options', 'label', 'value', 'editedValue', 'placeholder', 'context', 'contextName', 'fieldName', 'variant', 'name', 'allowEdit', 'reset']
        },
        hoverLinkColumn: {
            template: hoverLinkTemplate,
            editTemplate: hoverLinkEditTemplate,
            standardCellLayout: true,
            typeAttributes: ['linkUrl', 'value', 'context', 'contextName', 'fieldName', 'fireHoverEvents', 'popupAlign','popupWidth', 'lookupId', 'lookupRecordApiName', 'lookupFieldToDisplay']
            // typeAttributes: ['label', 'linkUrl', 'value', 'context', 'contextName', 'fieldName', 'variant', 'name', 'fireHoverEvents', 'popupAlign','popupWidth', 'lookupId', 'lookupRecordApiName', 'lookupFieldToDisplay']
        },
        lookupColumn: {
            template: lookupTemplate,
            standardCellLayout: true,
            typeAttributes: ['lookupFieldToDisplay', 'value', 'editedValue', 'fireHoverEvents', 'lookupRecordApiName', 'context', 'contextName', 'fieldName', 'allowEdit', 'popupAlign', 'popupWidth']
        },
        richTextColumn: {
            template: richTextTemplate,
            editTemplate: richTextEditTemplate,
            standardCellLayout: true,
            typeAttributes: ['label', 'value', 'context', 'recordApiName', 'fieldName', 'fireHoverEvents','popupAlign','popupWidth']
        }
    };

    constructor() {
        super();
        Promise.all([
            loadStyle(this, DataTableResource),
        ]).then(() => {
            console.log('picklist style loaded');
        })
        .catch(error => {
            console.log('picklist style failed');
        });
    }

    // @api
    // resetCustoms() {
    //     this.customTypes.forEach(ctyp => {
    //         ctyp.reset();
    //     });
    // }
}