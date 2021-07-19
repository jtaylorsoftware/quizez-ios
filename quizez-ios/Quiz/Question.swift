//
//  Question.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/17/21.
//

import Foundation

/// A Question for a quiz - can be one of multiple types
protocol Question: Encodable {
    /// The Question text
    var text: String { get }
    
    /// The body of the Question
    var body: QuestionBody { get }
}

/// The body of a Question, containing the submitter and question data
protocol QuestionBody: Encodable {
}

enum QuestionType: String, Encodable {
    case multipleChoice = "MultipleChoice"
    case fillInTheBlank = "FillIn"
}

/// Errors thrown creating a Question
enum QuestionError: Error {
    /// Could not initialize the Question because the question text is empty
    case textEmpty
}

/// Errors thrown creating a QuestionBody
enum QuestionBodyError: Error {
    /// Could not initialize the MultipleChoiceQuestionBody because it has too few or many choices
    case choicesOutOfExpectedRange
    
    /// Could not initialize the MultipleChoiceQuestionBody because its answer is not in the choices.count range
    case answerOutOfBounds
    
    /// Could not initialize the QuestionBody because an answer is empty
    case answerTextEmpty
}

/// A Question with multiple choices
struct MultipleChoiceQuestion : Question {
    let text: String
    private let _body: MultipleChoiceQuestionBody
    var body: QuestionBody {
        self._body as QuestionBody
    }
    
    /// Creates a MultipleChoiceQuestion
    /// - Parameters:
    ///     - text: The top-level question text
    ///     - body: The content of the question
    /// - Throws:
    ///     - `QuestionError.textEmpty` if text is empty
    init(text: String, body: MultipleChoiceQuestionBody) throws {
        // Throw instead of returning nil so error reason is explicit
        guard !text.isEmpty else {
            throw QuestionError.textEmpty
        }
        
        self.text = text
        self._body = body
    }
}

/// A Question with one answer that users try to figure out
struct FillInTheBlankQuestion : Question {
    let text: String
    private let _body: FillInTheBlankQuestionBody
    var body: QuestionBody {
        self._body as QuestionBody
    }
    
    /// Creates a FillInTheBlankQuestion
    /// - Parameters:
    ///     - text: The top-level question text
    ///     - body: The content of the question
    /// - Throws:
    ///     - `QuestionError.textEmpty` if text is empty
    init(text: String, body: FillInTheBlankQuestionBody) throws {
        guard !text.isEmpty else {
            throw QuestionError.textEmpty
        }
        
        self.text = text
        self._body = body
    }
}

struct MultipleChoiceQuestionBody : QuestionBody {
    let choices: [Choice]
    let answer: Int
    
    struct Choice: Encodable {
        let text: String
    }
    
    /// Creates the body for a MultipleChoiceQuestion
    /// - Parameters:
    ///     - choices: List of choices for the question. Should be between 2 and 4, inclusive.
    ///     - answer: The index of the choice that is the correct anser to the question. Should be in `[0, choices.count)`
    /// - Throws:
    ///     - `QuestionBodyError.choicesOutOfExpectedRange`if incorrect number of choices
    ///     - `QuestionBodyError.answerOutOfBounds` if `answer < 0 || answer > choices.count`
    ///     - `QuestionBodyError.answerTextEmpty` if any choice's text is empty
    init(choices: [Choice], answer: Int) throws {
        guard choices.count >= 2, choices.count <= 4 else {
            throw QuestionBodyError.choicesOutOfExpectedRange
        }
        guard answer >= 0, answer < choices.count else {
            throw QuestionBodyError.answerOutOfBounds
        }
        for choice in choices {
            if choice.text.isEmpty {
                throw QuestionBodyError.answerTextEmpty
            }
        }
        self.choices = choices
        self.answer = answer
    }
}

struct FillInTheBlankQuestionBody : QuestionBody {
    let answer: String
    
    /// Creates the body for a FillInTheBlankQuestion
    /// - Parameters:
    ///     - answer: The expected answer used to check submissions
    /// - Throws:
    ///     - `QuestionBodyError.answerTextEmpty` if the answer text is empty
    init(answer: String) throws {
        guard !answer.isEmpty else {
            throw QuestionBodyError.answerTextEmpty
        }
        self.answer = answer
    }
}
