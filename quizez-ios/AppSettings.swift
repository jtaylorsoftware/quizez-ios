//
//  AppSettings.swift
//  AppSettings
//
//  Created by Jeremy Taylor on 7/22/21.
//

import Foundation

/// Global settings
struct AppSettings: Decodable {
    /// Shared singleton
    static let shared = AppSettings()
    
    let serverUrl: String
    let codeLength: Int
    
    private init() {
        guard let settings = Bundle.main.object(forInfoDictionaryKey: "AppSettings") as? [String: Any],
                let serverUrl = settings["serverUrl"] as? String,
                let codeLength = settings["codeLength"] as? Int else {
            fatalError("Could not get AppSettings key from Info.plist")
        }
        
        self.serverUrl = serverUrl
        self.codeLength = codeLength
    }
    
    private enum CodingKeys: String, CodingKey {
        case serverUrl, codeLength
    }
}
