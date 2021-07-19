//
//  Responses.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/16/21.
//

import Foundation

/// A  response from the socket server
protocol SocketResponse {
    /// The ID of the session for the response
    var session: String { get }
    
    /// Creates a SocketResponse from a JSON Dictionary
    /// - Parameter json: Dictionary of `String: Any` pairs, where it is expected that `json` has keys for `Self.Type` properties
    init?(json: [String: Any])
}

/// Quiz session was created successfully
struct CreatedSession: SocketResponse {
    let session: String
    
    init?(json: [String : Any]) {
        guard let id = json["id"] as? String else {
            return nil
        }
        self.session = id
    }
}

/// A user has joined the session (the user might be the socket receiving the response)
struct UserJoined: SocketResponse {
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

/// A user has manually disconnected from the session
struct UserDisconnected: SocketResponse {
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

/// The next Question being received from session
struct NextQuestion: SocketResponse {
    let session: String
    
    /// Index of the Question in the quiz
    let index: Int
    
    /// The next Question
    let question: Question
    
    init?(json: [String : Any]) {
        guard let session = json["session"] as? String,
              let index = json["index"] as? Int,
              let question = Self.parseQuestion(json: json) else {
            return nil
        }
        
        self.session = session
        self.index = index
        self.question = question
    }
    
    private static func parseQuestion(json: [String: Any]) -> Question? {
        guard let question = json["question"] as? [String: Any],
              let text = question["text"] as? String,
              let body = question["body"] as? [String: Any],
              let rawType = body["type"] as? String,
              let type = QuestionType(rawValue: rawType) else {
            return nil
        }
        
        switch(type){
        case .multipleChoice:
            guard let answer = body["answer"] as? Int else {
                return nil
            }
            guard let rawChoices = body["choices"] as? [[String: Any]] else {
                return nil
            }
            var choices: [MultipleChoiceQuestionBody.Choice] = []
            for choice in rawChoices {
                guard let choiceText = choice["text"] as? String else {
                    return nil
                }
                choices.append(.init(text: choiceText))
            }
            
            return try? MultipleChoiceQuestion(text: text, body: .init(choices: choices, answer: answer))
        case .fillInTheBlank:
            guard let answer = body["answer"] as? String else {
                return nil
            }
            return try? FillInTheBlankQuestion(text: text, body: .init(answer: answer))
        }
    }
}
