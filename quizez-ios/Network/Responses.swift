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
