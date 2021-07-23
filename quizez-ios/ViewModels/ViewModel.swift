//
//  ViewModel.swift
//  quizez-ios
//
//  Created by Jeremy Taylor on 7/22/21.
//

import Foundation

protocol ViewModel {
}

/// Reasons for ViewModel methods to fail, with human-readable error Strings.
enum FailureReason: String, Error {
    case couldNotConnect = "The app could not connect to the service."
    case notConnected = "The app is not connected to the service."
    case alreadyInSession = "You already joined or created a session."
    case couldNotJoin = ""
    case badServerResponse = "Bad response from server."
    case unknown = "Unknown error."
}
