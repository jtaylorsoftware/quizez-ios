//
//  QuestionTests.swift
//  quizez-iosTests
//
//  Created by Jeremy Taylor on 7/17/21.
//

import XCTest
@testable import quizez_ios

class QuestionTests: XCTestCase {
    func testQuestion_MultipleChoice_AllInvalidProperties_ValidateContainsAllErrors() {
        let question = Question(text: "", timeLimit: -1, body: .multipleChoice(choices: [.init(text: "", points: -1)], answer: -1))
        let failedConstraints = question.validate()
        
        XCTAssertFalse(failedConstraints.isEmpty)
        XCTAssertTrue(failedConstraints.contains(.answerWithinBounds))
        XCTAssertTrue(failedConstraints.contains(.choiceTextNotEmpty(index: 0)))
        XCTAssertTrue(failedConstraints.contains(.textNotEmpty))
        XCTAssertTrue(failedConstraints.contains(.choicesInExpectedRange))
        XCTAssertTrue(failedConstraints.contains(.pointsNotNegative(index: 0)))
        XCTAssertTrue(failedConstraints.contains(.totalPointsInExpectedRange))
        XCTAssertTrue(failedConstraints.contains(.timeLimitInExpectedRange))
    }
    
    func testQuestion_MultipleChoice_OneChoices_ValidateContainsChoicesInExpectedRange() {
        let question = Question(text: "Text", body: .multipleChoice(choices: [.init(text: "Text", points: 100)], answer: 0))
        let failedConstraints = question.validate()
        
        XCTAssertFalse(failedConstraints.isEmpty)
        XCTAssertTrue(failedConstraints.contains(.choicesInExpectedRange))
    }
    
    func testQuestion_MultipleChoice_FiveChoices_ValidateContainsChoicesInExpectedRange() {
        let choices = (0..<5).map { Question.Body.Choice(text: String($0), points: $0 * 100) }
        let question = Question(text: "Text", body: .multipleChoice(choices: choices, answer: 0))
        let failedConstraints = question.validate()
        
        XCTAssertFalse(failedConstraints.isEmpty)
        XCTAssertTrue(failedConstraints.contains(.choicesInExpectedRange))
    }
    
    func testQuestion_MultipleChoice_NegativeAnswer_ValidateContainsAnswerWithinBounds() {
        let choices = (0..<4).map { Question.Body.Choice(text: String($0), points: $0 * 100) }
        let question = Question(text: "Text", body: .multipleChoice(choices: choices, answer: -1))
        let failedConstraints = question.validate()
        
        XCTAssertFalse(failedConstraints.isEmpty)
        XCTAssertTrue(failedConstraints.contains(.answerWithinBounds))
    }
    
    func testQuestion_MultipleChoice_OutOfBoundsAnswer_ValidateContainsAnswerWithinBounds() {
        let choices = (0..<4).map { Question.Body.Choice(text: String($0), points: $0 * 100) }
        let question = Question(text: "Text", body: .multipleChoice(choices: choices, answer: choices.count))
        let failedConstraints = question.validate()
        
        XCTAssertFalse(failedConstraints.isEmpty)
        XCTAssertTrue(failedConstraints.contains(.answerWithinBounds))
    }
    
    func testQuestion_MultipleChoice_AllValid_ValidatePasses() {
        let choices = (0..<4).map { Question.Body.Choice(text: String($0), points: $0 * 100) }
        let question = Question(text: "Text", body: .multipleChoice(choices: choices, answer: 1))
        let failedConstraints = question.validate()
        
        XCTAssertTrue(failedConstraints.isEmpty)
    }
    
    func testQuestion_FillIn_AllInvalid_ValidateContainsAllErrors() {
        let question = Question(text: "", timeLimit: -1, body: .fillInTheBlank(answers: [.init(text: "", points: -1)]))
        let failedConstraints = question.validate()
        
        XCTAssertFalse(failedConstraints.isEmpty)
        XCTAssertTrue(failedConstraints.contains(.textNotEmpty))
        XCTAssertTrue(failedConstraints.contains(.answerTextNotEmpty(index: 0)))
        XCTAssertTrue(failedConstraints.contains(.pointsNotNegative(index: 0)))
        XCTAssertTrue(failedConstraints.contains(.totalPointsInExpectedRange))
        XCTAssertTrue(failedConstraints.contains(.timeLimitInExpectedRange))
    }
    
    func testQuestion_FillIn_AllValid_ValidatePasses() {
        let question = Question(text: "Text", body: .fillInTheBlank(answers: [.init(text: "Text", points: 100)]))
        let failedConstraints = question.validate()
        
        XCTAssertTrue(failedConstraints.isEmpty)
    }
}
