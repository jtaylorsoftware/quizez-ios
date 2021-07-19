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
        try? socketService.connect()

        wait(for: [delegate.connected!], timeout: 5.0)
    }

    func testSocketIOService_CanCreateSession() {
        delegate.createdSession = expectation(description: "Socket client can create session and get its id")

        try? socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try? socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
    }
    
    func testSocketIOService_GetsDisconnectReason_ForSelfDisconnect() {
        delegate.disconnected = expectation(description: "Socket client disconnects from server")
        
        try? socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try? socketService.disconnect()
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
        
        try? sessionCreator.connect()
        wait(for: [sessionCreatorDelegate.connected!], timeout: 5.0)
        
        try? sessionCreator.createSession()
        wait(for: [sessionCreatorDelegate.createdSession!], timeout: 5.0)
        
        let sessionId = sessionCreator.sessionId!
        
        // Have client socket join session
        delegate.joined = expectation(description: "Socket client joins session")
        
        try? socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try? socketService.joinSession(JoinSessionRequest(session: sessionId, name: "user"))
        wait(for: [delegate.joined!, sessionCreatorDelegate.joined!], timeout: 5.0)
    }
    
    func testSocketIOService_CanKickUserFromSession() throws {
        // Set up a socket to join the session
        let sessionJoiner = try SocketIOService(url: "http://localhost:30000")
        let socketJoinerDelegate = SocketServiceDelegateMock()
        socketJoinerDelegate.connected = expectation(description: "Socket sessionJoiner connects to server")
        socketJoinerDelegate.joined = expectation(description: "Socket sessionJoiner joins session")
        sessionJoiner.delegate = socketJoinerDelegate
        
        try? sessionJoiner.connect()
        wait(for: [socketJoinerDelegate.connected!], timeout: 5.0)
        
        // Wait for main socket to connect and create session
        delegate.createdSession = expectation(description: "Socket client creates session and gets its id")

        try? socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try? socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
        let sessionId = socketService.sessionId!
        
        // Join session so they can be kicked
        let userName = "user"
        try? sessionJoiner.joinSession(JoinSessionRequest(session: sessionId, name: userName))
        wait(for: [socketJoinerDelegate.joined!], timeout: 5.0)
        
        // Kick user
        delegate.kicked = expectation(description: "Socket client kicks user")
        try? socketService.kickUser(KickUserRequest(name: userName))
        wait(for: [delegate.kicked!], timeout: 5.0)
    }
    
    func testSocketIOService_CanStartOwnSession() throws {
        // Set up a socket to join the session so they can get the started event
        let sessionJoiner = try SocketIOService(url: "http://localhost:30000")
        let socketJoinerDelegate = SocketServiceDelegateMock()
        socketJoinerDelegate.connected = expectation(description: "Socket sessionJoiner connects to server")
        socketJoinerDelegate.joined = expectation(description: "Socket sessionJoiner joins session")
        socketJoinerDelegate.started = expectation(description: "Socket sessionJoiner receives started event")
        sessionJoiner.delegate = socketJoinerDelegate
        
        try? sessionJoiner.connect()
        wait(for: [socketJoinerDelegate.connected!], timeout: 5.0)
        
        delegate.createdSession = expectation(description: "Socket creates session")
        delegate.started = expectation(description: "Socket can start session")
        
        try? socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try? socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
        
        // Join session so they can receive messages
        let userName = "user"
        try? sessionJoiner.joinSession(JoinSessionRequest(session: socketService.sessionId!, name: userName))
        wait(for: [socketJoinerDelegate.joined!], timeout: 5.0)
        
        try? socketService.startSession()
        wait(for: [delegate.started!, socketJoinerDelegate.started!], timeout: 5.0)
    }
    
    func testSocketIOService_CanEndOwnSession() throws {
        // Set up a socket to join the session so they can get the ended event
        let sessionJoiner = try SocketIOService(url: "http://localhost:30000")
        let socketJoinerDelegate = SocketServiceDelegateMock()
        socketJoinerDelegate.connected = expectation(description: "Socket sessionJoiner connects to server")
        socketJoinerDelegate.joined = expectation(description: "Socket sessionJoiner joins session")
        socketJoinerDelegate.ended = expectation(description: "Socket sessionJoiner receives ended event")
        sessionJoiner.delegate = socketJoinerDelegate
        
        try? sessionJoiner.connect()
        wait(for: [socketJoinerDelegate.connected!], timeout: 5.0)
        
        delegate.createdSession = expectation(description: "Socket creates session")
        delegate.started = expectation(description: "Socket starts session")
        delegate.ended = expectation(description: "Socket can end session")
        
        try? socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try? socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
        
        // Join session so they can receive messages
        let userName = "user"
        try? sessionJoiner.joinSession(JoinSessionRequest(session: socketService.sessionId!, name: userName))
        wait(for: [socketJoinerDelegate.joined!], timeout: 5.0)
        
        try? socketService.startSession()
        wait(for: [delegate.started!], timeout: 5.0)
        
        try? socketService.endSession()
        wait(for: [delegate.ended!, socketJoinerDelegate.ended!], timeout: 5.0)
    }
    
    func testSocketIOService_ReceivesUserDisconnectedForUserInSession() throws {
        // Set up socket to join and disconnect
        let sessionJoiner = try SocketIOService(url: "http://localhost:30000")
        let socketJoinerDelegate = SocketServiceDelegateMock()
        socketJoinerDelegate.connected = expectation(description: "Socket sessionJoiner connects to server")
        socketJoinerDelegate.joined = expectation(description: "Socket sessionJoiner joins session")
        sessionJoiner.delegate = socketJoinerDelegate
        
        try? sessionJoiner.connect()
        wait(for: [socketJoinerDelegate.connected!], timeout: 5.0)
        
        delegate.createdSession = expectation(description: "Socket creates session")
        delegate.userDisconnected = expectation(description: "Socket receives userDisconnected for socketJoiner")
        
        try? socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try? socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
        
        // Join session and then disconnect
        let userName = "user"
        try? sessionJoiner.joinSession(JoinSessionRequest(session: socketService.sessionId!, name: userName))
        wait(for: [socketJoinerDelegate.joined!], timeout: 5.0)
        
        try? sessionJoiner.disconnect()
        wait(for: [delegate.userDisconnected!], timeout: 5.0)
    }
    
    func testSocketIOService_CanAddQuestion() {
        delegate.createdSession = expectation(description: "Socket client can create session and get its id")
        delegate.questionAdded = expectation(description: "Socket client can add question to the session")

        try? socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try? socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
        
        let question = try! FillInTheBlankQuestion(text: "Question", body: .init(answer: "Yes"))
        try! socketService.addQuestion(AddQuestionRequest(text: question.text, body: question.body))
        wait(for: [delegate.questionAdded!], timeout: 5.0)
    }
    
    func testSocketIOService_CanSendNextQuestion() throws {
        // Set up a socket to join the session so they can get the started event
        let sessionJoiner = try SocketIOService(url: "http://localhost:30000")
        let socketJoinerDelegate = SocketServiceDelegateMock()
        socketJoinerDelegate.connected = expectation(description: "Socket sessionJoiner connects to server")
        socketJoinerDelegate.joined = expectation(description: "Socket sessionJoiner joins session")
        sessionJoiner.delegate = socketJoinerDelegate
        
        // Connect and create session
        try? socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try? socketService.createSession()
        delegate.createdSession = expectation(description: "Socket client creates session")
        wait(for: [delegate.createdSession!], timeout: 5.0)
        
        // Join session so they can receive messages
        try? sessionJoiner.connect()
        wait(for: [socketJoinerDelegate.connected!], timeout: 5.0)
        
        let userName = "user"
        try? sessionJoiner.joinSession(JoinSessionRequest(session: socketService.sessionId!, name: userName))
        wait(for: [socketJoinerDelegate.joined!], timeout: 5.0)
        
        // Add fillin question
        delegate.questionAdded = expectation(description: "Socket client addd question to the session")
        let fillInQuestion = try! FillInTheBlankQuestion(text: "Question", body: .init(answer: "Yes"))
        try! socketService.addQuestion(AddQuestionRequest(text: fillInQuestion.text, body: fillInQuestion.body))
        wait(for: [delegate.questionAdded!], timeout: 5.0)
        
        // Add mc question
        delegate.questionAdded = expectation(description: "Socket client addd question to the session")
        let mcQuestion = try! MultipleChoiceQuestion(text: "Question", body: .init(choices: [.init(text: "1"), .init(text: "2")], answer: 1))
        try! socketService.addQuestion(AddQuestionRequest(text: mcQuestion.text, body: mcQuestion.body))
        wait(for: [delegate.questionAdded!], timeout: 5.0)
        
        // Start session
        delegate.started = expectation(description: "Socket client starts session")
        try? socketService.startSession()
        wait(for: [delegate.started!], timeout: 5.0)
        
        // Push first next question
        delegate.nextQuestion = expectation(description: "Session creator receives first next question event")
        socketJoinerDelegate.nextQuestion = expectation(description: "Socket sessionJoiner receives first next question event")
        try? socketService.pushNextQuestion()
        wait(for: [delegate.nextQuestion!, socketJoinerDelegate.nextQuestion!], timeout: 5.0)
        
        // Push first next question
        delegate.nextQuestion = expectation(description: "Session creator receives second next question event")
        socketJoinerDelegate.nextQuestion = expectation(description: "Socket sessionJoiner receives second next question event")
        try? socketService.pushNextQuestion()
        wait(for: [delegate.nextQuestion!, socketJoinerDelegate.nextQuestion!], timeout: 5.0)
    }
}
