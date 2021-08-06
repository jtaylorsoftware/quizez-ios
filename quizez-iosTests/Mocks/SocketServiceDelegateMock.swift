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
    var questionAdded: XCTestExpectation?
    var nextQuestion: XCTestExpectation?
    var responseSubmitted: XCTestExpectation?
    var responseAdded: XCTestExpectation?
    var feedbackSubmitted: XCTestExpectation?
    var feedbackReceived: XCTestExpectation?

    func onConnected() {
        connected?.fulfill()
    }
    
    func onCreatedSession(_ result: SocketResult<CreatedSession>) {
        guard let exp = createdSession else { return }
        
        if case let .success(response) = result {
            XCTAssert(!response.session.isEmpty, "Response id should have non-zero length")
        } else {
            XCTAssert(false, "Response should have data")
        }
        exp.fulfill()
    }
    
    func onDisconnected(_ reason: String) {
        guard let exp = disconnected else { return }
        XCTAssert(!reason.isEmpty, "Disconnect reason should be non-zero length")
        XCTAssert(reason != "unknown", "Reason should not be unknown")
        exp.fulfill()
    }
    
    func onSessionJoined(_ result: SocketResult<UserJoined>) {
        guard let exp = joined else { return }
        if case .failure(_) = result {
            XCTAssert(false, "Join should succeed")
        }
        exp.fulfill()
    }
    
    func onUserKicked(_ result: SocketResult<KickedUser>) {
        guard let exp = kicked else { return }
        if case let .success(kickedUser) = result {
            XCTAssert(!kickedUser.session.isEmpty, "Kicked session ID should not be empty")
            XCTAssert(!kickedUser.name.isEmpty, "Kicked user name should not be empty")
        } else {
            XCTAssert(false, "Kick should succeed")
        }
        exp.fulfill()
    }
    
    func onSessionStarted(_ result: SocketResult<Void>) {
        guard let exp = started else { return }
        if case .failure(_) = result {
            XCTAssert(false, "Start should succeed")
        }
        exp.fulfill()
    }
    
    func onSessionEnded(_ result: SocketResult<Void>) {
        guard let exp = ended else { return }
        if case .failure(_) = result {
            XCTAssert(false, "End should succeed")
        }
        exp.fulfill()
    }
    
    func onUserDisconnected(_ result: SocketResult<UserDisconnected>) {
        guard let exp = userDisconnected else { return }
        if case .failure(_) = result {
            XCTAssert(false, "UserDisconnected should succeed with data")
        }
        exp.fulfill()
    }
    
    func onQuestionAdded(_ result: SocketResult<Void>) {
        guard let exp = questionAdded else { return }
        if case .failure(_) = result {
            XCTAssert(false, "QuestionAdded should succeed")
        }
        exp.fulfill()
    }
    
    func onNextQuestion(_ result: SocketResult<NextQuestion>) {
        guard let exp = nextQuestion else { return }
        if case .failure(_) = result {
            XCTAssert(false, "NextQuestion should succeed at parsing returned data")
        }
        exp.fulfill()
    }
    
    func onQuestionResponseSubmitted(_ result: SocketResult<QuestionResponseSubmitted>) {
        guard let exp = responseSubmitted else { return }
        if case .failure(_) = result {
            XCTAssert(false, "QuestionResponseSubmitted should succeed at parsing returned data")
        }
        exp.fulfill()
    }
    
    func onQuestionResponseAdded(_ result: SocketResult<QuestionResponseAdded>) {
        guard let exp = responseAdded else { return }
        if case .failure(_) = result {
            XCTAssert(false, "QuestionResponseSubmitted should succeed at parsing returned data")
        }
        exp.fulfill()
    }
    
    func onQuestionFeedbackSubmitted(_ result: SocketResult<FeedbackSubmitted>) {
        guard let exp = feedbackSubmitted else { return }
        if case .failure(_) = result {
            XCTAssert(false, "QuestionFeedbackSubmitted should succeed at parsing returned data")
        }
        exp.fulfill()
    }
    
    func onQuestionFeedbackReceived(_ result: SocketResult<FeedbackReceived>) {
        guard let exp = feedbackReceived else { return }
        if case .failure(_) = result {
            XCTAssert(false, "QuestionFeedbackReceived should succeed at parsing returned data")
        }
        exp.fulfill()
    }
}
