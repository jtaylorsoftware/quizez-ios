//
//  ViewController.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/16/21.
//

import UIKit
import RxSwift
import RxCocoa

class MainViewController: UIViewController {
    @IBOutlet var sessionCodeText: UITextField!
    @IBOutlet var nameText: UITextField!
    @IBOutlet var joinButton: UIButton!
    @IBOutlet var createButton: UIButton!
    
    var sessionCode: String {
        sessionCodeText.text ?? ""
    }
    var name: String {
        nameText.text ?? ""
    }
    
    var viewModel: MainViewModel? = Injector.shared.resolve()
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Subscribe to events
        viewModel?.connectResult.emit(onNext: { [weak self] result in
            switch result {
            case .success:
                print("Connected")
            case let .failure(reason):
                self?.alertFailure(reason: reason) {
                    self?.viewModel?.connect()
                }
            }
        }).disposed(by: disposeBag)
        
        viewModel?.joinResult.emit(onNext: { [weak self] result in
            switch result {
            case .success:
                print("Joined")
            case let .failure(reason):
                self?.alertFailure(reason: reason)
            }
        }).disposed(by: disposeBag)
        
        viewModel?.createResult.emit(onNext: { [weak self] result in
            switch result {
            case .success:
                print("Created")
            case let .failure(reason):
                self?.alertFailure(reason: reason)
            }
        }).disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel?.connect()
    }
    
    @IBAction func joinPressed(_ sender: UIButton) {
        guard sessionCode.count == AppSettings.shared.codeLength else {
            return
        }
        viewModel?.joinSession(session: sessionCode, name: name)
    }
    
    @IBAction func createPressed(_ sender: UIButton) {
        viewModel?.createSession()
    }
    
    @IBAction func sessionCodeChanged(_ sender: UITextField) {
        guard let text = sender.text else {
            return
        }
        
        let maxCodeLength = AppSettings.shared.codeLength
        if text.count > maxCodeLength {
            sender.text = String(text.prefix(maxCodeLength))
        }
    }
    
    @IBAction func editingNameChanged(_ sender: UITextField) {
        guard let text = sender.text else {
            return
        }
        
        let maxNameLength = 12
        if text.count > maxNameLength {
            sender.text = String(text.prefix(maxNameLength))
        }
    }
    
    private func alertFailure(reason: FailureReason, onRetry: (() -> Void)? = nil) {
        let alert = UIAlertController(
            title: "Error",
            message: reason.rawValue,
            preferredStyle: .alert)
        
        if let retry = onRetry {
            let retryAction = UIAlertAction(title: "Retry", style: .default) { (action) in
                retry()
            }
            alert.addAction(retryAction)
        } else {
            let confirm = UIAlertAction(title: "Ok", style: .default)
            alert.addAction(confirm)
        }
        
        self.present(alert, animated: false)
    }
}

