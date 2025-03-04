@isTest
public class OpportunityTriggerHandlerTest {

    /**
     * This test class validates the behavior of the OpportunityTrigger, ensuring that:
     * 1. A user cannot create multiple open Opportunities in the same week.
     * 2. The error message is correctly added when the user tries to create an Opportunity within the same week.
     * 3. The system allows a user to create an Opportunity in a different week.
     * 4. It includes bulk testing and reuses common test data for all methods.
     */
    
    @testSetup
static void setupTestData() {
    // Generate a unique username for the test user to avoid duplicate username errors
   
    
    // Create a test User with a unique username
    Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
    User testUser = new User(
        Username = 'SalesTesting@example.com',
        FirstName = 'SalesTesting',  // Required field
        LastName = 'User',   // Required field
        Alias = 'tuser',
        Email = 'SalesTesting@example.com',
        ProfileId = userProfile.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        CommunityNickname = 'testuser'
    );
    insert testUser;

    // Create an Opportunity for the test user with a Close Date in a specific week (March 20, 2025)
    Opportunity existingOpp = new Opportunity(
        Name = 'Test Opportunity 1',
        OwnerId = testUser.Id,
        StageName = 'Prospecting',
        CloseDate = Date.newInstance(2025, 3, 20)
    );
    insert existingOpp;

    // This Opportunity will be used in other test methods
}

    @isTest
    static void testPreventMultipleOpportunitiesInSameWeek() {
        // Fetch the test user and existing Opportunity created in the @testSetup method
        User testUser = [SELECT Id FROM User WHERE Username = 'SalesTesting@example.com' LIMIT 1];
        Opportunity existingOpp = [SELECT Id, CloseDate FROM Opportunity WHERE OwnerId = :testUser.Id AND CloseDate = 2025-03-20 LIMIT 1];

        // Attempt to create another Opportunity for the same user with the same Close Date (same week)
        Opportunity newOpp = new Opportunity(
            Name = 'Test Opportunity 2',
            OwnerId = testUser.Id,
            StageName = 'Prospecting',
            CloseDate = existingOpp.CloseDate // Same Close Date (same week)
        );

        Test.startTest();
        
        // Try to insert the new Opportunity, it should throw an error
        try {
            insert newOpp;
            System.assert(false, 'An exception should have been thrown');
        } catch (DmlException e) {
            // Verify that the error message includes the expected text
            System.assert(e.getMessage().contains('You already have an open opportunity'));
        }
        
        Test.stopTest();
    }

    @isTest
    static void testAllowMultipleOpportunitiesInDifferentWeeks() {
        // Fetch the test user and existing Opportunity created in the @testSetup method
        User testUser = [SELECT Id FROM User WHERE Username = 'SalesTesting@example.com' LIMIT 1];
        
        // Create a second Opportunity for the same user with a different Close Date (March 25, 2025)
        Opportunity newOpp = new Opportunity(
            Name = 'Test Opportunity 2',
            OwnerId = testUser.Id,
            StageName = 'Prospecting',
            CloseDate = Date.newInstance(2025, 3, 25) // Different Close Date (different week)
        );
        
        Test.startTest();
        
        // The second Opportunity should be allowed to be created
        insert newOpp;

        // Verify the new Opportunity is inserted successfully
        Opportunity insertedOpp = [SELECT Id FROM Opportunity WHERE Id = :newOpp.Id];
        System.assert(insertedOpp != null, 'The second Opportunity should be inserted');
        
        Test.stopTest();
    }

    @isTest
    static void testBulkInsertOpportunities() {
        // Fetch the test user created in the @testSetup method
        User testUser = [SELECT Id FROM User WHERE Username = 'SalesTesting@example.com' LIMIT 1];
        
        // Insert multiple Opportunities for the test user with different Close Dates
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            Date closeDate = Date.today().addDays(i); // Creating Opportunities for multiple future weeks
            opportunities.add(new Opportunity(
                Name = 'Test Opportunity ' + i,
                OwnerId = testUser.Id,
                StageName = 'Prospecting',
                CloseDate = closeDate
            ));
        }

        Test.startTest();
        
        // Bulk insert the Opportunities
        insert opportunities;
        
        Test.stopTest();
    }
}