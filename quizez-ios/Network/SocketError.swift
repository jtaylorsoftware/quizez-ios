//
//  Events.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/16/21.
//

import Foundation

/// Errors that may occur when dealing with SocketService
enum SocketError: Error {
    /// Invalid URL format when constructing SocketService
    case invalidUrl
    
    /// Service timed out when connecting to the server
    case connectionTimeout
    
    /// The response data from a handler could not be cast to expected type
    case unexpectedResponseData
    
    /// The request data from a sender could not be encoded
    case encodingError
    
    /// Failed to join session
    case joinFailed
    
    /// Failed to kick user
    case kickFailed
    
    /// Failed to start session
    case startSessionFailed
    
    /// Failed to end session
    case endSessionFailed
}
