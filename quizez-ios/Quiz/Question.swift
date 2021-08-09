//
//  Question.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/17/21.
//

import Foundation

/// A quiz question
struct Question: Encodable {
    static let minTimeLimitSeconds = 60
    static let maxTimeLimitSeconds = 300
    
    /// The top-level question text
    let text: String
    
    /// The amount of time users have to answer the question
    let timeLimit: Int
    
    /// The total amount of points for the Question
    let totalPoints: Int
    
    /// The content of the question
    let body: Body
    
    init(text: String, timeLimit: Int = minTimeLimitSeconds, body: Body) {
        self.text = text
        self.body = body
        self.timeLimit = timeLimit
        self.totalPoints = Self.countPoints(in: body)
    }
    
    private static func countPoints(in body: Body) -> Int {
        switch body {
        case let .multipleChoice(choices, _):
            return choices.reduce(0) { sum, choice in
                return sum + choice.points
            }
        case let .fillInTheBlank(answers):
            return answers.reduce(0) { sum, answer in
                return sum + answer.points
            }
        }
    }
    
    /// Represents the body content for various question types
    enum Body {
        case multipleChoice(choices: [Choice], answer: Int)
        case fillInTheBlank(answers: [Answer])
        
        /// A choice to a multiple choice question
        struct Choice: Encodable {
            let text: String
            let points: Int
        }
        
        /// An acceptable answer for a fillin the blank answer
        struct Answer: Encodable {
            let text: String
            let points: Int
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
        case let .fillInTheBlank(answers):
            try container.encode(QuestionType.fillInTheBlank, forKey: .type)
            try container.encode(answers, forKey: .fillInAnswers)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case choices
        case answer
        case fillInAnswers = "answers"
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
        
        if timeLimit < Question.minTimeLimitSeconds || timeLimit > Question.maxTimeLimitSeconds {
            errors.append(.timeLimitInExpectedRange)
        }
        
        switch body {
        case let .multipleChoice(choices, answer):
            if choices.count < 2 || choices.count > 4 {
                errors.append(.choicesInExpectedRange)
            }
            var totalPoints = 0
            for (index, choice) in choices.enumerated() {
                if choice.text.isEmpty {
                    errors.append(.choiceTextNotEmpty(index: index))
                }
                if choice.points < 0 {
                    errors.append(.pointsNotNegative(index: index))
                } else {
                    totalPoints += choice.points
                }
            }
            if totalPoints < 100 || totalPoints != self.totalPoints {
                errors.append(.totalPointsInExpectedRange)
            }
            if answer < 0 || answer >= choices.count {
                errors.append(.answerWithinBounds)
            }
        case let .fillInTheBlank(answers):
            if answers.count < 1 || answers.count > 3 {
                errors.append(.answersInExpectedRange)
            }
            var totalPoints = 0
            for (index, answer) in answers.enumerated() {
                if answer.text.isEmpty {
                    errors.append(.answerTextNotEmpty(index: index))
                }
                if answer.points < 0 {
                    errors.append(.pointsNotNegative(index: index))
                } else {
                    totalPoints += answer.points
                }
            }
            if totalPoints < 100 || totalPoints != self.totalPoints {
                errors.append(.totalPointsInExpectedRange)
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
    
    /// Fill in questions must have between 1 and 3 acceptable answers
    case answersInExpectedRange
    
    /// The answer of a fill in the blank Question must be nonempty
    case answerTextNotEmpty(index: Int)
    
    /// The top-level text of the Question must be nonempty
    case textNotEmpty
    
    /// The points for any Question answer must be nonnegative
    case pointsNotNegative(index: Int)
    
    /// Any Question must have a total points value greater than some value
    case totalPointsInExpectedRange
    
    /// Time limit must be in expected range
    case timeLimitInExpectedRange
}
