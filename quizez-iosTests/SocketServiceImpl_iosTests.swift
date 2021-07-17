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

    func testSocketServiceCanConnect()  {
        socketService.connect()

        wait(for: [delegate.connected!], timeout: 5.0)
    }

    func testSocketServiceCanCreateSession() {
        delegate.createdSession = expectation(description: "Socket client can create Session and get its id")

        socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        socketService.createSession()
        wait(for: [delegate.createdSession!], timeout: 5.0)
    }
    
    func testSocketServiceGetsDisconnectReason() {
        delegate.disconnected = expectation(description: "Socket client disconnects from server")
        
        socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        socketService.disconnect()
        wait(for: [delegate.disconnected!], timeout: 5.0)
    }
    
    func testSocketCanJoinSession() throws {
        // Set up a socket to create a session to get its id
        let sessionCreator = try SocketServiceImpl(url: "http://localhost:30000")
        let sessionCreatorDelegate = SocketServiceDelegateMock()
        sessionCreatorDelegate.connected = expectation(description: "Socket sessionCreator connects to server")
        sessionCreatorDelegate.createdSession = expectation(description: "Socket sessionCreator creates session")
        sessionCreator.delegate = sessionCreatorDelegate
        
        sessionCreator.connect()
        wait(for: [sessionCreatorDelegate.connected!], timeout: 5.0)
        
        sessionCreator.createSession()
        wait(for: [sessionCreatorDelegate.createdSession!], timeout: 5.0)
        
        let sessionId = sessionCreator.sessionId ?? ""
        
        // Have client socket join session
        delegate.joined = expectation(description: "Socket client joins session")
        
        socketService.connect()
        wait(for: [delegate.connected!], timeout: 5.0)
        
        socketService.joinSession(JoinSessionRequest(id: sessionId, name: "user"))
        wait(for: [delegate.joined!], timeout: 5.0)
    }
}
