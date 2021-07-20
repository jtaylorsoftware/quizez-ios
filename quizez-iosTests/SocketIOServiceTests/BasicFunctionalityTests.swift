//
//  BasicFunctionalityTests.swift
//  quizez-iosTests
//
//  Created by Jeremy Taylor on 7/20/21.
//

import XCTest
@testable import quizez_ios

class BasicFunctionalityTests: XCTestCase {
    var socketService: SocketService!
    var delegate: SocketServiceDelegateMock!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        socketService = try SocketIOService(url: "http://localhost:30000")
        delegate = SocketServiceDelegateMock()
        socketService.delegate = delegate
        delegate.connected = expectation(description: "Socket client connects to server")
    }

    func testSocketIOService_CanConnect() throws {
        try socketService.connect()

        wait(for: [delegate.connected!], timeout: 5.0)
    }

    func testSocketIOService_CanCreateSession() throws {
        delegate.createdSession = expectation(description: "Socket client can create session and get its id")

        try socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
    }
    
    func testSocketIOService_GetsDisconnectReasonForSelfDisconnect() throws {
        delegate.disconnected = expectation(description: "Socket client disconnects from server")
        
        try socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try socketService.disconnect()
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
        
        try sessionCreator.connect()
        wait(for: [sessionCreatorDelegate.connected!], timeout: 5.0)
        
        try sessionCreator.createSession()
        wait(for: [sessionCreatorDelegate.createdSession!], timeout: 5.0)
        
        let sessionId = sessionCreator.sessionId!
        
        // Have client socket join session
        delegate.joined = expectation(description: "Socket client joins session")
        
        try socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        try socketService.joinSession(JoinSessionRequest(session: sessionId, name: "user"))
        wait(for: [delegate.joined!, sessionCreatorDelegate.joined!], timeout: 5.0)
    }
}
