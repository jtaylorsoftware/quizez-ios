//
//  SocketIOService.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/19/21.
//

import Foundation
import SocketIO

/// SocketService that uses socket.io in its implementation
final class SocketIOService : SocketService {
    var delegate: SocketServiceDelegate = SocketServiceDelegateImpl.default
    
    var isSessionOwner: Bool {
        sessionInfo.isSessionOwner
    }
    var connected: Bool {
        socket.status == .connected
    }
    var username: String? {
        sessionInfo.username
    }
    var sessionId: String? {
        sessionInfo.sessionId
    }
    var sessionHasStarted: Bool {
        sessionInfo.sessionHasStarted
    }
    var sessionHasEnded: Bool {
        sessionInfo.sessionHasEnded
    }
    
    private var manager: SocketManager
    private var socket: SocketIOClient
    private var sessionInfo: SessionInfo
    
    init(url: String) throws {
        var config: SocketIOClientConfiguration = [.log(false)]
        #if LOG_SOCKETIO
        config = [.log(true)]
        #endif
        guard let socketUrl = URL(string: url) else {
            throw SocketError.invalidUrl
        }
        manager = SocketManager(socketURL: socketUrl, config: config)
        socket = manager.defaultSocket
        sessionInfo = SessionInfo()
        registerHandlers()
    }
    
    deinit {
        try? disconnect()
    }
    
    func connect(timeoutAfter: Double = 3.0, onTimeout: (() -> Void)? = nil) throws {
        guard !connected else {
            throw SocketError.alreadyConnected
        }
        socket.connect(timeoutAfter: timeoutAfter, withHandler: onTimeout)
    }
    
    func disconnect() throws {
        guard connected else {
            throw SocketError.notConnected
        }
        socket.disconnect()
    }
    
    func createSession() throws {
        guard connected else {
            throw SocketError.notConnected
        }
        guard sessionInfo.sessionId == nil else {
            throw SocketError.alreadyInSession
        }
        
        socket.emit(CreateNewSessionRequest.eventKey)
    }
    
    func joinSession(_ request: JoinSessionRequest) throws {
        guard connected else {
            throw SocketError.notConnected
        }
        guard sessionInfo.sessionId == nil else {
            throw SocketError.alreadyInSession
        }
        
        sessionInfo.sessionId = request.session
        sessionInfo.username = request.name
        socket.emit(JoinSessionRequest.eventKey, request)
    }
    
    func kickUser(_ request: KickUserRequest) throws {
        guard connected else {
            throw SocketError.notConnected
        }
        guard sessionInfo.isSessionOwner, let session = sessionInfo.sessionId else {
            throw SocketError.notSessionOwner
        }
        
        socket.emit(KickUserRequest.eventKey, request.forSession(session: session))
    }
    
    func startSession() throws {
        guard connected else {
            throw SocketError.notConnected
        }
        guard sessionInfo.isSessionOwner, let session = sessionInfo.sessionId else {
            throw SocketError.notSessionOwner
        }
        
        let request = StartSessionRequest(session: session)
        socket.emit(StartSessionRequest.eventKey, request)
    }
    
    func endSession() throws {
        guard connected else {
            throw SocketError.notConnected
        }
        guard sessionInfo.isSessionOwner, let session = sessionInfo.sessionId else {
            throw SocketError.notSessionOwner
        }
        guard sessionInfo.sessionHasStarted else {
            throw SocketError.sessionNotStarted
        }
        guard !sessionInfo.sessionHasEnded else {
            throw SocketError.sessionEnded
        }
        
        let request = EndSessionRequest(session: session)
        socket.emit(EndSessionRequest.eventKey, request)
    }
    
    func addQuestion(_ request: AddQuestionRequest) throws {
        guard connected else {
            throw SocketError.notConnected
        }
        guard sessionInfo.isSessionOwner, let session = sessionInfo.sessionId else {
            throw SocketError.notSessionOwner
        }
        guard !sessionInfo.sessionHasEnded else {
            throw SocketError.sessionEnded
        }
        
        socket.emit(AddQuestionRequest.eventKey, request.forSession(session: session))
    }
    
