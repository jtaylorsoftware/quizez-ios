//
//  SocketService.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/16/21.
//

import Foundation

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
    
    /// Sends a response to a question if this socket has joined a session.
    /// - Throws:
    ///     - `SocketError.notConnected` if not connected
    ///     - `SocketError.didNotJoinSession` if the user is the owner, rather than a joiner, of a session
    ///     - `SocketError.sessionNotStarted` if session has not started
    ///     - `SocketError.sessionEnded` if session has ended
    func submitQuestionResponse(_ request: SubmitResponseRequest) throws
    
    /// Sends feedback for a question if this socket has joined a session.
    /// - Throws:
    ///     - `SocketError.notConnected` if not connected
    ///     - `SocketError.didNotJoinSession` if the user is the owner, rather than a joiner, of a session
    ///     - `SocketError.sessionNotStarted` if session has not started
    ///     - `SocketError.sessionEnded` if session has ended
    func submitQuestionFeedback(_ request: SubmitFeedbackRequest) throws
}

extension SocketService {
    func connect(timeoutAfter: Double = 3.0, onTimeout: (() -> Void)? = nil) throws {
        try connect(timeoutAfter: timeoutAfter, onTimeout: onTimeout)
    }
}
