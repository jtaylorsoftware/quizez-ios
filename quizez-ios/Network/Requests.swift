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
struct AddQuestionRequest: SocketRequest {
    static let eventKey: String = "add question"
    var session: String
    
    /// The text of the Question
    let text: String
    
    /// The body of the Question
    let body: QuestionBody
    
    init(text: String, body: QuestionBody, session: String = "") {
        self.text = text
        self.body = body
        self.session = session
    }
}

/// If socket owns a session, push the next Question
struct NextQuestionRequest: SocketRequest {
    static let eventKey: String = "next question"
    var session: String
}

extension AddQuestionRequest: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(session, forKey: .session)
        try container.encode(text, forKey: .text)
        
        var bodyContainer = container.nestedContainer(keyedBy: BodyKeys.self, forKey: .body)
        
        switch body {
        case let body as MultipleChoiceQuestionBody:
            try bodyContainer.encode(QuestionType.multipleChoice.rawValue, forKey: .type)
            try bodyContainer.encode(body.choices, forKey: .choices)
            try bodyContainer.encode(body.answer, forKey: .answer)
        case let body as FillInTheBlankQuestionBody:
            try bodyContainer.encode(QuestionType.fillInTheBlank.rawValue, forKey: .type)
            try bodyContainer.encode(body.answer, forKey: .answer)
        default:
            throw EncodingError.invalidValue(body, .init(codingPath: [CodingKeys.body], debugDescription: "AddQuestionRequest.body has unsupported type \(type(of: body))"))
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case session
        case text
        case body
    }
    
    enum BodyKeys: String, CodingKey {
        case type
        case choices
        case answer
    }
}
