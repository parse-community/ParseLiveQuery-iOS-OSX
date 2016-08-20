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
            self["where"] = conditions.encodedQueryDictionary as? Value
        }
    }
}

extension Dictionary where Key: StringLiteralConvertible, Value: AnyObject {
    var encodedQueryDictionary: Dictionary {
        var encodedQueryDictionary = Dictionary()
        for (key, val) in self {
            if let dict = val as? [String:AnyObject] {
                encodedQueryDictionary[key] = dict.encodedQueryDictionary as? Value
            } else if let geoPoint = val as? PFGeoPoint {
                encodedQueryDictionary[key] = geoPoint.encodedDictionary as? Value
            } else {
                encodedQueryDictionary[key] = val
            }
        }
        return encodedQueryDictionary
    }
}

extension PFGeoPoint {
    var encodedDictionary: [String:AnyObject] {
        return ["__type": "GeoPoint",
                "latitude": latitude,
                "longitude": longitude]
    }
}
