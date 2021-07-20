//
//  Requests.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/16/21.
//

import Foundation
import SocketIO

protocol SocketRequest: Encodable, SocketData {
    /// The event key for the socket server to associate with the request
    static var eventKey: String { get }
    
    /// The ID of the session to send request to
    var session: String { get set }
    
    /// Creates a copy of the request, setting `self.session` to the given argument
    func forSession(session: String) -> Self
}

extension SocketRequest {
    func forSession(session: String) -> Self {
        var clone = self
        clone.session = session
        return clone
    }
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

/// Request to create a new session - no arguments actually sent to server
struct CreateNewSessionRequest {
    static let eventKey: String = "create session"
}

/// Request sent to join a session
struct JoinSessionRequest: SocketRequest {
    static let eventKey: String = "join session"
    var session: String
    
    /// Display name to associate with
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case session = "id"
        case name
    }
}

/// If socket owns a session, kick a user
struct KickUserRequest: SocketRequest {
    static let eventKey: String = "kick"
    var session: String
    
    /// Display name to kick
    let name: String
    
    init(name: String, session: String = "") {
        self.name = name
        self.session = session
    }
}

/// If socket owns a session, start it
struct StartSessionRequest: SocketRequest {
    static let eventKey: String = "start session"
    var session: String
}

/// If socket owns a session, end it
struct EndSessionRequest: SocketRequest {
    static let eventKey: String = "end session"
    var session: String
}

/// If socket owns a session, add a Question to its quiz
class AddQuestionRequest: SocketRequest {
    static let eventKey: String = "add question"
    var session: String
    
    let question: Question
    
    init<T: Question>(question: T, session: String = "") {
        self.question = question
        self.session = session
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(session, forKey: .session)
        try container.encode(question, forKey: .question)
    }
    
    enum CodingKeys: String, CodingKey {
        case session
        case question
    }
}

/// If socket owns a session, push the next Question
struct NextQuestionRequest: SocketRequest {
    static let eventKey: String = "next question"
    var session: String
}

/// Socket submits response to session that they joined
class SubmitResponseRequest: SocketRequest {
    static let eventKey: String = "question response"
    
    var session: String
    
    /// The index of the question being responded to
    let index: Int
    
    /// The name of the user responding
    let name: String
    
    /// The response being sent
    let response: Response
    
    init<T: Response>(index: Int, name: String, response: T, session: String = "") {
        self.session = session
        self.name = name
        self.index = index
        self.response = response
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(session, forKey: .session)
        try container.encode(name, forKey: .name)
        try container.encode(index, forKey: .index)
        try container.encode(response, forKey: .response)
    }
    
    enum CodingKeys: String, CodingKey {
        case session
        case name
        case index
        case response
    }
}