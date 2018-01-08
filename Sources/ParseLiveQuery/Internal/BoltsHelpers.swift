/**
 * Copyright (c) 2016-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

import Bolts
import BoltsSwift

let unknownDomain = "unknown"

func objcTask<T>(_ task: Task<T>) -> BFTask<T> where T: AnyObject {
    let taskCompletionSource = BFTaskCompletionSource<T>()
    task.continueWith { task in
        if task.cancelled {
            taskCompletionSource.trySetCancelled()
        } else if task.faulted {
            let error = (task.error as NSError?) ?? NSError(domain: unknownDomain, code: -1, userInfo: nil)
            taskCompletionSource.trySet(error: error)
        } else {
            taskCompletionSource.trySet(result: task.result)
        }
    }
    return taskCompletionSource.task
}

func swiftTask(_ task: BFTask<AnyObject>) -> Task<AnyObject> {
    let taskCompletionSource = TaskCompletionSource<AnyObject>()
    task.continueWith(block: { task in
        if task.isCancelled {
            taskCompletionSource.tryCancel()
        } else if let error = task.error , task.isFaulted {
            taskCompletionSource.trySet(error: error)
        } else if let result = task.result {
            taskCompletionSource.trySet(result: result)
        } else {
            fatalError("Unknown task state")
        }
        return nil
    })
    return taskCompletionSource.task
}
