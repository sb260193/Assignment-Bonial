import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; // Import for showing toast
import updateContact from '@salesforce/apex/AccountContactController.updateContact';

export default class ContactModal extends LightningElement {
    @api contactId; // The contact ID passed from the parent component
    contact = {}; // The contact object

    // Close the modal when cancel button is clicked
    closeModal() {
        this.dispatchEvent(new CustomEvent('close')); // Dispatch event to parent to close modal
    }

    // After contact is saved, close the modal and notify the parent to refresh the contact list
    handleSuccess() {
        // Show success toast message
        const toastEvent = new ShowToastEvent({
            title: 'Success',
            message: 'Contact updated successfully!',
            variant: 'success',
        });
        this.dispatchEvent(toastEvent); // Display toast message

        // Notify the parent to refresh the contact list
        this.dispatchEvent(new CustomEvent('contactsave')); // Notify parent to rerender

        this.closeModal(); // Close the modal after saving
    }

    // Update contact details and handle saving
    saveContact() {
        // Assume we have a contact object with necessary fields
        updateContact({ contactId: this.contactId, updatedContact: this.contact })
            .then(result => {
                this.handleSuccess(); // Call the success handler after saving
            })
            .catch(error => {
                console.error('Error updating contact:', error);
            });
    }
}
