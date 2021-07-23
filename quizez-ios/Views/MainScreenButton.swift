//
//  MainScreenButton.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/20/21.
//

import Foundation
import UIKit

class MainScreenButton : RoundedButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
 
    func setup() {
        cornerRadius = bounds.size.height * 0.1
        layer.backgroundColor = UIColor.systemGreen.cgColor
        titleLabel?.font = UIFont(name: "Helvetica Neue", size: 28.0)
        setTitleColor(.white, for: .normal)
        
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 150).isActive = true
        heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
}
