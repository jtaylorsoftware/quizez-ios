//
//  ResponseTests.swift
//  quizez-iosTests
//
//  Created by Jeremy Taylor on 7/20/21.
//

import XCTest
@testable import quizez_ios

class ResponseTests: XCTestCase {
    // A valid multiple choice question
    let mcQuestion = Question(text: "Q1", body: .multipleChoice(choices: [.init(text: "C1", points: 100), .init(text: "C2", points: 100)], answer: 1))
    
    func testResponse_MultipleChoice_AllInvalidProperties_ValidateContainsAllErrors() {
        
        let response = Response(submitter: "", body: .multipleChoice(-1))
        
        let failedConstraints = response.validate(for: mcQuestion)
        XCTAssertFalse(failedConstraints.isEmpty)
        XCTAssertTrue(failedConstraints.contains(.answerWithinBounds))
        XCTAssertTrue(failedConstraints.contains(.submitterNotEmpty))
    }
    
    func testResponse_MultipleChoice_NegativeChoice_ValidateContainsAnswerWithinBounds() {
        
        let response = Response(submitter: "User", body: .multipleChoice(-1))
        let failedConstraints = response.validate(for: mcQuestion)
        XCTAssertTrue(failedConstraints.contains(.answerWithinBounds))
    }
    
    func testResponse_MultipleChoice_ChoiceGreaterThanCount_ValidateContainsAnswerWithinBounds() {
        
        guard case .multipleChoice(let choices, _) = mcQuestion.body else {
            XCTAssert(false)
            return
        }
        
        let response = Response(submitter: "User", body: .multipleChoice(choices.count))
        let failedConstraints = response.validate(for: mcQuestion)
        XCTAssertTrue(failedConstraints.contains(.answerWithinBounds))
    }
    
    func testResponse_MultipleChoice_EmptySubmitter_ValidateContainsSubmitterNotEmpty() {
        
        let response = Response(submitter: "", body: .multipleChoice(0))
        let failedConstraints = response.validate(for: mcQuestion)
        XCTAssertTrue(failedConstraints.contains(.submitterNotEmpty))
    }
    
    func testResponse_MultipleChoice_AllValid_ValidatePasses() {
        
        let response = Response(submitter: "user", body: .multipleChoice(0))
        let failedConstraints = response.validate(for: mcQuestion)
        XCTAssertTrue(failedConstraints.isEmpty)
    }
    
    func testResponse_FillIn_AllInvalidProperties_ValidateContainsAllErrors() {
        
        let response = Response(submitter: "", body: .fillInTheBlank(""))
        
        let failedConstraints = response.validate()
        XCTAssertFalse(failedConstraints.isEmpty)
        XCTAssertTrue(failedConstraints.contains(.answerNotEmpty))
        XCTAssertTrue(failedConstraints.contains(.submitterNotEmpty))
    }
    
    
    func testResponse_FillIn_EmptySubmitter_ValidateContainsSubmitterNotEmpty() {
        
        let response = Response(submitter: "", body: .fillInTheBlank("Answer"))
        let failedConstraints = response.validate()
        XCTAssertTrue(failedConstraints.contains(.submitterNotEmpty))
    }
    
    func testResponse_FillIn_EmptyAnswer_ValidateContainsAnswerNotEmpty() {
        
        let response = Response(submitter: "user", body: .fillInTheBlank(""))
        let failedConstraints = response.validate()
        XCTAssertTrue(failedConstraints.contains(.answerNotEmpty))
    }
    
    func testResponse_FillIn_AllValid_ValidatePasses() {
        
        let response = Response(submitter: "user", body: .fillInTheBlank("Answer"))
        let failedConstraints = response.validate()
        XCTAssertTrue(failedConstraints.isEmpty)
    }
}
