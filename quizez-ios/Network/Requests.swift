//
//  Requests.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/16/21.
//

import Foundation
import SocketIO

protocol SocketRequest: Encodable, SocketData {
}

extension SocketRequest {
    func socketRepresentation() throws -> SocketData {
        guard let data = try? JSONEncoder().encode(self),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw SocketError.encodingError
        }
        
        return json
    }
}

/// Request sent to join a session
struct JoinSessionRequest: SocketRequest {
    /// ID of Session to join
    let id: String
    
    /// Display name to associate with
    let name: String
}

/// If socket owns a session, kick a user
struct KickUserRequest: SocketRequest {
    /// ID of Session
    let session: String
    
    /// Display name to kick
    let name: String
}

/// If socket owns a session, start it
struct StartSessionRequest: SocketRequest {
    /// ID of Session
    let session: String
}

/// If socket owns a session, end it
struct EndSessionRequest: SocketRequest {
    /// ID of Session
    let session: String
}
