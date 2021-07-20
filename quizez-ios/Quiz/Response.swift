//
//  Response.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/19/21.
//

import Foundation

/// A user-submitted response to a quiz Question
class Response: Encodable {
    /// The name of user submitting response
    private(set) var submitter: String
    
    fileprivate init(submitter: String) {
        self.submitter = submitter
    }
}

class MultipleChoiceResponse : Response {
    /// The index of the selected choice
    let choice: Int
    
    /// Creates a MultipleChoiceResponse for a Question
    /// - Throws:
    ///     - `ResponseError.submitterEmpty` if submitter is empty
    ///     - `ResponseError.choiceOutOfBounds` if choice out of bounds for the question
    init(submitter: String, choice: Int, for question: MultipleChoiceQuestion) throws {
        guard !submitter.isEmpty else {
            throw ResponseError.submitterEmpty
        }
        guard choice >= 0, choice < question.multipleChoiceBody.choices.count else {
            throw ResponseError.choiceOutOfBounds
        }
        
        self.choice = choice
        super.init(submitter: submitter)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(submitter, forKey: .submitter)
        try container.encode(QuestionType.multipleChoice.rawValue, forKey: .type)
        try container.encode(choice, forKey: .choice)
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case submitter
        case choice
    }
}

class FillInTheBlankResponse : Response {
    /// The text the user submited as the answer
    let text: String
    
    /// Creates a MultipleChoiceResponse
    /// - Throws:
    ///     - `ResponseError.submitterEmpty` if submitter is empty
    ///     - `ResponseError.textEmpty` if answer text empty
    init(submitter: String, text: String) throws {
        guard !submitter.isEmpty else {
            throw ResponseError.submitterEmpty
        }
        guard !text.isEmpty else {
            throw ResponseError.textEmpty
        }
        
        self.text = text
        super.init(submitter: submitter)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(submitter, forKey: .submitter)
        try container.encode(QuestionType.fillInTheBlank.rawValue, forKey: .type)
        try container.encode(text, forKey: .text)
    }

    enum CodingKeys: String, CodingKey {
        case type
        case submitter
        case text
    }
}

/// Validation errors when creating a Response for a Question
enum ResponseError : Error {
    /// The submitter is empty
    case submitterEmpty
    
    /// The text of a FillIn is empty
    case textEmpty
    
    /// The choice of a MultipleChoice is out of bounds
    case choiceOutOfBounds
}
