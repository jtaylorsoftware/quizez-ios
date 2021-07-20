//
//  AdvancedInteractionTests.swift
//  quizez-iosTests
//
//  Created by Jeremy Taylor on 7/20/21.
//

import XCTest
@testable import quizez_ios

class AdvancedInteractionTests: XCTestCase {
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
    }
    
    func testSocketIOService_IfOwnsSession_CanKickUserFromSession() throws {
        creatorDelegate.kicked = expectation(description: "Socket client kicks user")
        try sessionCreator.kickUser(KickUserRequest(name: joinerUsername))
        wait(for: [creatorDelegate.kicked!], timeout: 5.0)
    }
    
    func testSocketIOService_IfOwnsSession_CanStartOwnSession() throws {
        joinerDelegate.started = expectation(description: "Socket sessionJoiner receives started event")
        creatorDelegate.started = expectation(description: "Socket can start session")
        
        try sessionCreator.startSession()
        wait(for: [creatorDelegate.started!, joinerDelegate.started!], timeout: 5.0)
    }
    
    func testSocketIOService_IfOwnsSession_CanEndOwnSession() throws {
        joinerDelegate.ended = expectation(description: "Socket sessionJoiner receives ended event")
        creatorDelegate.started = expectation(description: "Socket starts session")
        creatorDelegate.ended = expectation(description: "Socket can end session")
  
        try sessionCreator.startSession()
        wait(for: [creatorDelegate.started!], timeout: 5.0)
        
        try sessionCreator.endSession()
        wait(for: [creatorDelegate.ended!, joinerDelegate.ended!], timeout: 5.0)
    }
    
    func testSocketIOService_AllUsers_ReceivesUserDisconnectedForUserInSession() throws {
        creatorDelegate.userDisconnected = expectation(description: "Socket receives userDisconnected for socketJoiner")
        
        try sessionJoiner.disconnect()
        wait(for: [creatorDelegate.userDisconnected!], timeout: 5.0)
    }
    
    func testSocketIOService_IfCreatedSession_CanAddQuestion() throws {
        creatorDelegate.questionAdded = expectation(description: "Socket client can add question to the session")

        let question = Question(text: "Question", body: .fillInTheBlank(answer: "Yes"))
        try sessionCreator.addQuestion(AddQuestionRequest(question: question))
        wait(for: [creatorDelegate.questionAdded!], timeout: 5.0)
    }
    
    func testSocketIOService_IfCreatedSession_CanSendNextFillInQuestion() throws {
        // Add fillin question
        creatorDelegate.questionAdded = expectation(description: "Socket client addd question to the session")
        let fillInQuestion = Question(text: "Question", body: .fillInTheBlank(answer: "Yes"))
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
    
    func testSocketIOService_IfCreatedSession_CanSendNextMultipleChoiceQuestion() throws {
        // Add mc question
        creatorDelegate.questionAdded = expectation(description: "Socket client addd question to the session")
        let mcQuestion = Question(text: "Question", body: .multipleChoice(choices: [.init(text: "1"), .init(text: "2")], answer: 1))
        try sessionCreator.addQuestion(AddQuestionRequest(question: mcQuestion))
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
        // Add question
        creatorDelegate.questionAdded = expectation(description: "Socket client addd question to the session")
        let fillInQuestion = Question(text: "Question", body: .fillInTheBlank(answer: "Yes"))
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

        // Send response
        let response = Response(submitter: joinerUsername, body: .fillInTheBlank("Yes"))
        joinerDelegate.responseSubmitted = expectation(description: "Socket sessionJoiner can send response to the question")
        try sessionJoiner.submitQuestionResponse(SubmitResponseRequest(index: 0, name: joinerUsername, response: response))
        wait(for: [joinerDelegate.responseSubmitted!], timeout: 5.0)
    }
    
    func testSocketIOService_IfCreatedSession_ReceivesSubmittedUserResponse() throws {
        // Add question
        creatorDelegate.questionAdded = expectation(description: "Socket client addd question to the session")
        let fillInQuestion = Question(text: "Question", body: .fillInTheBlank(answer: "Yes"))
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

        // Send response
        let response = Response(submitter: joinerUsername, body: .fillInTheBlank("Yes"))
        joinerDelegate.responseSubmitted = expectation(description: "Socket sessionJoiner can send response to the question")
        creatorDelegate.responseAdded = expectation(description: "Session creator receives graded added response")
        try sessionJoiner.submitQuestionResponse(SubmitResponseRequest(index: 0, name: joinerUsername, response: response))
        wait(for: [joinerDelegate.responseSubmitted!, creatorDelegate.responseAdded!], timeout: 5.0)
    }
}
