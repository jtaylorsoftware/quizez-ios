//
//  Events.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/16/21.
//

import Foundation

/// Errors that may occur when dealing with `SocketService`. Some are redundant (the event already indicates
/// the error) but are presented to keep the API consistent.
enum SocketError: Error {
    /// Invalid `URL` format when constructing `SocketService`
    case invalidUrl
    
    /// `SocketService` timed out when connecting to the server
    case connectionTimeout
    
    /// The response data from a handler could not be cast to expected type
    case unexpectedResponseData
    
    /// The request data from a sender could not be encoded
    case encodingError
    
    /// Could not complete a request because the `SocketService` is already connected
    case alreadyConnected
    
    /// Could not complete a request because the `SocketService` is already in a session
    case alreadyInSession
    
    /// Could not complete a request because it requires the `SocketService` to be connected
    case notConnected
    
    /// Could not complete a request because it requires the `SocketService` to be the owner of a session
    case notSessionOwner
    
    /// Could not complete a request because it requires the `SocketService` to have joined a session
    case didNotJoinSession
    
    /// Could not complete a request because it requires the `SocketService` to have started the session
    case sessionNotStarted
    
    /// Could not complete a request because the session has ended
    case sessionEnded
    
    /// Failed to join session
    case joinFailed
    
    /// Failed to kick user
    case kickFailed
    
    /// Failed to start session
    case startSessionFailed
    
    /// Failed to end session
    case endSessionFailed
    
    /// Failed to add question
    case addQuestionFailed
    
    /// Failed to respond to question
    case responseSubmissionFailed
    
    /// Failed to submit feedback
    case submitFeedbackFailed
}
