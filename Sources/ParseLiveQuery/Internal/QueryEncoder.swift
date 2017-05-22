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
extension Dictionary where Key: ExpressibleByStringLiteral, Value: AnyObject {
    init<T>(query: PFQuery<T>) where T: PFObject {
        self.init()
        let queryState = query.value(forKey: "state") as AnyObject?
        if let className = queryState?.value(forKey: "parseClassName") {
            self["className"] = className as? Value
        }
        if let conditions: [String:AnyObject] = queryState?.value(forKey: "conditions") as? [String:AnyObject] {
            self["where"] = conditions.encodedQueryDictionary as? Value
        }
    }
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: AnyObject {
    var encodedQueryDictionary: Dictionary {
        var encodedQueryDictionary = Dictionary()
        for (key, val) in self {
            if let dict = val as? [String:AnyObject] {
                encodedQueryDictionary[key] = dict.encodedQueryDictionary as? Value
            } else if let geoPoint = val as? PFGeoPoint {
                encodedQueryDictionary[key] = geoPoint.encodedDictionary as? Value
            } else if let object = val as? PFObject {
                encodedQueryDictionary[key] = PFPointerObjectEncoder.object().encode(object) as? Value
            } else if let date = val as? Date {
                encodedQueryDictionary[key] = date.encodedString as? Value
            } else {
                encodedQueryDictionary[key] = val
            }
        }
        return encodedQueryDictionary
    }
}

extension PFGeoPoint {
    var encodedDictionary: [String:Any] {
        return ["__type": "GeoPoint",
                "latitude": latitude,
                "longitude": longitude]
    }
}

fileprivate extension Formatter {
    fileprivate static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}

fileprivate extension Date {
    fileprivate var encodedString: String {
        return Formatter.iso8601.string(from: self)
    }
}
