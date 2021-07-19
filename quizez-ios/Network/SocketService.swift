//
//  SocketService.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/16/21.
//

import Foundation
import SocketIO

/// Service that interacts with the socket server
protocol SocketService {
    /// Creates a SocketService instance
    /// - Parameter url: the URL of the socket server
    /// - Throws: `SocketError.invalidUrl` if URL is malformed
    init(url: String) throws
    
    /// Delegate for event handlers. No-op default provided.
    var delegate: SocketServiceDelegate { get set }
    
    /// Is the socket connected
    var connected: Bool { get }
    
    /// Session ID that socket joined or created
    var sessionId: String? { get }
    
    /// Is this socket the owner of a session
    var isSessionOwner: Bool { get }
    
    /// Has the session this socket is in started
    var sessionHasStarted: Bool { get }
    
    /// Has the session ended
    var sessionHasEnded: Bool { get }
    
    /// The name this socket used if a session was joined
    var username: String? { get }
    
    /// Connects to the server
    /// - Throws:
    ///     - `SocketError.alreadyConnected` if not connected
    func connect(timeoutAfter: Double, onTimeout: (() -> Void)?) throws
    
    /// Disconnects from the server
    /// - Throws:
    ///     - `SocketError.notConnected` if not connected
    func disconnect() throws
    
    /// Creates a new quiz session under the client's own ID
    /// - Throws:
    ///     - `SocketError.notConnected` if not connected
    ///     - `SocketError.alreadyInSession` if already in a session or created a session
    func createSession() throws
    
    /// Joins a session by ID
    /// - Throws:
    ///     - `SocketError.notConnected` if not connected
    ///     - `SocketError.alreadyInSession` if already in a session or created a session
    func joinSession(_ request: JoinSessionRequest) throws
    
    /// Removes a user from the session, if this socket owns the session
    /// - Throws:
    ///     - `SocketError.notConnected` if not connected
    ///     - `SocketError.notSessionOwner` if not the owner of a session
    func kickUser(_ request: KickUserRequest) throws
    
    /// Starts the session, preventing users from joining and allowing questions to be pushed
    /// - Throws:
    ///     - `SocketError.notConnected` if not connected
    ///     - `SocketError.notSessionOwner` if not the owner of a session
    func startSession() throws
    
    /// Ends the session, removing all users, except this socket, if it owns the session
    /// - Throws:
    ///     - `SocketError.notConnected` if not connected
    ///     - `SocketError.notSessionOwner` if not the owner of a session
    ///     - `SocketError.sessionNotStarted` if session is not started
    ///     - `SocketError.sessionEnded` if session has ended
    func endSession() throws
    
    /// Adds a question to the session if this socket owns a session
    /// - Throws:
    ///     - `SocketError.notConnected` if not connected
    ///     - `SocketError.notSessionOwner` if not the owner of a session
    func addQuestion(_ request: AddQuestionRequest) throws
    
    /// Attempts to push the next question to the session, if this socket owns a session and has added
    /// a question
    /// - Throws:
    ///     - `SocketError.notConnected` if not connected
    ///     - `SocketError.notSessionOwner` if not the owner of a session
    ///     - `SocketError.sessionNotStarted` if session has not started
    ///     - `SocketError.sessionEnded` if session has ended
    func pushNextQuestion() throws
}

extension SocketService {
    func connect(timeoutAfter: Double = 3.0, onTimeout: (() -> Void)? = nil) throws {
        try connect(timeoutAfter: timeoutAfter, onTimeout: onTimeout)
    }
}

/// Delegates socket events to handler functions
class SocketServiceDelegate {
    /// Completion result signature
    typealias SocketResult<T> = Result<T, SocketError>
    
    /// The socket has connected to the server.
    func onConnected() {}
    
    /// The requested session has been created. The result will be `Result.failure` if
    /// the response data could not be parsed.
    func onCreatedSession(_ result: SocketResult<CreatedSession>) {}
    
    /// The socket has disconnected from the server.
    func onDisconnected(_ reason: String) {}
    
    /// The socket has joined a session. The result will be `Result.failure` if
    /// the response data could not be parsed or if this socket sent a join request that failed.
    func onSessionJoined(_ result: SocketResult<UserJoined>) {}
    
    /// The session owner (which might not be this socket) has kicked a user. The result will be `Result.failure` if
    /// the response data could not be parsed, or if this socket sent a kick request that failed.
    func onUserKicked(_ result: SocketResult<KickedUser>) {}
    
    /// The session that this socket is in or owns has started. The result will only be `Result.failure`
    /// if this socket had sent a start request and the request failed.
    func onSessionStarted(_ result: SocketResult<Void>) {}
    
    /// The session that this socket is in or owns has ended. The result will only be `Result.failure`
    /// if this socket had sent an end request and the request failed.
    func onSessionEnded(_ result: SocketResult<Void>) {}
    
    /// A user in the same session as this socket has disconnected. The result will be `Result.failure` if
    /// the response data could not be parsed.
    func onUserDisconnected(_ result: SocketResult<UserDisconnected>) {}
    
    /// A Question has been added by this socket. The result will be `Result.failure` if
    /// this socket had sent an add question request that failed.
    func onQuestionAdded(_ result: SocketResult<Void>) {}
    
    /// The next Question of the quiz has been pushed to the session. The result will be `Result.failure` if
    /// the response data could not be parsed.
    func onNextQuestion(_ result: SocketResult<NextQuestion>) {}
    
    /// Provides default in case clients of SocketService do not provide a delegate; also serves as a
    /// marker to trace calls in that case
    fileprivate static let `default` = SocketServiceDelegate()
}

/// SocketService that uses socket.io in its implementation
final class SocketIOService : SocketService {
    var delegate: SocketServiceDelegate = SocketServiceDelegate.default
    
