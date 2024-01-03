import { api, LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { FlowNavigationPauseEvent } from 'lightning/flowSupport';

export default class P2C_launchModalFlow extends NavigationMixin(LightningElement) {

    @api flowInputs;
    @api _inputVariables;
    
    @track flowApiName;
    @track modalTitle;
    @track startFlow;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            // console.log('got wired params');
            // console.log(JSON.stringify(currentPageReference));

            this.flowApiName = currentPageReference?.state?.c__flowApiName;
            this.modalTitle = currentPageReference?.state?.c__modalTitle;
            this.flowInputs = currentPageReference?.state?.c__flowInputs;
            this.startFlow = true;

            console.log('flowInputs: ' + this.flowInputs);
        }
    }

    get inputVariables() {
        if (this._inputVariables) {
            return JSON.parse(this._inputVariables);
        } else {
            return [];
        }
    }

    connectedCallback() {
        console.log('connected with params');

        console.log('flowapiname: ' + this.flowApiName);
        console.log('flowInputs: ' + this.flowInputs);
        console.log('variables: ' + this._inputVariables);

        if (this._inputVariables) {
            this._inputVariables = JSON.parse(this._inputVariables);
        }
    }

    handleStatusChange(event) {
        console.log('handleStatusChange', event.detail);

        console.log('success ? ' + event.detail.status);
        if (event.detail.status === 'FINISHED' || event.detail.status === 'FINISHED_SCREEN') {
            console.log('flow ended');
            console.log('output is: ' + JSON.stringify(event.detail.outputVariables));
            if (event.detail.outputVariables) {
                let outputs = event.detail.outputVariables;
                outputs.forEach(element => {
                    if (element.name === 'retURL') {
                        this.navigateTo(element.value);
                    }
                });
            }
        }
    }

    navigateTo(toUrl){
        console.log('now redirect to ' + toUrl);
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: toUrl,
                actionName: 'view',
            },
        }).then((url) => {
            window.location.href = url;
        });
    }

    closeModal(){
        window.history.back();
        setTimeout(() => {
            window.location.reload();
        }, 1000);
    }
}