    func pushNextQuestion() throws {
        guard connected else {
            throw SocketError.notConnected
        }
        guard sessionInfo.isSessionOwner, let session = sessionInfo.sessionId else {
            throw SocketError.notSessionOwner
        }
        guard sessionInfo.sessionHasStarted else {
            throw SocketError.sessionNotStarted
        }
        guard !sessionInfo.sessionHasEnded else {
            throw SocketError.sessionEnded
        }
        
        let request = NextQuestionRequest(session: session)
        socket.emit(NextQuestionRequest.eventKey, request)
    }
    
    func submitQuestionResponse(_ request: SubmitResponseRequest) throws {
        guard connected else {
            throw SocketError.notConnected
        }
        guard !sessionInfo.isSessionOwner, let session = sessionInfo.sessionId else {
            throw SocketError.didNotJoinSession
        }
        guard sessionInfo.sessionHasStarted else {
            throw SocketError.sessionNotStarted
        }
        guard !sessionInfo.sessionHasEnded else {
            throw SocketError.sessionEnded
        }
        
        socket.emit(SubmitResponseRequest.eventKey, request.forSession(session: session))
    }
    
    func submitQuestionFeedback(_ request: SubmitFeedbackRequest) throws {
        guard connected else {
            throw SocketError.notConnected
        }
        guard !sessionInfo.isSessionOwner, let session = sessionInfo.sessionId else {
            throw SocketError.didNotJoinSession
        }
        guard sessionInfo.sessionHasStarted else {
            throw SocketError.sessionNotStarted
        }
        guard !sessionInfo.sessionHasEnded else {
            throw SocketError.sessionEnded
        }
        
        socket.emit(SubmitFeedbackRequest.eventKey, request.forSession(session: session))
    }
    
    func sendQuestionHint(_ request: SendHintRequest) throws {
        guard connected else {
            throw SocketError.notConnected
        }
        guard sessionInfo.isSessionOwner, let session = sessionInfo.sessionId else {
            throw SocketError.notSessionOwner
        }
        guard sessionInfo.sessionHasStarted else {
            throw SocketError.sessionNotStarted
        }
        guard !sessionInfo.sessionHasEnded else {
            throw SocketError.sessionEnded
        }
        
        socket.emit(SendHintRequest.eventKey, request.forSession(session: session))
    }
    
