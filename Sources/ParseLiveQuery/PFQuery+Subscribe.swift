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

extension PFQuery {
    /**
     Register this PFQuery for updates with Live Queries.
     This uses the shared live query client, and creates a default subscription handler for you.

     - parameter subclassType: The type of the subscription to register for.
                               This can usually be inferred from the context and rarely should be set.

     - returns: The created subscription for observing.
     */
    public func subscribe<T: PFObject>(subclassType: T.Type = T.self) -> Subscription<T> {
        return Client.shared.subscribe(self)
    }
}
