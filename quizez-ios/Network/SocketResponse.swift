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
class NextQuestion: SocketResponse {
    let session: String
    
    /// Index of the Question in the quiz
    let index: Int
    
    required init?(json: [String : Any]) {
        guard let session = json["session"] as? String,
              let index = json["index"] as? Int else {
            return nil
        }
        
        self.session = session
        self.index = index
    }
}

class NextMultipleChoiceQuestion: NextQuestion {
    let question: MultipleChoiceQuestion
    
    required init?(json: [String : Any]) {
        guard let questionJson = json["question"] as? [String: Any],
              let question = Self.parseQuestion(json: questionJson) else {
            return nil
        }
        
        self.question = question
        super.init(json: json)
    }
    
    private static func parseQuestion(json: [String: Any]) -> MultipleChoiceQuestion? {
        guard let question = json["question"] as? [String: Any],
              let text = question["text"] as? String,
              let body = question["body"] as? [String: Any],
              let rawType = body["type"] as? String,
              let type = QuestionType(rawValue: rawType),
              type == .multipleChoice else {
            return nil
        }
        
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
    }
}

class NextFillInTheBlankQuestion: NextQuestion {
    let question: FillInTheBlankQuestion
    
    required init?(json: [String : Any]) {
        guard let questionJson = json["question"] as? [String: Any],
              let question = Self.parseQuestion(json: questionJson) else {
            return nil
        }
        
        self.question = question
        super.init(json: json)
    }
    
    private static func parseQuestion(json: [String: Any]) -> FillInTheBlankQuestion? {
        guard let question = json["question"] as? [String: Any],
              let text = question["text"] as? String,
              let body = question["body"] as? [String: Any],
              let rawType = body["type"] as? String,
              let type = QuestionType(rawValue: rawType),
              type == .fillInTheBlank else {
            return nil
        }
        
        guard let answer = body["answer"] as? String else {
            return nil
        }
        return try? FillInTheBlankQuestion(text: text, body: .init(answer: answer))
    }
}

/// The user has submitted their response to a question and is receiving their grade
struct QuestionResponseSubmitted : SocketResponse {
    let session: String
    
    /// The index of the question that was responded to originally
    let index: Int
    
    /// True if the user was the first to submit the correct response
    let firstCorrect: Bool
    
    /// True if the user's submission was the correct answer
    let isCorrect: Bool
    
    init?(json: [String : Any]) {
        guard let session = json["session"] as? String,
              let index = json["index"] as? Int,
              let firstCorrect = json["firstCorrect"] as? Bool,
              let isCorrect = json["isCorrect"] as? Bool else {
            return nil
        }
        
        self.session = session
        self.index = index
        self.firstCorrect = firstCorrect
        self.isCorrect = isCorrect
    }
}

/// The session owner is receiving a graded, user-submitted response
struct QuestionResponseAdded : SocketResponse {
    /// The id of the session containing the Question
    let session: String
    
    ///The Question index
    let index: Int
    
    /// The user submitting Response
    let user: String
    
    /// The user's response value
    let response: String
    
    /// True if the user's Response is correct
    let isCorrect: Bool
    
    /// Name of the first correct responder
    let firstCorrect: String

    /// The frequency of the user's response at the time of submission
    let frequency: Int
    
    /// The relative frequency of the user's response at the time of submission
    let relativeFrequency: Int
    
    init?(json: [String : Any]) {
        guard let session = json["session"] as? String,
              let index = json["index"] as? Int,
              let user = json["user"] as? String,
              let response = json["response"] as? String,
              let isCorrect = json["isCorrect"] as? Bool,
              let firstCorrect = json["firstCorrect"] as? String,
              let frequency = json["frequency"] as? Int,
              let relativeFrequency = json["relativeFrequency"] as? Int else {
            return nil
        }
        
        self.session = session
        self.index = index
        self.user = user
        self.response = response
        self.isCorrect = isCorrect
        self.firstCorrect = firstCorrect
        self.frequency = frequency
        self.relativeFrequency = relativeFrequency
    }
}