    var isSessionOwner: Bool {
        status.isSessionOwner
    }
    var connected: Bool {
        status.connected
    }
    var username: String? {
        status.username
    }
    var sessionId: String? {
        status.sessionId
    }
    var sessionHasStarted: Bool {
        status.sessionHasStarted
    }
    var sessionHasEnded: Bool {
        status.sessionHasEnded
    }
    
    private var manager: SocketManager
    private var socket: SocketIOClient
    private var status: SocketStatus
    
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
        status = SocketStatus()
        registerHandlers()
    }
    
    deinit {
        try? disconnect()
    }
    
    func connect(timeoutAfter: Double = 3.0, onTimeout: (() -> Void)? = nil) throws {
        guard !status.connected else {
            throw SocketError.alreadyConnected
        }
        socket.connect(timeoutAfter: timeoutAfter, withHandler: onTimeout)
    }
    
    func disconnect() throws {
        guard status.connected else {
            throw SocketError.notConnected
        }
        socket.disconnect()
    }
    
    func createSession() throws {
        guard status.connected else {
            throw SocketError.notConnected
        }
        guard status.sessionId == nil else {
            throw SocketError.alreadyInSession
        }
        
        socket.emit(CreateNewSessionRequest.eventKey)
    }
    
    func joinSession(_ request: JoinSessionRequest) throws {
        guard status.connected else {
            throw SocketError.notConnected
        }
        guard status.sessionId == nil else {
            throw SocketError.alreadyInSession
        }
        
        status.sessionId = request.session
        status.username = request.name
        socket.emit(JoinSessionRequest.eventKey, request)
    }
    
    func kickUser(_ request: KickUserRequest) throws {
        guard status.connected else {
            throw SocketError.notConnected
        }
        guard status.isSessionOwner, let session = status.sessionId else {
            throw SocketError.notSessionOwner
        }
        
        socket.emit(KickUserRequest.eventKey, request.forSession(session: session))
    }
    
    func startSession() throws {
        guard status.connected else {
            throw SocketError.notConnected
        }
        guard status.isSessionOwner, let session = status.sessionId else {
            throw SocketError.notSessionOwner
        }
        
        let request = StartSessionRequest(session: session)
        socket.emit(StartSessionRequest.eventKey, request)
    }
    
    func endSession() throws {
        guard status.connected else {
            throw SocketError.notConnected
        }
        guard status.isSessionOwner, let session = status.sessionId else {
            throw SocketError.notSessionOwner
        }
        guard status.sessionHasStarted else {
            throw SocketError.sessionNotStarted
        }
        guard !status.sessionHasEnded else {
            throw SocketError.sessionEnded
        }
        
        let request = EndSessionRequest(session: session)
        socket.emit(EndSessionRequest.eventKey, request)
    }
    
    func addQuestion(_ request: AddQuestionRequest) throws {
        guard status.connected else {
            throw SocketError.notConnected
        }
        guard status.isSessionOwner, let session = status.sessionId else {
            throw SocketError.notSessionOwner
        }
        guard !status.sessionHasEnded else {
            throw SocketError.sessionEnded
        }
        
        socket.emit(AddQuestionRequest.eventKey, request.forSession(session: session))
    }
    
    func pushNextQuestion() throws {
        guard status.connected else {
            throw SocketError.notConnected
        }
        guard status.isSessionOwner, let session = status.sessionId else {
            throw SocketError.notSessionOwner
        }
        guard status.sessionHasStarted else {
            throw SocketError.sessionNotStarted
        }
        guard !status.sessionHasEnded else {
            throw SocketError.sessionEnded
        }
        
        let request = NextQuestionRequest(session: session)
        socket.emit(NextQuestionRequest.eventKey, request)
    }
    
    private func registerHandlers() {
        socket.on(clientEvent: .connect) { [weak self] data, _ in
            self?.status.connected = true
            self?.delegate.onConnected()
        }
        socket.on(clientEvent: .disconnect) { [weak self] data, _ in
            self?.status.connected = false
            if let reason = data[0] as? String {
                self?.delegate.onDisconnected(reason)
            } else {
                // Fallback to ensure something is given, but this branch should only be hit if socket.io changes its API
                self?.delegate.onDisconnected("unknown")
            }
        }
        socket.on(SocketEvent.createdSession.rawValue) { [weak self] data, _ in
            if let createdSession: CreatedSession = Self.readResponseFromData(from: data[0]) {
                self?.status.sessionId = createdSession.session
                self?.status.isSessionOwner = true
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
            self?.status.sessionId = nil
            self?.status.username = nil
            self?.delegate.onSessionJoined(.failure(SocketError.joinFailed))
        }
        socket.on(SocketEvent.userKicked.rawValue) { [weak self] data, _ in
            if let kickedUser: KickedUser = Self.readResponseFromData(from: data[0]) {
                if kickedUser.session == self?.sessionId {
                    if kickedUser.name == self?.username {
                        // the user kicked was this socket
                        self?.status.sessionId = nil
                        self?.status.username = nil
                        self?.status.sessionHasStarted = false
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
            self?.status.sessionHasStarted = true
            self?.delegate.onSessionStarted(.success(()))
        }
        socket.on(SocketEvent.startSessionFailed.rawValue){ [weak self] data, _ in
            self?.delegate.onSessionStarted(.failure(.startSessionFailed))
        }
        socket.on(SocketEvent.sessionEnded.rawValue) { [weak self] data, _ in
            self?.status.sessionHasEnded = true
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
    }
    
    private struct SocketStatus {
        var isSessionOwner: Bool = false
        var connected: Bool = false
        var username: String?
        var sessionId: String?
        var sessionHasStarted: Bool = false
        var sessionHasEnded: Bool = false
    }
}
