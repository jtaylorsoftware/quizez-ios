//
//  SocketServiceImpl.swift
//  quizez-iosTests
//
//  Created by Jeremy Taylor on 7/16/21.
//

import XCTest
@testable import quizez_ios

class SocketServiceImpl_iosTests: XCTestCase {
    var socketService: SocketService!
    var delegate: SocketServiceDelegateMock!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        socketService = try SocketServiceImpl(url: "http://localhost:30000")
        delegate = SocketServiceDelegateMock()
        socketService.delegate = delegate
        delegate.connected = expectation(description: "Socket client connects to server")
    }

    func testConnect()  {
        socketService.connect()

        wait(for: [delegate.connected!], timeout: 5.0)
    }

    func testCreateSession() {
        delegate.createdSession = expectation(description: "Socket client can create Session and get its id")

        socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
    }
    
    func testGetsDisconnectReason() {
        delegate.disconnected = expectation(description: "Socket client disconnects from server")
        
        socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        socketService.disconnect()
        wait(for: [delegate.disconnected!], timeout: 5.0)
    }
    
    func testCanJoinSession() throws {
        // Set up a socket to create a session to get its id
        let sessionCreator = try SocketServiceImpl(url: "http://localhost:30000")
        let sessionCreatorDelegate = SocketServiceDelegateMock()
        sessionCreatorDelegate.connected = expectation(description: "Socket sessionCreator connects to server")
        sessionCreatorDelegate.createdSession = expectation(description: "Socket sessionCreator creates session")
        sessionCreatorDelegate.joined = expectation(description: "Socket sessionCreator receives join event for joiner")
        sessionCreator.delegate = sessionCreatorDelegate
        
        sessionCreator.connect()
        wait(for: [sessionCreatorDelegate.connected!], timeout: 5.0)
        
        sessionCreator.createSession()
        wait(for: [sessionCreatorDelegate.createdSession!], timeout: 5.0)
        
        let sessionId = sessionCreator.sessionId!
        
        // Have client socket join session
        delegate.joined = expectation(description: "Socket client joins session")
        
        socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        socketService.joinSession(JoinSessionRequest(id: sessionId, name: "user"))
        wait(for: [delegate.joined!, sessionCreatorDelegate.joined!], timeout: 5.0)
    }
    
    func testCanKickUser() throws {
        // Set up a socket to join the session
        let sessionJoiner = try SocketServiceImpl(url: "http://localhost:30000")
        let socketJoinerDelegate = SocketServiceDelegateMock()
        socketJoinerDelegate.connected = expectation(description: "Socket sessionJoiner connects to server")
        socketJoinerDelegate.joined = expectation(description: "Socket sessionJoiner joins session")
        sessionJoiner.delegate = socketJoinerDelegate
        
        sessionJoiner.connect()
        wait(for: [socketJoinerDelegate.connected!], timeout: 5.0)
        
        // Wait for main socket to connect and create session
        delegate.createdSession = expectation(description: "Socket client creates Session and gets its id")

        socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
        let sessionId = socketService.sessionId!
        
        // Join session so they can be kicked
        let userName = "user"
        sessionJoiner.joinSession(JoinSessionRequest(id: sessionId, name: userName))
        wait(for: [socketJoinerDelegate.joined!], timeout: 5.0)
        
        // Kick user
        delegate.kicked = expectation(description: "Socket client kicks user")
        socketService.kickUser(KickUserRequest(session: sessionId, name: userName))
        wait(for: [delegate.kicked!], timeout: 5.0)
    }
    
    func testCanStartSession() throws {
        // Set up a socket to join the session so they can get the started event
        let sessionJoiner = try SocketServiceImpl(url: "http://localhost:30000")
        let socketJoinerDelegate = SocketServiceDelegateMock()
        socketJoinerDelegate.connected = expectation(description: "Socket sessionJoiner connects to server")
        socketJoinerDelegate.joined = expectation(description: "Socket sessionJoiner joins session")
        socketJoinerDelegate.started = expectation(description: "Socket sessionJoiner receives started event")
        sessionJoiner.delegate = socketJoinerDelegate
        
        sessionJoiner.connect()
        wait(for: [socketJoinerDelegate.connected!], timeout: 5.0)
        
        delegate.createdSession = expectation(description: "Socket creates Session")
        delegate.started = expectation(description: "Socket can start Session")
        
        socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
        
        // Join session so they can receive messages
        let userName = "user"
        sessionJoiner.joinSession(JoinSessionRequest(id: socketService.sessionId!, name: userName))
        wait(for: [socketJoinerDelegate.joined!], timeout: 5.0)
        
        socketService.startSession(StartSessionRequest(session: socketService.sessionId!))
        wait(for: [delegate.started!, socketJoinerDelegate.started!], timeout: 5.0)
    }
    
    func testCanEndSession() throws {
        // Set up a socket to join the session so they can get the ended event
        let sessionJoiner = try SocketServiceImpl(url: "http://localhost:30000")
        let socketJoinerDelegate = SocketServiceDelegateMock()
        socketJoinerDelegate.connected = expectation(description: "Socket sessionJoiner connects to server")
        socketJoinerDelegate.joined = expectation(description: "Socket sessionJoiner joins session")
        socketJoinerDelegate.ended = expectation(description: "Socket sessionJoiner receives ended event")
        sessionJoiner.delegate = socketJoinerDelegate
        
        sessionJoiner.connect()
        wait(for: [socketJoinerDelegate.connected!], timeout: 5.0)
        
        delegate.createdSession = expectation(description: "Socket creates Session")
        delegate.started = expectation(description: "Socket starts Session")
        delegate.ended = expectation(description: "Socket can end Session")
        
        socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
        
        // Join session so they can receive messages
        let userName = "user"
        sessionJoiner.joinSession(JoinSessionRequest(id: socketService.sessionId!, name: userName))
        wait(for: [socketJoinerDelegate.joined!], timeout: 5.0)
        
        socketService.startSession(StartSessionRequest(session: socketService.sessionId!))
        wait(for: [delegate.started!], timeout: 5.0)
        
        socketService.endSession(EndSessionRequest(session: socketService.sessionId!))
        wait(for: [delegate.ended!, socketJoinerDelegate.ended!], timeout: 5.0)
    }
    
    func testReceivesUserDisconnected() throws {
        // Set up socket to join and disconnect
        let sessionJoiner = try SocketServiceImpl(url: "http://localhost:30000")
        let socketJoinerDelegate = SocketServiceDelegateMock()
        socketJoinerDelegate.connected = expectation(description: "Socket sessionJoiner connects to server")
        socketJoinerDelegate.joined = expectation(description: "Socket sessionJoiner joins session")
        sessionJoiner.delegate = socketJoinerDelegate
        
        sessionJoiner.connect()
        wait(for: [socketJoinerDelegate.connected!], timeout: 5.0)
        
        delegate.createdSession = expectation(description: "Socket creates Session")
        delegate.userDisconnected = expectation(description: "Socket receives userDisconnected for socketJoiner")
        
        socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
        
        // Join session and then disconnect
        let userName = "user"
        sessionJoiner.joinSession(JoinSessionRequest(id: socketService.sessionId!, name: userName))
        wait(for: [socketJoinerDelegate.joined!], timeout: 5.0)
        
        sessionJoiner.disconnect()
        wait(for: [delegate.userDisconnected!], timeout: 5.0)
    }
}
