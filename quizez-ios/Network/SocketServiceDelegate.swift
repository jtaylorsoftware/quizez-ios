//
//  SocketServiceDelegate.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/19/21.
//

import Foundation

protocol SocketServiceDelegate {
    /// Completion result signature
    typealias SocketResult<T> = Result<T, SocketError>
    
    /// The socket has connected to the server.
    func onConnected()
    
    /// The requested session has been created. The result will be `Result.failure` if
    /// the response data could not be parsed.
    func onCreatedSession(_ result: SocketResult<CreatedSession>)
    
    /// The socket has disconnected from the server.
    func onDisconnected(_ reason: String)
    
    /// The socket has joined a session. The result will be `Result.failure` if
    /// the response data could not be parsed or if this socket sent a join request that failed.
    func onSessionJoined(_ result: SocketResult<UserJoined>)
    
    /// The session owner (which might not be this socket) has kicked a user. The result will be `Result.failure` if
    /// the response data could not be parsed, or if this socket sent a kick request that failed.
    func onUserKicked(_ result: SocketResult<KickedUser>)
    
    /// The session that this socket is in or owns has started. The result will only be `Result.failure`
    /// if this socket had sent a start request and the request failed.
    func onSessionStarted(_ result: SocketResult<Void>)
    
    /// The session that this socket is in or owns has ended. The result will only be `Result.failure`
    /// if this socket had sent an end request and the request failed.
    func onSessionEnded(_ result: SocketResult<Void>)
    
    /// A user in the same session as this socket has disconnected. The result will be `Result.failure` if
    /// the response data could not be parsed.
    func onUserDisconnected(_ result: SocketResult<UserDisconnected>)
    
    /// A Question has been added by this socket. The result will be `Result.failure` if
    /// this socket had sent an add question request that failed.
    func onQuestionAdded(_ result: SocketResult<Void>)
    
    /// The next Question of the quiz has been pushed to the session. The result will be `Result.failure` if
    /// the response data could not be parsed.
    func onNextQuestion(_ result: SocketResult<NextQuestion>)
    
    /// If this socket joined a session, it is receiving the result of submitting a response. The result will be `Result.failure` if
    /// the response data could not be parsed, or if the request failed.
    func onQuestionResponseSubmitted(_ result: SocketResult<QuestionResponseSubmitted>)
    
    /// If this socket owns a session, it is receiving some user's graded response. The result will be `Result.failure` if
    /// the response data could not be parsed.
    func onQuestionResponseAdded(_ result: SocketResult<QuestionResponseAdded>)
}

extension SocketServiceDelegate {
    func onConnected(){}
    func onCreatedSession(_ result: SocketResult<CreatedSession>) {}
    func onDisconnected(_ reason: String) {}
    func onSessionJoined(_ result: SocketResult<UserJoined>) {}
    func onUserKicked(_ result: SocketResult<KickedUser>) {}
    func onSessionStarted(_ result: SocketResult<Void>) {}
    func onSessionEnded(_ result: SocketResult<Void>) {}
    func onUserDisconnected(_ result: SocketResult<UserDisconnected>) {}
    func onQuestionAdded(_ result: SocketResult<Void>) {}
    func onNextQuestion(_ result: SocketResult<NextQuestion>) {}
    func onQuestionResponseSubmitted(_ result: SocketResult<QuestionResponseSubmitted>) {}
    func onQuestionResponseAdded(_ result: SocketResult<QuestionResponseAdded>) {}
}

/// Utility class for default implementation
final class SocketServiceDelegateImpl : SocketServiceDelegate {
    /// Provides default in case clients of SocketService do not provide a delegate; also serves as a
    /// marker to trace calls in that case
    static let `default`: SocketServiceDelegate = SocketServiceDelegateImpl()
}
