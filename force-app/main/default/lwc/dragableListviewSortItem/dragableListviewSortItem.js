import { LightningElement, api, track } from 'lwc';

export default class DragableListviewSortItem extends LightningElement {

    @api itemLabel;
    @api itemName;
    @api itemDirection;
    @api itemOrder;
    @api itemIsLast;
    @api itemIsFirst;
    @api itemDirectionIcon;
    @api showIcons;
    @api itemIsUsed;
    @api itemCanDrop;
    
    @track itemIsDraggable;

    // connectedCallback() {
    //     console.log('    item sortOrder: ' + this.itemOrder);
    //     console.log('    item label: ' + this.itemLabel);
    // }

    renderedCallback() {
        // console.log('item is used? ' + this.itemIsUsed);
        if (this.itemCanDrop == undefined) {
            let itemSelector = this.template.querySelector('[data-role="container"]');
            if (itemSelector) itemSelector.classList.add('itemInlineBlock');
        }
        if (this.itemIsUsed) {
            this.itemIsDraggable = undefined;

            let itemSelector = this.template.querySelector('[data-role="drag-item"]');
            // console.log('itm selector: ' + itemSelector);
            if (itemSelector) itemSelector.classList.add('itemShadow');
        } else {
            this.itemIsDraggable = true;
        }
    }

    handledDropBeforeShow(event) {
        event.preventDefault();
        this.template.querySelector('[data-role="drop-before"]').classList.remove('link');
        this.template.querySelector('[data-role="drop-before"]').classList.add('over');
    }

    handledDropBeforeHide(event) {
        event.preventDefault();
        this.template.querySelector('[data-role="drop-before"]').classList.remove('over');
        this.template.querySelector('[data-role="drop-before"]').classList.add('link');
    }

    handledDropAfterShow(event) {
        event.preventDefault();
        this.template.querySelector('[data-role="drop-after"]').classList.remove('link');
        this.template.querySelector('[data-role="drop-after"]').classList.add('over');
    }
    
    handledDropAfterHide(event) {
        event.preventDefault();
        this.template.querySelector('[data-role="drop-after"]').classList.remove('over');
        this.template.querySelector('[data-role="drop-after"]').classList.add('link');
    }

    handleDragStart(event) {
        this.template.querySelector('[data-role="drag-item"]').classList.add('alpha15');

        let sord = Number(event.currentTarget.getAttribute("data-id"));
        this.dispatchEvent(new CustomEvent('dragitemorder', {
            detail: {
                orderToChange: sord
            }
        }));    
    }

    handleDragStop(event) {
        this.template.querySelector('[data-role="drag-item"]').classList.remove('alpha15');

        this.dispatchEvent(new CustomEvent('dragitemorderstop', {
            detail: {
                orderToChange: 'none'
            }
        }));    
    }

    handleChangeDirection(event) {
        let sord = event.currentTarget.getAttribute("data-id");

        if (this.itemDirection.toLowerCase() === 'asc') {
            this.itemDirection = 'DESC';
        } else {
            this.itemDirection = 'ASC';
        }

        this.dispatchEvent(new CustomEvent('changeitemdirection', {
            detail: {
                orderChange: sord
            }
        }));
    }

    handleDropBefore(event) {
        event.preventDefault();
        this.template.querySelector('[data-role="drop-before"]').classList.remove('over');
        this.template.querySelector('[data-role="drop-before"]').classList.add('link');
        let sord = Number(event.currentTarget.getAttribute("data-id"));

        this.dispatchEvent(new CustomEvent('moveitembeforeorder', {
            detail: {
                orderChange: sord
            }
        }));    
    }

    handleDropAfter(event) {
        event.preventDefault();
        this.template.querySelector('[data-role="drop-after"]').classList.remove('over');
        this.template.querySelector('[data-role="drop-after"]').classList.add('link');
        let sord = Number(event.currentTarget.getAttribute("data-id"));

        this.dispatchEvent(new CustomEvent('moveitemafterorder', {
            detail: {
                orderChange: sord
            }
        }));    
    }

    handleRemoveOrderItem(event) {
        let sord = event.currentTarget.getAttribute("data-id");

        this.dispatchEvent(new CustomEvent('removeorderitem', {
            detail: {
                order: sord
            }
        }));
    }
}