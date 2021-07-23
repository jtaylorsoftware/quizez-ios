//
//  RoundedButton.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/20/21.
//

import Foundation
import UIKit

class RoundedButton: UIButton {
    var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
