public without sharing class AccountContactController {
    
    // Method to get all Accounts
    @AuraEnabled(cacheable=true)
    public static List<Account> getAllAccounts() {
        return [SELECT Id, Name FROM Account limit 100];
    }

    // Method to get Contacts for a specific Account
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactsByAccountId(Id accountId) {
        return [SELECT Id, FirstName, LastName, Email FROM Contact WHERE AccountId = :accountId];
    }

    // Method to update a Contact
    @AuraEnabled
    public static String updateContact(Contact contactToUpdate) {
        try {
            update contactToUpdate;
            return 'Success';
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
}