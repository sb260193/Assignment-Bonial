trigger OpportunityTrigger on Opportunity (before insert) {
    
    // Create a map to store the Close Dates for all new Opportunities by user.
    // This map will help us track the Close Dates of the new Opportunities for each user.
    Map<Id, Date> userIdToCloseDates = new Map<Id, Date>();

    // Populate the map with user Id and Close Date for each new Opportunity being inserted.
    // This loop iterates through the list of Opportunities being inserted (Trigger.new) and stores
    // the OwnerId (UserId) and their corresponding Close Date in the map.
    for (Opportunity opp : Trigger.new) {
        userIdToCloseDates.put(opp.OwnerId, opp.CloseDate);
    }

    // Call the bulkified method to check if any user has an open Opportunity for the same week
    // as the Close Date of the new Opportunity. The method returns a map with the UserId as the key 
    // and the corresponding open Opportunity as the value.
    Map<Id, Opportunity> openOpportunities = OpportunityTriggerHandler.checkOpenOpportunities(userIdToCloseDates);

    // Loop through each Opportunity being inserted and check if the user already has an open Opportunity
    // for the same week. We check if an open Opportunity exists for the user within the same week as the 
    // new Opportunity's Close Date.
    for (Opportunity opp : Trigger.new) {
        // Get the existing open Opportunity for the user (if any) from the map returned by the helper method
        Opportunity existingOpportunity = openOpportunities.get(opp.OwnerId);
        
        // If an open Opportunity exists for the same week (i.e., an Opportunity is found in the map),
        // we prevent the creation of the new Opportunity by adding an error to the new Opportunity record.
        if (existingOpportunity != null) {
            // Retrieve the custom label for the Opportunity record link.
            // The label contains the URL template for accessing the Opportunity.
            String oppLinkTemplate = Label.Opportunity_Record_Link; // Custom Label
            
            // Replace the placeholder in the URL template with the actual Opportunity ID of the existing Opportunity.
            // This will generate a valid URL to the existing Opportunity record.
            String oppLink = oppLinkTemplate.replace('{!Opportunity.Id}', existingOpportunity.Id);
            
            // Add an error message to the new Opportunity record to prevent its creation.
            // The error message explains that the user already has an open Opportunity for the same week
            // and provides a link to the existing Opportunity so the user can close it.
            opp.addError('You already have an open opportunity for the week of ' + opp.CloseDate.format() + 
                         '. Please close the existing opportunity as "Won" or "Lost" before creating a new one. You can close the opportunity here: ' + 
                         oppLink);
        }
    }
}