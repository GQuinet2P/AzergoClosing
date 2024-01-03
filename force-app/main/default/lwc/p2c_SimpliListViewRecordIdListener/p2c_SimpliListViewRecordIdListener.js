import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';

export default class P2c_SimpliListViewRecordIdListener extends LightningElement {

    @api recordIds;
    @api fieldsToDisplay;
    @api objectApiName;
    @track oppty;

    subscription = {};

    connectedCallback() {
        // Register error listener
        this.registerErrorListener();

        const messageCallback = function (response) {
            console.log('New message received: ', JSON.stringify(response));
            // Response contains the payload of the new message received
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe('My_Component_Name', -1, messageCallback).then((response) => {
            // Response contains the subscription information on subscribe call
            console.log(
                'Subscription request sent to: ',
                JSON.stringify(response.channel)
            );
            this.subscription = response;
        });
    }


    @wire(getRecord, { recordId: '$recordIds', fields: [ 'Opportunity.Name', 'Opportunity.Id' ] })
    getaccountRecord({ data, error }) {
        console.log('opptyRecord => ', data, error);
        if (data) {
            this.oppty = data;
        } else if (error) {
            console.error('ERROR => ', JSON.stringify(error)); // handle error properly
        }
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError((error) => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }

}