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

    override func onConnected() {
        connected?.fulfill()
    }
    
    override func onCreatedSession(_ result: SocketResult<CreatedSession>) {
        guard let exp = createdSession else { return }
        
        if case let .success(response) = result {
            XCTAssert(response.id.count != 0, "Response id should have non-zero length")
            exp.fulfill()
        } else {
            XCTAssert(false, "Response should have data")
            exp.fulfill()
        }
    }
    
    override func onDisconnected(_ reason: String) {
        guard let exp = disconnected else { return }
        XCTAssert(reason.count > 0, "Disconnect reason should be non-zero length")
        XCTAssert(reason != "unknown", "Reason should not be unknown")
        exp.fulfill()
    }
    
    override func onSessionJoined(_ result: SocketServiceDelegate.SocketResult<Void>) {
        guard let exp = joined else { return }
        if case .success(_) = result {
            exp.fulfill()
        } else {
            XCTAssert(false, "Join should succeed")
            exp.fulfill()
        }
    }
}
