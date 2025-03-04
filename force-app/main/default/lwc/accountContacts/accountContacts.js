import { LightningElement, wire, track } from 'lwc';
import getAllAccounts from '@salesforce/apex/AccountContactController.getAllAccounts';
import getContactsByAccountId from '@salesforce/apex/AccountContactController.getContactsByAccountId';
import updateContact from '@salesforce/apex/AccountContactController.updateContact';

export default class AccountContactComponent extends LightningElement {
    @track selectedAccountId; // Track selected account ID
    @track contacts = [];      // Track contacts for selected account
    @track accountOptions = []; // Track account options for picklist
    @track columns = [
        { label: 'First Name', fieldName: 'FirstName' },
        { label: 'Last Name', fieldName: 'LastName' },
        { label: 'Email', fieldName: 'Email' },
        {
            label: 'Actions',
            type: 'button',
            typeAttributes: {
                label: 'Edit',
                name: 'edit',
                title: 'Edit',
                disabled: false,
                value: 'edit',
                iconPosition: 'left'
            }
        }
    ];
    @track isModalOpen = false; // Modal visibility for editing contact
    @track contactToEdit = {}; // Track contact details to edit
    @track isSuccessMessageVisible = false; // Track success message visibility
    @track errorMessage = '';  // Track error message for invalid input

    // Get all accounts for the picklist
    @wire(getAllAccounts)
    wiredAccounts({ data, error }) {
        if (data) {
            this.accountOptions = data.map(account => ({
                label: account.Name,
                value: account.Id
            }));
        } else if (error) {
            console.error('Error fetching accounts', error);
        }
    }

    // Handle account change and fetch related contacts
    handleAccountChange(event) {
        this.selectedAccountId = event.target.value; // Set the selected account ID
        if (this.selectedAccountId) {
            this.fetchContacts(this.selectedAccountId); // Fetch contacts for selected account
        } else {
            this.contacts = []; // Reset contacts if no account is selected
        }
    }

    // Fetch contacts for the selected account
    fetchContacts(accountId) {
        getContactsByAccountId({ accountId })
            .then(result => {
                this.contacts = result; // Set fetched contacts
            })
            .catch(error => {
                console.error('Error fetching contacts', error);
            });
    }

    // Handle edit button click on the contact table
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        
        if (actionName === 'edit') {
            this.contactToEdit = { ...row }; // Set the contact to edit
            this.isModalOpen = true; // Open the modal to edit contact
        }
    }

    // Handle input changes in the modal
    handleInputChange(event) {
        const field = event.target.dataset.id;
        this.contactToEdit[field] = event.target.value; // Update the contact data
    }

    // Save the edited contact with email validation
    saveContact() {
        // Validate the email format using a simple regex pattern
        const email = this.contactToEdit.Email;
        const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
        
        if (!emailRegex.test(email)) {
            this.errorMessage = 'Please enter a valid email address.';
            return; // Prevent the save if the email is invalid
        }

        this.errorMessage = ''; // Clear the error message if email is valid

        updateContact({ contactToUpdate: this.contactToEdit })
            .then(result => {
                if (result === 'Success') {
                    // Close modal and show success message
                    this.isSuccessMessageVisible = true;
                    setTimeout(() => {
                        this.isSuccessMessageVisible = false;
                        this.isModalOpen = false;

                        // Update the contacts array with the edited contact
                        const updatedContactIndex = this.contacts.findIndex(contact => contact.Id === this.contactToEdit.Id);
                        if (updatedContactIndex !== -1) {
                            this.contacts = [
                                ...this.contacts.slice(0, updatedContactIndex),
                                { ...this.contactToEdit },
                                ...this.contacts.slice(updatedContactIndex + 1)
                            ];
                        }
                    }, 2000);
                }
            })
            .catch(error => {
                console.error('Error saving contact', error);
            });
    }

    // Close the modal
    closeModal() {
        this.isModalOpen = false; // Close the modal
    }
}
