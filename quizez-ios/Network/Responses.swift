//
//  Responses.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/16/21.
//

import Foundation

/// A  response from the socket server
protocol SocketResponse {
    /// Creates a SocketResponse from a JSON Dictionary
    /// - Parameter json: Dictionary of `String: Any` pairs, where it is expected that `json` has keys for `Self.Type` properties
    init?(json: [String: Any])
}

/// Quiz session was created successfully
struct CreatedSession: SocketResponse {
    /// The unique ID of the session
    let id: String
    
    init?(json: [String : Any]) {
        guard let id = json["id"] as? String else {
            return nil
        }
        self.id = id
    }
}

/// A user has joined the session (the user might be the socket receiving the response)
struct UserJoined: SocketResponse {
    /// The ID of the session
    let session: String
    
    /// The name of the user joining
    let name: String

    init?(json: [String : Any]) {
        guard let session = json["session"] as? String,
              let name = json["name"] as? String else {
            return nil
        }
        self.session = session
        self.name = name
    }
}

/// User kicked successfully
struct KickedUser: SocketResponse {
    /// The ID of the session
    let session: String
    
    /// The name of the user kicked
    let name: String
    
    init?(json: [String : Any]) {
        guard let session = json["session"] as? String,
              let name = json["name"] as? String else {
            return nil
        }
        self.session = session
        self.name = name
    }
}

/// A user has disconnected from the session (reason is not that they were kicked)
struct UserDisconnected: SocketResponse {
    /// The ID of the session
    let session: String
    
    /// The name of the user disconnected
    let name: String
    
    init?(json: [String : Any]) {
        guard let session = json["session"] as? String,
              let name = json["name"] as? String else {
            return nil
        }
        self.session = session
        self.name = name
    }
}
