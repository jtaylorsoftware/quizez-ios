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
    
    /// Delegate for event handlers
    var delegate: SocketServiceDelegate { get set }
    
    /// Is the Socket connected
    var connected: Bool { get }
    
    /// Session ID that Socket joined or created
    var sessionId: String? { get }
    
    /// Is this Socket the owner of a Session
    var isSessionOwner: Bool { get }
    
    /// Has the Session this Socket is in started
    var sessionHasStarted: Bool { get }
    
    /// Has the Session ended
    var sessionHasEnded: Bool { get }
    
    /// The name this Socket used if a Session was joined
    var username: String? { get }
    
    /// Connects to the server
    func connect(timeoutAfter: Double, onTimeout: (() -> Void)?)
    
    /// Disconnects from the server
    func disconnect()
    
    /// Creates a new quiz session under the client's own ID
    func createSession()
    
    /// Joins a session by ID
    func joinSession(_ request: JoinSessionRequest)
    
    /// Removes a user from the session, if this socket owns the session
    func kickUser(_ request: KickUserRequest)
    
    /// Starts the session, preventing users from joining and allowing questions to be pushed
    func startSession(_ request: StartSessionRequest)
    
    /// Ends the session, removing all users, except this Socket, if it owns the Session
    func endSession(_ request: EndSessionRequest)
}

extension SocketService {
    func connect(timeoutAfter: Double = 3.0, onTimeout: (() -> Void)? = nil) {
        connect(timeoutAfter: timeoutAfter, onTimeout: onTimeout)
    }
}

/// Delegates socket events to handler functions
class SocketServiceDelegate {
    /// Completion result signature
    typealias SocketResult<T> = Result<T, SocketError>
    
    /// The Socket has connected to the server
    func onConnected() {}
    
    /// The requested session has been created
    func onCreatedSession(_ result: SocketResult<CreatedSession>) {}
    
    /// The Socket has disconnected from the server
    func onDisconnected(_ reason: String) {}
    
    /// The Socket has joined a session
    func onSessionJoined(_ result: SocketResult<UserJoined>) {}
    
    /// The session owner (which might not be this Socket) has kicked a user
    func onUserKicked(_ result: SocketResult<KickedUser>) {}
    
    /// The session that this Socket is in or owns has started
    func onSessionStarted(_ result: SocketResult<Void>) {}
    
    /// The session that this Socket is in or owns has ended
    func onSessionEnded(_ result: SocketResult<Void>) {}
    
    /// A user in the same session as this Socket has disconnected
    func onUserDisconnected(_ result: SocketResult<UserDisconnected>) {}
    
    /// Provides default in case clients of SocketService do not provide a delegate; also serves as a
    /// marker to trace calls in that case
    fileprivate static let `default` = SocketServiceDelegate()
}

final class SocketServiceImpl: SocketService {
    var delegate: SocketServiceDelegate = SocketServiceDelegate.default
    
    private(set) var isSessionOwner: Bool = false
    private(set) var connected: Bool = false
    private(set) var username: String?
    private(set) var sessionId: String?
    private(set) var sessionHasStarted: Bool = false
    private(set) var sessionHasEnded: Bool = false
    
