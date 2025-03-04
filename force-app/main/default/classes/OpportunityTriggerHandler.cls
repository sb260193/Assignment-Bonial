public without sharing class OpportunityTriggerHandler {

    /**
     * Bulkified method to check if the user has any open Opportunities within the same week 
     * as the new Opportunity's Close Date.
     * This method is designed to handle multiple Opportunities at once and perform efficient querying.
     * 
     * @param userIdToCloseDates A map where the key is the UserId and the value is the Close Date of the Opportunity.
     * @return A Map with the UserId as the key and the corresponding open Opportunity as the value.
     */
    public static Map<Id, Opportunity> checkOpenOpportunities(Map<Id, Date> userIdToCloseDates) {
        // Map to store open Opportunities by the UserId, which will help to track whether a user already has an open Opportunity within the same week
        Map<Id, Opportunity> openOpportunities = new Map<Id, Opportunity>();

        // Query all open Opportunities where the OwnerId is one of the users from the provided map, excluding closed Opportunities.
        // The query retrieves the Opportunity's Id, OwnerId, StageName, and CloseDate.
        for (Opportunity opp : [
            SELECT Id, OwnerId, StageName, CloseDate
            FROM Opportunity
            WHERE OwnerId IN :userIdToCloseDates.keySet() // Filtering by user ids present in the input map
            AND StageName != 'Closed Won'               // Exclude closed Opportunities
            AND StageName != 'Closed Lost'              // Exclude closed Opportunities
            AND CloseDate != NULL                        // Ensure CloseDate is not null
        ]) {
            // Get the CloseDate of the current Opportunity from the query
            Date closeDate = opp.CloseDate;

            // Calculate the start and end of the week for this Opportunity's Close Date
            Date startOfWeek = closeDate.toStartOfWeek();  // Start of the week (e.g., Monday)
            Date endOfWeek = startOfWeek.addDays(6);      // End of the week (e.g., Sunday)

            // Iterate over each UserId in the map passed into the method
            for (Id userId : userIdToCloseDates.keySet()) {
                // Get the new Opportunity's CloseDate for this user
                Date newCloseDate = userIdToCloseDates.get(userId);

                // Calculate the start and end of the week for the new Opportunity's CloseDate
                Date newStartOfWeek = newCloseDate.toStartOfWeek(); // Start of the new Opportunity's week
                Date newEndOfWeek = newStartOfWeek.addDays(6);      // End of the new Opportunity's week

                // Check if the Opportunity belongs to the same user and if it falls within the same week
                if (userId == opp.OwnerId && (closeDate >= newStartOfWeek && closeDate <= newEndOfWeek)) {
                    // If the Opportunity belongs to the user and is within the same week, add it to the map
                    openOpportunities.put(userId, opp);
                }
            }
        }

        // Return the map of open Opportunities for users who have open Opportunities in the same week as the new Opportunity
        return openOpportunities;
    }
}