//
//  Question_iosTests.swift
//  quizez-iosTests
//
//  Created by Jeremy Taylor on 7/17/21.
//

import XCTest
@testable import quizez_ios

class Question_iosTests: XCTestCase {
    func testMultipleChoiceQuestion_InitThrows_IfTextEmpty() {
        var err: Error?
        do {
            let _ = try MultipleChoiceQuestion(text: "", body: .init(choices: [.init(text: "1"), .init(text: "2")],answer: 0))
        } catch {
            err = error
        }
        XCTAssertEqual(err as? QuestionError, .textEmpty)
    }
    
    func testMultipleChoiceQuestionBody_InitThrows_IfChoicesEmpty() {
        var err: Error?
        do {
            let _ = try MultipleChoiceQuestionBody(choices: [], answer: 0)
        } catch {
            err = error
        }
        XCTAssertEqual(err as? QuestionBodyError, .choicesOutOfExpectedRange)
    }
    
    func testMultipleChoiceQuestionBody_InitThrows_IfLessThanTwoChoices() {
        var err: Error?
        do {
            let choices: [MultipleChoiceQuestionBody.Choice] = [.init(text: "1")]
            let _ = try MultipleChoiceQuestionBody(choices: choices, answer: 0)
        } catch {
            err = error
        }
        XCTAssertEqual(err as? QuestionBodyError, .choicesOutOfExpectedRange)
    }
    
    func testMultipleChoiceQuestionBody_InitThrows_IfMoreThanFourChoices() {
        var err: Error?
        do {
            let choices: [MultipleChoiceQuestionBody.Choice] = [.init(text: "1"), .init(text: "2"), .init(text: "3"), .init(text: "4"), .init(text: "5")]
            let _ = try MultipleChoiceQuestionBody(choices: choices, answer: 0)
        } catch {
            err = error
        }
        XCTAssertEqual(err as? QuestionBodyError, .choicesOutOfExpectedRange)
    }

    func testMultipleChoiceQuestionBody_InitThrows_IfAnswerNegative() {
        var err: Error?
        do {
            let choices: [MultipleChoiceQuestionBody.Choice] = [.init(text: "1"), .init(text: "2")]
            let _ = try MultipleChoiceQuestionBody(choices: choices, answer: -1)
        } catch {
            err = error
        }
        XCTAssertEqual(err as? QuestionBodyError, .answerOutOfBounds)
    }
    
    func testMultipleChoiceQuestionBody_InitThrows_IfAnswerOutOfRange() {
        var err: Error?
        do {
            let choices: [MultipleChoiceQuestionBody.Choice] = [.init(text: "1"), .init(text: "2"), .init(text: "3"), .init(text: "4")]
            let _ = try MultipleChoiceQuestionBody(choices: choices, answer: 5)
        } catch {
            err = error
        }
        XCTAssertEqual(err as? QuestionBodyError, .answerOutOfBounds)
    }
    
    func testMultipleChoiceQuestionBody_InitThrows_IfAnyChoiceTextIsEmpty() {
        var err: Error?
        do {
            let choices: [MultipleChoiceQuestionBody.Choice] = [.init(text: "1"), .init(text: "")]
            let _ = try MultipleChoiceQuestionBody(choices: choices, answer: 1)
        } catch {
            err = error
        }
        XCTAssertEqual(err as? QuestionBodyError, .answerTextEmpty)
    }
    
    func testFillInQuestion_InitThrows_IfTextEmpty() {
        var err: Error?
        do {
            let _ = try FillInTheBlankQuestion(text: "", body: .init(answer: "Answer"))
        } catch {
            err = error
        }
        XCTAssertEqual(err as? QuestionError, .textEmpty)
    }
    
    func testFillInQuestionBody_InitThrows_IfAnswerEmpty() {
        var err: Error?
        do {
            let _ = try FillInTheBlankQuestion(text: "123", body: .init(answer: ""))
        } catch {
            err = error
        }
        XCTAssertEqual(err as? QuestionBodyError, .answerTextEmpty)
    }
}
