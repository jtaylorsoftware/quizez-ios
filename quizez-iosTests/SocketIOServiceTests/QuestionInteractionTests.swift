//
//  QuestionInteractionTests.swift
//  quizez-iosTests
//
//  Created by Jeremy Taylor on 8/6/21.
//

import XCTest
@testable import quizez_ios

class QuestionInteractionTests: XCTestCase {
    var sessionCreator: SocketService!
    var creatorDelegate: SocketServiceDelegateMock!
    var sessionJoiner: SocketService!
    var joinerDelegate: SocketServiceDelegateMock!
    let joinerUsername = "user"
    var sessionId: String {
        sessionCreator.sessionId!
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sessionCreator = try SocketIOService(url: "http://localhost:30000")
        creatorDelegate = SocketServiceDelegateMock()
        sessionCreator.delegate = creatorDelegate
        
        // Connect and create session using sessionCreator
        creatorDelegate.connected = expectation(description: "Setup - creator connects to server")
        try sessionCreator.connect()
        wait(for: [creatorDelegate.connected!], timeout: 2.0)
        try sessionCreator.createSession()
        creatorDelegate.createdSession = expectation(description: "Setup - creator creates session and gets its id")
        wait(for: [creatorDelegate.createdSession!], timeout: 2.0)
        
        // Join session using sessionJoiner
        sessionJoiner = try SocketIOService(url: "http://localhost:30000")
        joinerDelegate = SocketServiceDelegateMock()
        joinerDelegate.connected = expectation(description: "Setup - sessionJoiner connects to server")
        joinerDelegate.joined = expectation(description: "Setup - sessionJoiner joins session")
        sessionJoiner.delegate = joinerDelegate
        
        try sessionJoiner.connect()
        wait(for: [joinerDelegate.connected!], timeout: 2.0)
        
        try sessionJoiner.joinSession(JoinSessionRequest(session: sessionId, name: joinerUsername))
        wait(for: [joinerDelegate.joined!], timeout: 5.0)
        
        // Add question
        creatorDelegate.questionAdded = expectation(description: "Socket client addd question to the session")
        let fillInQuestion = Question(text: "Question", body: .fillInTheBlank(answers: [.init(text: "Yes", points: 100)]))
        try sessionCreator.addQuestion(AddQuestionRequest(question: fillInQuestion))
        wait(for: [creatorDelegate.questionAdded!], timeout: 5.0)
        
        // Start session
        creatorDelegate.started = expectation(description: "Socket client starts session")
        try sessionCreator.startSession()
        wait(for: [creatorDelegate.started!], timeout: 5.0)
        
        // Push next question
        creatorDelegate.nextQuestion = expectation(description: "Session creator receives next question event")
        joinerDelegate.nextQuestion = expectation(description: "Socket sessionJoiner receives next question event")
        try sessionCreator.pushNextQuestion()
        wait(for: [creatorDelegate.nextQuestion!, joinerDelegate.nextQuestion!], timeout: 5.0)
    }

    func testSocketIOService_CanSubmitQuestionResponse() throws {
        // Send response
        let response = Response(submitter: joinerUsername, body: .fillInTheBlank("Yes"))
        joinerDelegate.responseSubmitted = expectation(description: "Socket sessionJoiner can send response to the question")
        try sessionJoiner.submitQuestionResponse(SubmitResponseRequest(index: 0, name: joinerUsername, response: response))
        
        // Check if successful
        wait(for: [joinerDelegate.responseSubmitted!], timeout: 5.0)
    }
    
    func testSocketIOService_IfCreatedSession_ReceivesSubmittedUserResponse() throws {
        // Send response
        let response = Response(submitter: joinerUsername, body: .fillInTheBlank("Yes"))
        creatorDelegate.responseAdded = expectation(description: "Session creator receives graded added response")
        try sessionJoiner.submitQuestionResponse(SubmitResponseRequest(index: 0, name: joinerUsername, response: response))
        
        // Check session creator received response
        wait(for: [creatorDelegate.responseAdded!], timeout: 5.0)
    }
    
    func testSocketIOService_CanSubmitQuestionFeedback() throws {
        // Send feedback
        let feedback = Feedback(rating: .Easy, message: "")
        joinerDelegate.feedbackSubmitted = expectation(description: "Socket sessionJoiner can send feedback to the question")
        try sessionJoiner.submitQuestionFeedback(SubmitFeedbackRequest(name: joinerUsername, question: 0, feedback: feedback))
        
        // Check user's submission worked
        wait(for: [joinerDelegate.feedbackSubmitted!], timeout: 5.0)
    }
    
    func testSocketIOService_IfCreatedSession_ReceivesSubmittedFeedback() throws {
        // Send feedback
        let feedback = Feedback(rating: .Easy, message: "")
        creatorDelegate.feedbackReceived = expectation(description: "Socket sessionJoiner receives the feedback submitted to the question")
        try sessionJoiner.submitQuestionFeedback(SubmitFeedbackRequest(name: joinerUsername, question: 0, feedback: feedback))
        
        // Check session creator receives response
        wait(for: [creatorDelegate.feedbackReceived!], timeout: 5.0)
    }
}
