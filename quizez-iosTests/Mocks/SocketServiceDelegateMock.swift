//
//  SocketServiceDelegateMock.swift
//  quizez-iosTests
//
//  Created by Jeremy Taylor on 7/16/21.
//

import Foundation
import XCTest

@testable import quizez_ios

class SocketServiceDelegateMock: SocketServiceDelegate {
    var connected: XCTestExpectation?
    var createdSession: XCTestExpectation?
    var disconnected: XCTestExpectation?
    var joined: XCTestExpectation?
    var kicked: XCTestExpectation?
    var started: XCTestExpectation?
    var ended: XCTestExpectation?
    var userDisconnected: XCTestExpectation?

    override func onConnected() {
        connected?.fulfill()
    }
    
    override func onCreatedSession(_ result: SocketResult<CreatedSession>) {
        guard let exp = createdSession else { return }
        
        if case let .success(response) = result {
            XCTAssert(response.id.count != 0, "Response id should have non-zero length")
        } else {
            XCTAssert(false, "Response should have data")
        }
        exp.fulfill()
    }
    
    override func onDisconnected(_ reason: String) {
        guard let exp = disconnected else { return }
        XCTAssert(reason.count > 0, "Disconnect reason should be non-zero length")
        XCTAssert(reason != "unknown", "Reason should not be unknown")
        exp.fulfill()
    }
    
    override func onSessionJoined(_ result: SocketServiceDelegate.SocketResult<UserJoined>) {
        guard let exp = joined else { return }
        if case .failure(_) = result {
            XCTAssert(false, "Join should succeed")
        }
        exp.fulfill()
    }
    
    override func onUserKicked(_ result: SocketServiceDelegate.SocketResult<KickedUser>) {
        guard let exp = kicked else { return }
        if case let .success(kickedUser) = result {
            XCTAssert(kickedUser.session.count > 0, "Kicked session ID should not be empty")
            XCTAssert(kickedUser.name.count > 0, "Kicked user name should not be empty")
        } else {
            XCTAssert(false, "Kick should succeed")
        }
        exp.fulfill()
    }
    
    override func onSessionStarted(_ result: SocketServiceDelegate.SocketResult<Void>) {
        guard let exp = started else { return }
        if case .failure(_) = result {
            XCTAssert(false, "Start should succeed")
        }
        exp.fulfill()
    }
    
    override func onSessionEnded(_ result: SocketServiceDelegate.SocketResult<Void>) {
        guard let exp = ended else { return }
        if case .failure(_) = result {
            XCTAssert(false, "End should succeed")
        }
        exp.fulfill()
    }
    
    override func onUserDisconnected(_ result: SocketServiceDelegate.SocketResult<UserDisconnected>) {
        guard let exp = userDisconnected else { return }
        if case .failure(_) = result {
            XCTAssert(false, "UserDisconnected should succeed with data")
        }
        exp.fulfill()
    }
}
