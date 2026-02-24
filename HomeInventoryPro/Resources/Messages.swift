import Foundation

enum ActorMessage: Sendable {
    // Lifecycle
    case initialize
    case timeout
    
    // Data
    case campaignReceived([String: String])
    case navigationReceived([String: String])
    
    // Network
    case networkOnline
    case networkOffline
    
    // Validation
    case validateStart
    case validateSuccess
    case validateFailure
    
    // Fetching
    case fetchCampaignStart
    case fetchCampaignSuccess([String: String])
    case fetchCampaignFailure
    
    case fetchEndpointStart
    case fetchEndpointSuccess(String)
    case fetchEndpointFailure
    
    // Permissions
    case permissionRequested
    case permissionAllowed
    case permissionDenied
    case permissionSkipped
    
    // Navigation
    case navigateToMain
    case navigateToWeb
}
