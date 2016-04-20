//
//  CorePlugin.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 20/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation

enum CorePlugin: Int {
    case BeaconForest
    case ImageCache
    case Recipes
    case Polls
    case Contents
    case Notifications
    
    var name: String {
        switch self {
        case .BeaconForest:
            return "com.nearit.sdk.plugin.np-beacon-forest"
        case .ImageCache:
            return "com.nearit.sdk.plugin.np-image-cache"
        case .Recipes:
            return "com.nearit.sdk.plugin.np-recipes"
        case .Polls:
            return "com.nearit.sdk.plugin.np-polls"
        case .Contents:
            return "com.nearit.sdk.plugin.np-contents"
        case .Notifications:
            return "com.nearit.sdk.plugin.np-notifications"
        }
    }
}
