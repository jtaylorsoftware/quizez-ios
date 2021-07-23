//
//  MainViewModel.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/22/21.
//

import Foundation
import RxSwift
import RxCocoa

final class MainViewModel: ViewModel {
    private var socketService: SocketService
    
    private let _connectResult = PublishRelay<Result<Bool, FailureReason>>()
    private let _joinResult = PublishRelay<Result<String, FailureReason>>()
    private let _createResult = PublishRelay<Result<String, FailureReason>>()
    
    /// Result of connecting to the server. Success value is always true.
    var connectResult: Signal<Result<Bool, FailureReason>> {
        return _connectResult.asSignal()
    }
    
    /// Result of joining a session. Success value is the session id.
    var joinResult: Signal<Result<String, FailureReason>> {
        return _joinResult.asSignal()
    }
    
    /// Result of creating a result. Success value is the session id.
    var createResult: Signal<Result<String, FailureReason>> {
        return _createResult.asSignal()
    }
    
    /// Name user joined with.
    var name: String? {
        socketService.username
    }
    
    /// Session user joined or created.
    var session: String? {
        socketService.sessionId
    }
    
    init(socketService: SocketService) {
        self.socketService = socketService
        self.socketService.delegate = SocketDelegate(self)
    }
    
    deinit {
        self.socketService.delegate = SocketServiceDelegateImpl.default
    }
    
    /// Connects to the server.
    func connect() {
        guard !socketService.connected else {
            return
        }
        
        let _ = try? socketService.connect(timeoutAfter: 3.0) { [weak self] in
            self?._connectResult.accept(.failure(.couldNotConnect))
        }
    }
    
    /// Joins a session.
    /// - Parameters:
    ///     - session: Session code to join
    ///     - name: Display name to use
    func joinSession(session: String, name: String) {
        do {
            try socketService.joinSession(JoinSessionRequest(session: session, name: name))
        } catch SocketError.notConnected {
            _joinResult.accept(.failure(.notConnected))
        } catch SocketError.alreadyInSession {
            _joinResult.accept(.failure(.alreadyInSession))
        } catch {
            _joinResult.accept(.failure(.unknown))
        }
    }
    
    /// Creates a session.
    func createSession() {
        do {
            try socketService.createSession()
        }  catch SocketError.notConnected {
            _joinResult.accept(.failure(.notConnected))
        } catch SocketError.alreadyInSession {
            _joinResult.accept(.failure(.alreadyInSession))
        } catch {
            _joinResult.accept(.failure(.unknown))
        }
    }
    
    private class SocketDelegate: SocketServiceDelegate {
        private unowned var viewModel: MainViewModel
        
        init(_ viewModel: MainViewModel) {
            self.viewModel = viewModel
        }
        
        func onConnected() {
            viewModel._connectResult.accept(.success(true))
        }
        
        func onSessionJoined(_ result: SocketResult<UserJoined>) {
            switch result {
            case let .success(userJoined):
                if let session = viewModel.session,
                   let name = viewModel.name,
                   userJoined.session == session,
                   userJoined.name == name {
                    // This user/VM joined session
                    viewModel._joinResult.accept(.success(session))
                }
            case let .failure(reason):
                if reason == .joinFailed {
                    viewModel._joinResult.accept(.failure(.couldNotJoin))
                } else {
                    viewModel._joinResult.accept(.failure(.unknown))
                }
            }
        }
        
        func onCreatedSession(_ result: SocketResult<CreatedSession>) {
            switch result {
            case let .success(createdSession):
                viewModel._createResult.accept(.success(createdSession.session))
            case .failure:
                viewModel._createResult.accept(.failure(.unknown))
            }
        }
    }
}


