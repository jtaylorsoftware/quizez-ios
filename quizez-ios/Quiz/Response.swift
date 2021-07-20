//
//  Response.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/19/21.
//

import Foundation

/// A response to a question
struct Response {
    /// The name of the submitter
    let submitter: String
    
    /// The content of the response
    let body: Body
    
    /// Represents the response body content for various question types
    enum Body {
        case multipleChoice(Int)
        case fillInTheBlank(String)
    }
}

extension Response: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(submitter, forKey: .submitter)
        switch body {
        case let .multipleChoice(choice):
            try container.encode(QuestionType.multipleChoice, forKey: .type)
            try container.encode(choice, forKey: .answer)
        case let .fillInTheBlank(answer):
            try container.encode(QuestionType.fillInTheBlank, forKey: .type)
            try container.encode(answer, forKey: .answer)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case submitter
        case answer
    }
}

extension Response {
    /// Validates a Response's text and body against a Question
    /// - Parameter question: The Question to validate against
    /// - Returns: List of validation constraints failed.
    func validate(for question: Question? = nil) -> [ResponseValidationConstraint] {
        var errors: [ResponseValidationConstraint] = []
        
        if submitter.isEmpty {
            errors.append(.submitterNotEmpty)
        }
        
        switch body {
        case let .multipleChoice(choice):
            guard let question = question, case .multipleChoice(let choices, _) = question.body else {
                return errors
            }
            if choice < 0 || choice >= choices.count {
                errors.append(.answerWithinBounds)
            }
        case let .fillInTheBlank(answer):
            if answer.isEmpty {
                errors.append(.answerNotEmpty)
            }
        }
        
        return errors
    }
}

/// Validation errors when creating a Response for a Question
enum ResponseValidationConstraint: Equatable {
    /// The submitter must be nonempty
    case submitterNotEmpty
    
    /// The answer of a FillIn must be nonempty
    case answerNotEmpty
    
    /// The choice of a MultipleChoice must be in range `[0, choices.count)`
    case answerWithinBounds
}
