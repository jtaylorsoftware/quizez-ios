//
//  SocketIOService_iosTests.swift
//  quizez-iosTests
//
//  Created by Jeremy Taylor on 7/16/21.
//

import XCTest
@testable import quizez_ios

class SocketIOService_iosTests: XCTestCase {
    var socketService: SocketService!
    var delegate: SocketServiceDelegateMock!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        socketService = try SocketIOService(url: "http://localhost:30000")
        delegate = SocketServiceDelegateMock()
        socketService.delegate = delegate
        delegate.connected = expectation(description: "Socket client connects to server")
    }

    func testSocketIOService_CanConnect()  {
        try! socketService.connect()

        wait(for: [delegate.connected!], timeout: 5.0)
    }

    func testSocketIOService_CanCreateSession() {
        delegate.createdSession = expectation(description: "Socket client can create session and get its id")

        try! socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try! socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
    }
    
    func testSocketIOService_GetsDisconnectReasonForSelfDisconnect() {
        delegate.disconnected = expectation(description: "Socket client disconnects from server")
        
        try! socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try! socketService.disconnect()
        wait(for: [delegate.disconnected!], timeout: 5.0)
    }
    
    func testSocketIOService_CanJoinOtherSession() throws {
        // Set up a socket to create a session to get its id
        let sessionCreator = try SocketIOService(url: "http://localhost:30000")
        let sessionCreatorDelegate = SocketServiceDelegateMock()
        sessionCreatorDelegate.connected = expectation(description: "Socket sessionCreator connects to server")
        sessionCreatorDelegate.createdSession = expectation(description: "Socket sessionCreator creates session")
        sessionCreatorDelegate.joined = expectation(description: "Socket sessionCreator receives join event for joiner")
        sessionCreator.delegate = sessionCreatorDelegate
        
        try! sessionCreator.connect()
        wait(for: [sessionCreatorDelegate.connected!], timeout: 5.0)
        
        try! sessionCreator.createSession()
        wait(for: [sessionCreatorDelegate.createdSession!], timeout: 5.0)
        
        let sessionId = sessionCreator.sessionId!
        
        // Have client socket join session
        delegate.joined = expectation(description: "Socket client joins session")
        
        try! socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try! socketService.joinSession(JoinSessionRequest(session: sessionId, name: "user"))
        wait(for: [delegate.joined!, sessionCreatorDelegate.joined!], timeout: 5.0)
    }
    
    func testSocketIOService_IfOwnsSession_CanKickUserFromSession() throws {
        // Set up a socket to join the session
        let sessionJoiner = try SocketIOService(url: "http://localhost:30000")
        let sessionJoinerDelegate = SocketServiceDelegateMock()
        sessionJoinerDelegate.connected = expectation(description: "Socket sessionJoiner connects to server")
        sessionJoinerDelegate.joined = expectation(description: "Socket sessionJoiner joins session")
        sessionJoiner.delegate = sessionJoinerDelegate
        
        try! sessionJoiner.connect()
        wait(for: [sessionJoinerDelegate.connected!], timeout: 5.0)
        
        // Wait for main socket to connect and create session
        delegate.createdSession = expectation(description: "Socket client creates session and gets its id")

        try! socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try! socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
        let sessionId = socketService.sessionId!
        
        // Join session so they can be kicked
        let userName = "user"
        try! sessionJoiner.joinSession(JoinSessionRequest(session: sessionId, name: userName))
        wait(for: [sessionJoinerDelegate.joined!], timeout: 5.0)
        
        // Kick user
        delegate.kicked = expectation(description: "Socket client kicks user")
        try! socketService.kickUser(KickUserRequest(name: userName))
        wait(for: [delegate.kicked!], timeout: 5.0)
    }
    
    func testSocketIOService_IfOwnsSession_CanStartOwnSession() throws {
        // Set up a socket to join the session so they can get the started event
        let sessionJoiner = try SocketIOService(url: "http://localhost:30000")
        let sessionJoinerDelegate = SocketServiceDelegateMock()
        sessionJoinerDelegate.connected = expectation(description: "Socket sessionJoiner connects to server")
        sessionJoinerDelegate.joined = expectation(description: "Socket sessionJoiner joins session")
        sessionJoinerDelegate.started = expectation(description: "Socket sessionJoiner receives started event")
        sessionJoiner.delegate = sessionJoinerDelegate
        
        try! sessionJoiner.connect()
        wait(for: [sessionJoinerDelegate.connected!], timeout: 5.0)
        
        delegate.createdSession = expectation(description: "Socket creates session")
        delegate.started = expectation(description: "Socket can start session")
        
        try! socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try! socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
        
        // Join session so they can receive messages
        let userName = "user"
        try! sessionJoiner.joinSession(JoinSessionRequest(session: socketService.sessionId!, name: userName))
        wait(for: [sessionJoinerDelegate.joined!], timeout: 5.0)
        
        try! socketService.startSession()
        wait(for: [delegate.started!, sessionJoinerDelegate.started!], timeout: 5.0)
    }
    
    func testSocketIOService_IfOwnsSession_CanEndOwnSession() throws {
        // Set up a socket to join the session so they can get the ended event
        let sessionJoiner = try SocketIOService(url: "http://localhost:30000")
        let sessionJoinerDelegate = SocketServiceDelegateMock()
        sessionJoinerDelegate.connected = expectation(description: "Socket sessionJoiner connects to server")
        sessionJoinerDelegate.joined = expectation(description: "Socket sessionJoiner joins session")
        sessionJoinerDelegate.ended = expectation(description: "Socket sessionJoiner receives ended event")
        sessionJoiner.delegate = sessionJoinerDelegate
        
        try! sessionJoiner.connect()
        wait(for: [sessionJoinerDelegate.connected!], timeout: 5.0)
        
        delegate.createdSession = expectation(description: "Socket creates session")
        delegate.started = expectation(description: "Socket starts session")
        delegate.ended = expectation(description: "Socket can end session")
        
        try! socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try! socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
        
        // Join session so they can receive messages
        let userName = "user"
        try! sessionJoiner.joinSession(JoinSessionRequest(session: socketService.sessionId!, name: userName))
        wait(for: [sessionJoinerDelegate.joined!], timeout: 5.0)
        
        try! socketService.startSession()
        wait(for: [delegate.started!], timeout: 5.0)
        
        try! socketService.endSession()
        wait(for: [delegate.ended!, sessionJoinerDelegate.ended!], timeout: 5.0)
    }
    
    func testSocketIOService_AllUsers_ReceivesUserDisconnectedForUserInSession() throws {
        // Set up socket to join and disconnect
        let sessionJoiner = try SocketIOService(url: "http://localhost:30000")
        let sessionJoinerDelegate = SocketServiceDelegateMock()
        sessionJoinerDelegate.connected = expectation(description: "Socket sessionJoiner connects to server")
        sessionJoinerDelegate.joined = expectation(description: "Socket sessionJoiner joins session")
        sessionJoiner.delegate = sessionJoinerDelegate
        
        try! sessionJoiner.connect()
        wait(for: [sessionJoinerDelegate.connected!], timeout: 5.0)
        
        delegate.createdSession = expectation(description: "Socket creates session")
        delegate.userDisconnected = expectation(description: "Socket receives userDisconnected for socketJoiner")
        
        try! socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try! socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
        
        // Join session and then disconnect
        let userName = "user"
        try! sessionJoiner.joinSession(JoinSessionRequest(session: socketService.sessionId!, name: userName))
        wait(for: [sessionJoinerDelegate.joined!], timeout: 5.0)
        
        try! sessionJoiner.disconnect()
        wait(for: [delegate.userDisconnected!], timeout: 5.0)
    }
    
    func testSocketIOService_IfCreatedSession_CanAddQuestion() {
        delegate.createdSession = expectation(description: "Socket client can create session and get its id")
        delegate.questionAdded = expectation(description: "Socket client can add question to the session")

        try! socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try! socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
        
        let question = try! FillInTheBlankQuestion(text: "Question", body: .init(answer: "Yes"))
        try! socketService.addQuestion(AddQuestionRequest(question: question))
        wait(for: [delegate.questionAdded!], timeout: 5.0)
    }
    
    func testSocketIOService_IfCreatedSession_CanSendNextQuestion() throws {
        // Set up a socket to join the session so they can get the started event
        let sessionJoiner = try SocketIOService(url: "http://localhost:30000")
        let sessionJoinerDelegate = SocketServiceDelegateMock()
        sessionJoinerDelegate.connected = expectation(description: "Socket sessionJoiner connects to server")
        sessionJoinerDelegate.joined = expectation(description: "Socket sessionJoiner joins session")
        sessionJoiner.delegate = sessionJoinerDelegate
        
        // Connect and create session
        try! socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try! socketService.createSession()
        delegate.createdSession = expectation(description: "Socket client creates session")
        wait(for: [delegate.createdSession!], timeout: 5.0)
        
        // Join session so they can receive messages
        try! sessionJoiner.connect()
        wait(for: [sessionJoinerDelegate.connected!], timeout: 5.0)
        
        let userName = "user"
        try! sessionJoiner.joinSession(JoinSessionRequest(session: socketService.sessionId!, name: userName))
        wait(for: [sessionJoinerDelegate.joined!], timeout: 5.0)
        
        // Add fillin question
        delegate.questionAdded = expectation(description: "Socket client addd question to the session")
        let fillInQuestion = try! FillInTheBlankQuestion(text: "Question", body: .init(answer: "Yes"))
        try! socketService.addQuestion(AddQuestionRequest(question: fillInQuestion))
        wait(for: [delegate.questionAdded!], timeout: 5.0)
        
        // Add mc question
        delegate.questionAdded = expectation(description: "Socket client addd question to the session")
        let mcQuestion = try! MultipleChoiceQuestion(text: "Question", body: .init(choices: [.init(text: "1"), .init(text: "2")], answer: 1))
        try! socketService.addQuestion(AddQuestionRequest(question: mcQuestion))
        wait(for: [delegate.questionAdded!], timeout: 5.0)
        
        // Start session
        delegate.started = expectation(description: "Socket client starts session")
        try! socketService.startSession()
        wait(for: [delegate.started!], timeout: 5.0)
        
        // Push first next question
        delegate.nextQuestion = expectation(description: "Session creator receives first next question event")
        sessionJoinerDelegate.nextQuestion = expectation(description: "Socket sessionJoiner receives first next question event")
        try! socketService.pushNextQuestion()
        wait(for: [delegate.nextQuestion!, sessionJoinerDelegate.nextQuestion!], timeout: 5.0)
        
        // Push first next question
        delegate.nextQuestion = expectation(description: "Session creator receives second next question event")
        sessionJoinerDelegate.nextQuestion = expectation(description: "Socket sessionJoiner receives second next question event")
        try! socketService.pushNextQuestion()
        wait(for: [delegate.nextQuestion!, sessionJoinerDelegate.nextQuestion!], timeout: 5.0)
    }
    
    func testSocketIOService_CanSubmitQuestionResponse() throws {
        // Set up a socket to join the session so they can get the started event and submit response
        let sessionJoiner = try SocketIOService(url: "http://localhost:30000")
        let sessionJoinerDelegate = SocketServiceDelegateMock()
        sessionJoinerDelegate.connected = expectation(description: "Socket sessionJoiner connects to server")
        sessionJoinerDelegate.joined = expectation(description: "Socket sessionJoiner joins session")
        sessionJoiner.delegate = sessionJoinerDelegate
        
        // Connect and create session
        try! socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try! socketService.createSession()
        delegate.createdSession = expectation(description: "Socket client creates session")
        wait(for: [delegate.createdSession!], timeout: 5.0)
        
        // Join session so they can receive messages
        try! sessionJoiner.connect()
        wait(for: [sessionJoinerDelegate.connected!], timeout: 5.0)
        
        let userName = "user"
        try! sessionJoiner.joinSession(JoinSessionRequest(session: socketService.sessionId!, name: userName))
        wait(for: [sessionJoinerDelegate.joined!], timeout: 5.0)
        
        // Add question
        delegate.questionAdded = expectation(description: "Socket client addd question to the session")
        let fillInQuestion = try! FillInTheBlankQuestion(text: "Question", body: .init(answer: "Yes"))
        try! socketService.addQuestion(AddQuestionRequest(question: fillInQuestion))
        wait(for: [delegate.questionAdded!], timeout: 5.0)
        
        // Start session
        delegate.started = expectation(description: "Socket client starts session")
        try! socketService.startSession()
        wait(for: [delegate.started!], timeout: 5.0)
        
        // Push next question
        delegate.nextQuestion = expectation(description: "Session creator receives first next question event")
        sessionJoinerDelegate.nextQuestion = expectation(description: "Socket sessionJoiner receives first next question event")
        try! socketService.pushNextQuestion()
        wait(for: [delegate.nextQuestion!, sessionJoinerDelegate.nextQuestion!], timeout: 5.0)

        // Send response
        let response = try! FillInTheBlankResponse(submitter: userName, text: "Yes")
        sessionJoinerDelegate.responseSubmitted = expectation(description: "Socket sessionJoiner can send response to the question")
        try! sessionJoiner.submitQuestionResponse(SubmitResponseRequest(index: 0, name: userName, response: response))
        wait(for: [sessionJoinerDelegate.responseSubmitted!], timeout: 5.0)
    }
    
    func testSocketIOService_IfCreatedSession_ReceivesSubmittedUserResponse() throws {
        // Set up a socket to join the session so they can get the started event and submit response
        let sessionJoiner = try SocketIOService(url: "http://localhost:30000")
        let sessionJoinerDelegate = SocketServiceDelegateMock()
        sessionJoinerDelegate.connected = expectation(description: "Socket sessionJoiner connects to server")
        sessionJoinerDelegate.joined = expectation(description: "Socket sessionJoiner joins session")
        sessionJoiner.delegate = sessionJoinerDelegate
        
        // Connect and create session
        try! socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try! socketService.createSession()
        delegate.createdSession = expectation(description: "Socket client creates session")
        wait(for: [delegate.createdSession!], timeout: 5.0)
        
        // Join session so they can receive messages
        try! sessionJoiner.connect()
        wait(for: [sessionJoinerDelegate.connected!], timeout: 5.0)
        
        let userName = "user"
        try! sessionJoiner.joinSession(JoinSessionRequest(session: socketService.sessionId!, name: userName))
        wait(for: [sessionJoinerDelegate.joined!], timeout: 5.0)
        
        // Add question
        delegate.questionAdded = expectation(description: "Socket client addd question to the session")
        let fillInQuestion = try! FillInTheBlankQuestion(text: "Question", body: .init(answer: "Yes"))
        try! socketService.addQuestion(AddQuestionRequest(question: fillInQuestion))
        wait(for: [delegate.questionAdded!], timeout: 5.0)
        
        // Start session
        delegate.started = expectation(description: "Socket client starts session")
        try! socketService.startSession()
        wait(for: [delegate.started!], timeout: 5.0)
        
        // Push next question
        delegate.nextQuestion = expectation(description: "Session creator receives first next question event")
        sessionJoinerDelegate.nextQuestion = expectation(description: "Socket sessionJoiner receives first next question event")
        try! socketService.pushNextQuestion()
        wait(for: [delegate.nextQuestion!, sessionJoinerDelegate.nextQuestion!], timeout: 5.0)

        // Send response
        let response = try! FillInTheBlankResponse(submitter: userName, text: "Yes")
        sessionJoinerDelegate.responseSubmitted = expectation(description: "Socket sessionJoiner can send response to the question")
        delegate.responseAdded = expectation(description: "Session creator receives graded added response")
        try! sessionJoiner.submitQuestionResponse(SubmitResponseRequest(index: 0, name: userName, response: response))
        wait(for: [sessionJoinerDelegate.responseSubmitted!, delegate.responseAdded!], timeout: 5.0)
    }
}
