import { LightningElement, api, track } from 'lwc';
import LightningConfirm from 'lightning/confirm';

export default class P2C_FolderAndFilesPicker extends LightningElement {

    @api structure;
    @api maxfiles;
    @api listtitle;
    @track items;
    @track recordId;
    @track recordName;
    @track selectedFileLabel;
    @track selectedFileValue;
    
    @track selectedItems;

    @track treeHeader;

    get hasItems() {
        return this.items && this.items.length > 0;
    }

    get hasFiles() {
        return this.selectedFileLabels && this.selectedFileLabels.length > 0;
    }

    connectedCallback() {
        if (this.structure !== undefined) {
            this.items = [];
            this.refreshAndSelect(this.structure, undefined);
        }
    }

    @api
    refreshAndSelect(structure, selected){
        this.structure = structure;
        this.recordId = this.structure.Id;
        this.recordName = this.structure.Name;
        this.treeHeader = this.listtitle + " " + this.recordName;
        if (structure.Children) {
            let buildItems = this.getItemsFromJson(structure.Children);
            this.items = [];
            this.items = buildItems;
            this.selectedItems = [];

            let matchingItem = this.selectItemByName(this.items, selected);
            if (matchingItem) {
                this.selectedFileLabel = matchingItem.label;
                this.selectedFileValue = matchingItem.name;
            } else {
                this.selectedFileLabel = undefined;
                this.selectedFileValue = undefined;
            }
        } else {
            this.items.length = 0;
        }

        let eventDetail = {};
        eventDetail.name = this.selectedFileLabel;
        eventDetail.id = this.selectedFileValue;
        const attachFileEvent = new CustomEvent("setfileasattachment", {
            detail: eventDetail
        });

        try {
            this.dispatchEvent(attachFileEvent);
        } catch (error) {
            console.log('failed to dispatch setfileasattachment');
            console.log(error);
        }
    }

    selectItemByName(items, itemname) {
        console.log('select itm with name ' + itemname);
        if (items !== undefined && itemname !== undefined) {
            console.log('items not empty, do the loop');
            for (let item of items) {
                if (item.name === itemname || item.label === itemname) return item;

                if (item.items && item.items.length > 0) {
                    let foundItem = this.selectItemByName(item.items, itemname);
                    if (foundItem) return foundItem;
                }
            }
        }
    }

    getItemsFromJson(jsonElements) {
        let items = [];
        jsonElements.forEach(child => {
            let item = {};
            if (child.IsFile) {
                item.label = 'Fichier ' + child.Name;
            } else {
                item.label = 'Devis N° ' + child.FileNumber + ' (' + child.Name + ')';
            }
            item.name = child.Id;
            item.disabled = false;
            item.items = [];
            item.expanded = true;
            if (child.Children) {
                item.items.push(...this.getItemsFromJson(child.Children));
            } else if (child.IsFile == undefined) {
                let genItem = {};
                genItem.label = 'Générer le devis';
                genItem.name = 'generate-' + child.Id;
                item.items.push(genItem);
            }
            items.push(item);
        });
        return items;
    }

    async handleSelectItem(event) {
        const findNode = (nodeList, name) =>
            nodeList.find((node) => node.name === name) ||
            nodeList.reduce(
                (p, v) => p || (v.items && findNode(v.items, name)),
                null
        );
        let selected = event.detail.name;
        let selectedLabel = findNode(this.items, selected).label;

        if (selected.startsWith('generate-')) {
            const result = await LightningConfirm.open({
                message: 'Voulez-vous générer le devis pdf et le sélectionné comme pièce jointe ?',
                variant: 'headerless',
                label: 'Confirmation de génération',
                // setting theme would have no effect
            });

            if (result == true){
                let quoteId = selected.substring(9, selected.length);
                console.log('ask for generation of file on quote ' + selected);
                console.log('   id is: ' + quoteId);
    
                let eventDetail = {};
                eventDetail.name = selected;
                eventDetail.id = quoteId;
                const genFileEvent = new CustomEvent("genquotefile", {
                    detail: eventDetail
                });
        
                try {
                    this.dispatchEvent(genFileEvent);
                } catch (error) {
                    console.log('failed to dispatch genFileEvent');
                    console.log(error);
                }
            }
        } else if (selectedLabel.startsWith('Fichier')) {
            const result = await LightningConfirm.open({
                message: 'Ajouter le fichier en pièce jointe ?',
                variant: 'headerless',
                label: 'Confirmation d\'ajout',
                // setting theme would have no effect
            });
            if (result == true){
                let matchingItem = this.selectItemByName(this.items, selected);
                if (matchingItem) {
                    this.selectedFileLabel = matchingItem.label;
                    this.selectedFileValue = matchingItem.name;
                } else {
                    this.selectedFileLabel = undefined;
                    this.selectedFileValue = undefined;
                }

                let eventDetail = {};
                eventDetail.name = this.selectedFileLabel;
                eventDetail.id = this.selectedFileValue;
                const attachFileEvent = new CustomEvent("setfileasattachment", {
                    detail: eventDetail
                });
        
                try {
                    this.dispatchEvent(attachFileEvent);
                } catch (error) {
                    console.log('failed to dispatch setfileasattachment');
                    console.log(error);
                }
            }
        }
    }

    handleRemoveSelection(event) {
        let eventDetail = {};
        eventDetail.name = this.selectedFileLabel;
        eventDetail.id = this.selectedFileValue;

        this.selectedFileLabel = undefined;
        this.selectedFileValue = undefined;

        const detachFileEvent = new CustomEvent("removeattachment", {
            detail: eventDetail
        });

        try {
            this.dispatchEvent(detachFileEvent);
        } catch (error) {
            console.log('failed to dispatch removeattachment');
            console.log(error);
        }
    }

    handleAddFileToEMail(event) {
        let eventDetail = {};
        eventDetail.name = this.selectedFileLabel;
        eventDetail.id = this.selectedFileValue;
        const attachFileEvent = new CustomEvent("setfileasattachment", {
            detail: eventDetail
        });

        try {
            this.dispatchEvent(attachFileEvent);
        } catch (error) {
            console.log('failed to dispatch setfileasattachment');
            console.log(error);
        }
    }
}