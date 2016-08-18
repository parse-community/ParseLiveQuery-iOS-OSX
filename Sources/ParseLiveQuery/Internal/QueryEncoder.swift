/**
 * Copyright (c) 2016-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

import Foundation
import Parse

/**
 NOTE: This is super hacky, and we need a better answer for this.
 */
extension Dictionary where Key: StringLiteralConvertible, Value: AnyObject {
    init(query: PFQuery) {
        self.init()
        
        let queryState = query.valueForKey("state")
        if let className = queryState?.valueForKey("parseClassName") {
            self["className"] = className as? Value
        }
        
        if let conditions: [String:AnyObject] = queryState?.valueForKey("conditions") as? [String:AnyObject] {
            let newConditions = conditions.sanitizeParseObjects()
            self["where"] = newConditions as? Value
        }
    }
}

extension Dictionary {
    func sanitizeParseObjects() -> Dictionary {
        var newSelf = Dictionary()
        for keyVal in self {
            if let dict = keyVal.1 as? [String:AnyObject] {
                newSelf[keyVal.0] = dict.sanitizeParseObjects() as? Value
            } else if let geoPoint = keyVal.1 as? PFGeoPoint {
                newSelf[keyVal.0] = geoPoint.toDict() as? Value
            } else {
                newSelf[keyVal.0] = keyVal.1
            }
        }
        return newSelf
    }
}

extension PFGeoPoint {
    func toDict() -> [String:AnyObject] {
        return ["__type": "GeoPoint",
                "latitude": latitude,
                "longitude": longitude]
    }
}
