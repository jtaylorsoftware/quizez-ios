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
