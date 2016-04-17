//
//  THRegion.swift
//  NMSDK
//
//  Created by Francesco Colleoni on 17/04/16.
//  Copyright © 2016 Near srl. All rights reserved.
//

import Foundation
import CoreLocation

class THRegion: CLRegion {
    private var _identifier = ""
    
    override var identifier: String {
        return _identifier
    }
    
    init(identifier: String) {
        super.init()
        
        _identifier = identifier
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