    private func registerHandlers() {
        // This socket's connection
        socket.on(clientEvent: .connect) { [weak self] data, _ in
            self?.delegate.onConnected()
        }
        
        // This socket's disconnect
        socket.on(clientEvent: .disconnect) { [weak self] data, _ in
            if let reason = data[0] as? String {
                self?.delegate.onDisconnected(reason)
            } else {
                // Fallback to ensure something is given, but this branch should only be hit if socket.io changes its API
                self?.delegate.onDisconnected("unknown")
            }
        }
        
        // This socket's session creation success
        socket.on(SocketEvent.createdSession.rawValue) { [weak self] data, _ in
            if let createdSession: CreatedSession = Self.readResponseFromData(from: data[0]) {
                self?.sessionInfo.sessionId = createdSession.session
                self?.sessionInfo.isSessionOwner = true
                self?.delegate.onCreatedSession(.success(createdSession))
            } else {
                self?.delegate.onCreatedSession(.failure(.unexpectedResponseData))
            }
        }
        
        // This socket's join session success
        socket.on(SocketEvent.joinedSession.rawValue) { [weak self] data, _ in
            if let userJoined: UserJoined = Self.readResponseFromData(from: data[0]) {
                if userJoined.session == self?.sessionId {
                    self?.delegate.onSessionJoined(.success(userJoined))
                }
            } else {
                self?.delegate.onSessionJoined(.failure(.unexpectedResponseData))
            }
        }
        
        // This socket's join session failed
        socket.on(SocketEvent.sessionJoinFailed.rawValue) { [weak self] data, _ in
            self?.sessionInfo.sessionId = nil
            self?.sessionInfo.username = nil
            self?.delegate.onSessionJoined(.failure(SocketError.joinFailed))
        }
        
        // This socket was kicked or is being told of a kick
        socket.on(SocketEvent.userKicked.rawValue) { [weak self] data, _ in
            if let kickedUser: KickedUser = Self.readResponseFromData(from: data[0]) {
                if kickedUser.session == self?.sessionId {
                    if kickedUser.name == self?.username {
                        // the user kicked was this socket
                        self?.sessionInfo.sessionId = nil
                        self?.sessionInfo.username = nil
                        self?.sessionInfo.sessionHasStarted = false
                    }
                    self?.delegate.onUserKicked(.success(kickedUser))
                }
            } else {
                self?.delegate.onUserKicked(.failure(.unexpectedResponseData))
            }
        }
        
        // This socket's kick attempt failed
        socket.on(SocketEvent.kickUserFailed.rawValue) { [weak self] data, _ in
            self?.delegate.onUserKicked(.failure(.kickFailed))
        }
        
        // This socket's successfully started session
        socket.on(SocketEvent.sessionStarted.rawValue) { [weak self] data, _ in
            self?.sessionInfo.sessionHasStarted = true
            self?.delegate.onSessionStarted(.success(()))
        }
        
        // This socket's session start failed
        socket.on(SocketEvent.startSessionFailed.rawValue){ [weak self] data, _ in
            self?.delegate.onSessionStarted(.failure(.startSessionFailed))
        }
        
        // This socket succesfully ended their session, or is in one and it ended
        socket.on(SocketEvent.sessionEnded.rawValue) { [weak self] data, _ in
            self?.sessionInfo.sessionHasEnded = true
            self?.delegate.onSessionEnded(.success(()))
        }
        
        // This socket failed to end own session
        socket.on(SocketEvent.endSessionFailed.rawValue) { [weak self] data, _ in
            self?.delegate.onSessionEnded(.failure(.endSessionFailed))
        }
        
        // A user disconnected from the same session as this socket
        socket.on(SocketEvent.userDisconnected.rawValue) { [weak self] data, _ in
            if let userDisconnected: UserDisconnected = Self.readResponseFromData(from: data[0]) {
                if userDisconnected.session == self?.sessionId {
                    self?.delegate.onUserDisconnected(.success(userDisconnected))
                }
            } else {
                self?.delegate.onUserDisconnected(.failure(.unexpectedResponseData))
            }
        }
        
        // This socket added a question successfully
        socket.on(SocketEvent.addedQuestion.rawValue) { [weak self] data, _ in
            self?.delegate.onQuestionAdded(.success(()))
        }
        
        // This socket's add question attempt failed
        socket.on(SocketEvent.questionAddFailed.rawValue) { [weak self] data, _ in
            self?.delegate.onQuestionAdded(.failure(.addQuestionFailed))
        }
        
        // The session the socket is in has pushed the next question
        // (if this socket owns the session, this indicates success)
        socket.on(SocketEvent.nextQuestion.rawValue) { [weak self] data, _ in
            if let nextQuestion: NextQuestion = Self.readResponseFromData(from: data[0]) {
                if nextQuestion.session == self?.sessionId {
                    self?.delegate.onNextQuestion(.success(nextQuestion))
                }
            } else {
                self?.delegate.onNextQuestion(.failure(.unexpectedResponseData))
            }
        }
        
        // This socket successfully submitted response to a question
        socket.on(SocketEvent.submittedResponse.rawValue){ [weak self] data, _ in
            if let questionResponseSubmitted: QuestionResponseSubmitted = Self.readResponseFromData(from: data[0]) {
                if questionResponseSubmitted.session == self?.sessionId {
                    self?.delegate.onQuestionResponseSubmitted(.success(questionResponseSubmitted))
                }
            } else {
                self?.delegate.onQuestionResponseSubmitted(.failure(.unexpectedResponseData))
            }
        }
        
        // This socket failed to submit response
        socket.on(SocketEvent.responseSubmissionFailed.rawValue) { [weak self] data, _ in
            self?.delegate.onQuestionResponseSubmitted(.failure(.responseSubmissionFailed))
        }
        
        // A response was added to the quiz created by this socket
        socket.on(SocketEvent.responseAdded.rawValue){ [weak self] data, _ in
            if let questionResponseAdded: QuestionResponseAdded = Self.readResponseFromData(from: data[0]) {
                if questionResponseAdded.session == self?.sessionId {
                    self?.delegate.onQuestionResponseAdded(.success(questionResponseAdded))
                }
            } else {
                self?.delegate.onQuestionResponseAdded(.failure(.unexpectedResponseData))
            }
        }
        
        // This socket failed to submit feedback
        socket.on(SocketEvent.submitFeedbackFailed.rawValue){ [weak self] data, _ in
            self?.delegate.onQuestionFeedbackSubmitted(.failure(.submitFeedbackFailed))
        }
        
        // This socket successfully submitted question feedback
        socket.on(SocketEvent.submitFeedbackSuccess.rawValue){ [weak self] data, _ in
            if let feedbackSubmitted: FeedbackSubmitted = Self.readResponseFromData(from: data[0]) {
                if feedbackSubmitted.session == self?.sessionId {
                    self?.delegate.onQuestionFeedbackSubmitted(.success(feedbackSubmitted))
                }
            } else {
                self?.delegate.onQuestionFeedbackSubmitted(.failure(.unexpectedResponseData))
            }
        }
        
        // A user submitted feedback to this socket's quiz
        socket.on(SocketEvent.feedbackReceived.rawValue){ [weak self] data, _ in
            if let feedbackReceived: FeedbackReceived = Self.readResponseFromData(from: data[0]) {
                if feedbackReceived.session == self?.sessionId {
                    self?.delegate.onQuestionFeedbackReceived(.success(feedbackReceived))
                }
            } else {
                self?.delegate.onQuestionFeedbackReceived(.failure(.unexpectedResponseData))
            }
        }
        
        // Session owner receiving confirmation of hint
        socket.on(SocketEvent.sendHintSuccess.rawValue){ [weak self] data, _ in
            if let hintSubmitted: HintSubmitted = Self.readResponseFromData(from: data[0]) {
                if hintSubmitted.session == self?.sessionId {
                    self?.delegate.onQuestionHintSubmitted(.success(hintSubmitted))
                }
            } else {
                self?.delegate.onQuestionHintSubmitted(.failure(.unexpectedResponseData))
            }
        }
        
        // Sending hint failed
        socket.on(SocketEvent.sendHintFailed.rawValue){ [weak self] data, _ in
            self?.delegate.onQuestionHintSubmitted(.failure(.sendHintFailed))
        }
        
        // User receiving hint for a question
        socket.on(SocketEvent.hintReceived.rawValue){ [weak self] data, _ in
            if let hintReceived: HintReceived = Self.readResponseFromData(from: data[0]) {
                if hintReceived.session == self?.sessionId {
                    self?.delegate.onQuestionHintReceived(.success(hintReceived))
                }
            } else {
                self?.delegate.onQuestionHintReceived(.failure(.unexpectedResponseData))
            }
        }
    }
    