    private var manager: SocketManager
    private var socket: SocketIOClient
    
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
        connected = false
        registerHandlers()
    }
    
    deinit {
        if connected {
            disconnect()
        }
    }
    
    func connect(timeoutAfter: Double = 3.0, onTimeout: (() -> Void)? = nil) {
        socket.connect(timeoutAfter: timeoutAfter, withHandler: onTimeout)
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
    func createSession() {
        failIfInSession()
        
        socket.emit(SocketRequestEvent.createNewSession.rawValue)
    }
    
    func joinSession(_ request: JoinSessionRequest) {
        failIfInSession()
        self.sessionId = request.id
        self.username = request.name
        socket.emit(SocketRequestEvent.joinSession.rawValue, request)
    }
    
    func kickUser(_ request: KickUserRequest) {
        failIfNotSessionOwner()
        
        socket.emit(SocketRequestEvent.kickUser.rawValue, request)
    }
    
    func startSession(_ request: StartSessionRequest) {
        failIfNotSessionOwner()
        
        socket.emit(SocketRequestEvent.startSession.rawValue, request)
    }
    
    func endSession(_ request: EndSessionRequest) {
        failIfNotSessionOwner()
        failIfNotStarted()
        
        socket.emit(SocketRequestEvent.endSession.rawValue, request)
    }
    
    private func failIfInSession(){
        if sessionId != nil || isSessionOwner {
            fatalError("Cannot create or join multiple sessions")
        }
    }
    
    private func failIfNotSessionOwner(){
        if sessionId == nil || !isSessionOwner {
            fatalError("Cannot perform action if not a session owner")
        }
    }
    
    private func failIfNotStarted() {
        if !sessionHasStarted {
            fatalError("Cannot perform action if session not started")
        }
    }
    
    private func failIfEnded() {
        if sessionHasEnded {
            fatalError("Cannot perform action if session has ended")
        }
    }
    
    private func registerHandlers() {
        socket.on(clientEvent: .connect) { [weak self] data, _ in
            self?.connected = true
            self?.delegate.onConnected()
        }
        socket.on(clientEvent: .disconnect) { [weak self] data, _ in
            self?.reset()
            if let reason = data[0] as? String {
                self?.delegate.onDisconnected(reason)
            } else {
                // Fallback to ensure something is given, but this branch should only be hit if socket.io changes its API
                self?.delegate.onDisconnected("unknown")
            }
        }
        socket.on(SocketEvent.createdSession.rawValue) { [weak self] data, _ in
            if let createdSession: CreatedSession = Self.readResponseFromData(from: data[0]) {
                self?.sessionId = createdSession.id
                self?.isSessionOwner = true
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
            self?.sessionId = nil
            self?.username = nil
            self?.delegate.onSessionJoined(.failure(SocketError.joinFailed))
        }
        socket.on(SocketEvent.userKicked.rawValue) { [weak self] data, _ in
            if let kickedUser: KickedUser = Self.readResponseFromData(from: data[0]) {
                if kickedUser.session == self?.sessionId && kickedUser.name == self?.username {
                    self?.sessionId = nil
                    self?.username = nil
                    self?.sessionHasStarted = false
                }
                self?.delegate.onUserKicked(.success(kickedUser))
            } else {
                self?.delegate.onUserKicked(.failure(.unexpectedResponseData))
            }
        }
        socket.on(SocketEvent.kickUserFailed.rawValue) { [weak self] data, _ in
            self?.delegate.onUserKicked(.failure(.kickFailed))
        }
        socket.on(SocketEvent.sessionStarted.rawValue) { [weak self] data, _ in
            self?.sessionHasStarted = true
            self?.delegate.onSessionStarted(.success(()))
        }
        socket.on(SocketEvent.startSessionFailed.rawValue){ [weak self] data, _ in
            self?.delegate.onSessionStarted(.failure(.startSessionFailed))
        }
        socket.on(SocketEvent.sessionEnded.rawValue) { [weak self] data, _ in
            self?.sessionHasEnded = true
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
    }
    
    private static func readResponseFromData<T: SocketResponse>(from data: Any) -> T? {
        guard let json = data as? [String: Any] else {
            return nil
        }

        return T(json: json)
    }
    
    private func reset() {
        self.connected = false
        self.sessionId = nil
        self.isSessionOwner = false
        self.sessionHasStarted = false
        self.sessionHasEnded = false
        self.username = nil
    }
}

/// Client request Socket events for QuizEz
fileprivate enum SocketRequestEvent: String {
    case createNewSession = "create session"
    case joinSession = "join session"
    case kickUser = "kick"
    case startSession = "start session"
    case endSession = "end session"
}

/// Server response Socket events for QuizEz
fileprivate enum SocketEvent: String {
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
}
