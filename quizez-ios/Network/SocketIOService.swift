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
        #if DEBUG
        print("Enabling SocketIO debug logging")
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
    
    private func registerHandlers() {
        socket.on(clientEvent: .connect) { [weak self] data, _ in
            self?.delegate.onConnected()
        }
        socket.on(clientEvent: .disconnect) { [weak self] data, _ in
            if let reason = data[0] as? String {
                self?.delegate.onDisconnected(reason)
            } else {
                // Fallback to ensure something is given, but this branch should only be hit if socket.io changes its API
                self?.delegate.onDisconnected("unknown")
            }
        }
        socket.on(SocketEvent.createdSession.rawValue) { [weak self] data, _ in
            if let createdSession: CreatedSession = Self.readResponseFromData(from: data[0]) {
                self?.sessionInfo.sessionId = createdSession.session
                self?.sessionInfo.isSessionOwner = true
                self?.delegate.onCreatedSession(.success(createdSession))
            } else {
                self?.delegate.onCreatedSession(.failure(.unexpectedResponseData))
            }
        }
        socket.on(SocketEvent.joinedSession.rawValue) { [weak self] data, _ in
            if let userJoined: UserJoined = Self.readResponseFromData(from: data[0]) {
                if userJoined.session == self?.sessionId {
                    self?.delegate.onSessionJoined(.success(userJoined))
                }
            } else {
                self?.delegate.onSessionJoined(.failure(.unexpectedResponseData))
            }
        }
        socket.on(SocketEvent.sessionJoinFailed.rawValue) { [weak self] data, _ in
            self?.sessionInfo.sessionId = nil
            self?.sessionInfo.username = nil
            self?.delegate.onSessionJoined(.failure(SocketError.joinFailed))
        }
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
        socket.on(SocketEvent.kickUserFailed.rawValue) { [weak self] data, _ in
            self?.delegate.onUserKicked(.failure(.kickFailed))
        }
        socket.on(SocketEvent.sessionStarted.rawValue) { [weak self] data, _ in
            self?.sessionInfo.sessionHasStarted = true
            self?.delegate.onSessionStarted(.success(()))
        }
        socket.on(SocketEvent.startSessionFailed.rawValue){ [weak self] data, _ in
            self?.delegate.onSessionStarted(.failure(.startSessionFailed))
        }
        socket.on(SocketEvent.sessionEnded.rawValue) { [weak self] data, _ in
            self?.sessionInfo.sessionHasEnded = true
            self?.delegate.onSessionEnded(.success(()))
        }
        socket.on(SocketEvent.endSessionFailed.rawValue) { [weak self] data, _ in
            self?.delegate.onSessionEnded(.failure(.endSessionFailed))
        }
        socket.on(SocketEvent.userDisconnected.rawValue) { [weak self] data, _ in
            if let userDisconnected: UserDisconnected = Self.readResponseFromData(from: data[0]) {
                if userDisconnected.session == self?.sessionId {
                    self?.delegate.onUserDisconnected(.success(userDisconnected))
                }
            } else {
                self?.delegate.onUserDisconnected(.failure(.unexpectedResponseData))
            }
        }
        socket.on(SocketEvent.addedQuestion.rawValue) { [weak self] data, _ in
            self?.delegate.onQuestionAdded(.success(()))
        }
        socket.on(SocketEvent.questionAddFailed.rawValue) { [weak self] data, _ in
            self?.delegate.onQuestionAdded(.failure(.addQuestionFailed))
        }
        socket.on(SocketEvent.nextQuestion.rawValue) { [weak self] data, _ in
            if let nextQuestion: NextQuestion = Self.readResponseFromData(from: data[0]) {
                if nextQuestion.session == self?.sessionId {
                    self?.delegate.onNextQuestion(.success(nextQuestion))
                }
            } else {
                self?.delegate.onNextQuestion(.failure(.unexpectedResponseData))
            }
        }
        socket.on(SocketEvent.submittedResponse.rawValue){ [weak self] data, _ in
            if let questionResponseSubmitted: QuestionResponseSubmitted = Self.readResponseFromData(from: data[0]) {
                if questionResponseSubmitted.session == self?.sessionId {
                    self?.delegate.onQuestionResponseSubmitted(.success(questionResponseSubmitted))
                }
            } else {
                self?.delegate.onQuestionResponseSubmitted(.failure(.unexpectedResponseData))
            }
        }
        socket.on(SocketEvent.responseSubmissionFailed.rawValue) { [weak self] data, _ in
            self?.delegate.onQuestionResponseSubmitted(.failure(.responseSubmissionFailed))
        }
        socket.on(SocketEvent.responseAdded.rawValue){ [weak self] data, _ in
            if let questionResponseAdded: QuestionResponseAdded = Self.readResponseFromData(from: data[0]) {
                if questionResponseAdded.session == self?.sessionId {
                    self?.delegate.onQuestionResponseAdded(.success(questionResponseAdded))
                }
            } else {
                self?.delegate.onQuestionResponseSubmitted(.failure(.unexpectedResponseData))
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
    }
    
    private struct SessionInfo {
        var isSessionOwner: Bool = false
        var username: String?
        var sessionId: String?
        var sessionHasStarted: Bool = false
        var sessionHasEnded: Bool = false
    }
}
