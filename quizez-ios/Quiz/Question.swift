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
    
    init(text: String, body: MultipleChoiceQuestionBody) throws {
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
    
    init(answer: String) throws {
        guard !answer.isEmpty else {
            throw QuestionBodyError.answerTextEmpty
        }
        self.answer = answer
    }
}
