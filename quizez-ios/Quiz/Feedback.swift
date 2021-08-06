//
//  Feedback.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 8/6/21.
//

import Foundation

/// User submitted feedback for a Quiz Question
struct Feedback : Encodable {
    static let maxMessageCharacters = 100
    
    /// A rating value indicating question difficulty
    let rating: Rating
    
    /// An associated message describing the user's reasoning
    let message: String
    
    enum Rating: Int, Encodable {
        case Impossible, Hard, Okay, Simple, Easy
    }
}

extension Feedback {
    /// Validates this Feedback's message data.
    /// - Returns: List of validation constraints failed.
    func validate() -> [FeedbackValidationConstraint] {
        var errors = [FeedbackValidationConstraint]()
        if message.count > Self.maxMessageCharacters {
            errors.append(.messageTooLong)
        }
        return errors
    }
}

enum FeedbackValidationConstraint: Equatable {
    /// The message must be less than 100 characters
    case messageTooLong
}
