//
//  AlertFailure.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 8/6/21.
//

import Foundation
import UIKit

extension UIViewController {
    func alertFailure(reason: FailureReason, onRetry: (() -> Void)? = nil) {
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
