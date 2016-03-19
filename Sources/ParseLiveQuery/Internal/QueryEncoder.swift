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
internal extension Dictionary where Key: StringLiteralConvertible, Value: AnyObject {
    internal init(query: PFQuery) {
        self.init()

        let queryState = query.valueForKey("state")
        if let className = queryState?.valueForKey("parseClassName") {
            self["className"] = className as? Value
        }

        if let conditions: [String:AnyObject] = queryState?.valueForKey("conditions") as? [String:AnyObject] {
            self["where"] = conditions as? Value
        }
    }
}