    private static func readResponseFromData<T: SocketResponse>(from data: Any) -> T? {
        guard let json = data as? [String: Any] else {
            return nil
        }
        
        return T(json: json)
    }
    
    /// Server response Socket events for QuizEz
    private enum SocketEvent: String {
        case createdSession = "created session"
        
        case joinedSession = "join success"
        case sessionJoinFailed = "join failed"
        
        case userKicked = "kick success"
        case kickUserFailed = "kick failed"
        
        case sessionStarted = "session started"
        case startSessionFailed = "session start failed"
        
        case sessionEnded = "session ended"
        case endSessionFailed = "session end failed"
        
        case userDisconnected = "user disconnected"
        
        case addedQuestion = "add question success"
        case questionAddFailed = "add question failed"
        
        case nextQuestion = "next question"
        
        // User submitted response to a session they joined
        case submittedResponse = "question response success"
        case responseSubmissionFailed = "question response failed"
        
        // Session creator received response
        case responseAdded = "question response added"
        
        // User submitted feedback to a question
        case submitFeedbackFailed = "submit feedback failed"
        case submitFeedbackSuccess = "submit feedback success"
        
        // Session creator received feedback
        case feedbackReceived = "feedback submitted"
        
        // Sending hint succeeded or failed
        case sendHintSuccess = "send hint success"
        case sendHintFailed = "send hint failed"
        
        // User receiving hint
        case hintReceived = "hint received"
    }
    
    private struct SessionInfo {
        var isSessionOwner: Bool = false
        var username: String?
        var sessionId: String?
        var sessionHasStarted: Bool = false
        var sessionHasEnded: Bool = false
    }
}
