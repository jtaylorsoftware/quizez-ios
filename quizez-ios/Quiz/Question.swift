//
//  Question.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/17/21.
//

import Foundation

/// A quiz question
struct Question: Encodable {
    /// The top-level question text
    let text: String
    
    /// The content of the question
    let body: Body
    
    /// Represents the body content for various question types
    enum Body {
        case multipleChoice(choices: [Choice], answer: Int)
        case fillInTheBlank(answer: String)
        
        struct Choice: Encodable {
            let text: String
        }
    }
}

extension Question.Body: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case let .multipleChoice(choices, answer):
            try container.encode(QuestionType.multipleChoice, forKey: .type)
            try container.encode(choices, forKey: .choices)
            try container.encode(answer, forKey: .answer)
        case let .fillInTheBlank(answer):
            try container.encode(QuestionType.fillInTheBlank, forKey: .type)
            try container.encode(answer, forKey: .answer)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case choices
        case answer
    }
}

extension Question {
    /// Validates a Question's text and body.
    /// - Returns: List of validation constraints failed.
    func validate() -> [QuestionValidationConstraint] {
        var errors: [QuestionValidationConstraint] = []
        
        if text.isEmpty {
            errors.append(.textNotEmpty)
        }
        
        switch body {
        case let .multipleChoice(choices, answer):
            if choices.count < 2 || choices.count > 4 {
                errors.append(.choicesInExpectedRange)
            }
            for (index, choice) in choices.enumerated() {
                if choice.text.isEmpty {
                    errors.append(.choiceTextNotEmpty(index: index))
                }
            }
            if answer < 0 || answer >= choices.count {
                errors.append(.answerWithinBounds)
            }
        case let .fillInTheBlank(answer):
            if answer.isEmpty {
                errors.append(.answerTextNotEmpty)
            }
        }
        
        return errors
    }
}

/// Types of Questions that can be used
enum QuestionType: Int, Encodable {
    case multipleChoice = 0
    case fillInTheBlank
}

/// Constraints for validating a Question
enum QuestionValidationConstraint: Equatable {
    /// The multiple choice Question must have between 2 and 4 questions
    case choicesInExpectedRange
    
    /// The multiple choice Question answer must be in the range `[0, choices.count)`
    case answerWithinBounds
    
    /// The text of a multiple choice Question choice must be nonempty
    case choiceTextNotEmpty(index: Int)
    
    /// The answer of a fill in the blank Question must be nonempty
    case answerTextNotEmpty
    
    /// The top-level text of the Question must be nonempty
    case textNotEmpty
}
