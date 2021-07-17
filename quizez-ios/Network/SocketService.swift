//
//  SocketIOService.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/16/21.
//

import Foundation
import SocketIO

/// Service that interacts with the socket server
protocol SocketService {
    /// Delegate for event handlers
    var delegate: SocketServiceDelegate { get set }
    
    /// Is the Socket connected
    var connected: Bool { get }
    
    /// Session ID that Socket joined or created
    var sessionId: String? { get }
    
    /// Connects to the server
    func connect(timeoutAfter: Double, onTimeout: (() -> Void)?)
    
    /// Disconnects from the server
    func disconnect()
    
    /// Creates a new quiz session under the client's own ID
    func createSession()
    
    /// Joins a session by ID
    func joinSession(_ request: JoinSessionRequest)
}

extension SocketService {
    func connect(timeoutAfter: Double = 3.0, onTimeout: (() -> Void)? = nil) {
        connect(timeoutAfter: timeoutAfter, onTimeout: onTimeout)
    }
}

/// Delegates socket events to handler functions
class SocketServiceDelegate {
    /// Completion callback signature for SocketService functions
    typealias SocketResult<T> = Result<T, SocketError>
    
    func onConnected() {}
    func onCreatedSession(_ result: SocketResult<CreatedSession>) {}
    func onDisconnected(_ reason: String) {}
    func onSessionJoined(_ result: SocketResult<Void>){}
    
    fileprivate static let `default` = SocketServiceDelegate()
}

class SocketServiceImpl: SocketService {
    var delegate: SocketServiceDelegate = SocketServiceDelegate.default
    
    private(set) var connected: Bool = false
    private var manager: SocketManager
    private var socket: SocketIOClient
    
    /// ID of the Session created or joined
    private(set) var sessionId: String?
    
    /// Creates a SocketService instance
    /// - Parameter url: the URL of the socket server
    /// - Throws: `SocketError.invalidUrl` if URL is malformed
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
        
        socket.emit(SocketRequestEvent.joinSession.rawValue, request)
    }
    
    private func failIfInSession(){
        if sessionId != nil {
            fatalError("Cannot create or join multiple sessions")
        }
    }
    
    private func registerHandlers() {
        socket.on(clientEvent: .connect) { [weak self] data, _ in
            self?.connected = true
            self?.delegate.onConnected()
        }
        socket.on(clientEvent: .disconnect) { [weak self] data, _ in
            self?.connected = false
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
                self?.delegate.onCreatedSession(.success(createdSession))
            } else {
                self?.delegate.onCreatedSession(.failure(.unexpectedResponseData))
            }
        }
        socket.on(SocketEvent.joinedSession.rawValue) { [weak self] data, _ in
            self?.delegate.onSessionJoined(.success(()))
        }
        socket.on(SocketEvent.sessionJoinFailed.rawValue) { [weak self] data, _ in
            self?.delegate.onSessionJoined(.failure(SocketError.joinFailed))
        }
    }
    
    private static func readResponseFromData<T: SocketResponse>(from data: Any) -> T? {
        guard let json = data as? [String: Any] else {
            return nil
        }

        return T(json: json)
    }
}

/// Client request Socket events for QuizEz
fileprivate enum SocketRequestEvent: String {
    case createNewSession = "create session"
    case joinSession = "join session"
}

/// Server response Socket events for QuizEz
fileprivate enum SocketEvent: String {
    case createdSession = "created session"
    case joinedSession = "join success"
    case sessionJoinFailed = "join failed"
}
