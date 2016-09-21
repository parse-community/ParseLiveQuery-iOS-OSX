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

enum ClientOperation {
    case connect(applicationId: String, sessionToken: String)
    case subscribe(requestId: Client.RequestId, query: PFQuery<PFObject>)
    case unsubscribe(requestId: Client.RequestId)

    var JSONObjectRepresentation: [String : AnyObject] {
        switch self {
        case .connect(let applicationId, let sessionToken):
            return [ "op": "connect" as AnyObject, "applicationId": applicationId as AnyObject, "sessionToken": sessionToken as AnyObject ]

        case .subscribe(let requestId, let query):
            return [ "op": "subscribe" as AnyObject, "requestId": requestId.value as AnyObject, "query": Dictionary<String, AnyObject>(query: query) as AnyObject ]

        case .unsubscribe(let requestId):
            return [ "op": "unsubscribe" as AnyObject, "requestId": requestId.value as AnyObject ]
        }
    }
}

enum ServerResponse {
    case redirect(url: String)
    case connected()

    case subscribed(requestId: Client.RequestId)
    case unsubscribed(requestId: Client.RequestId)

    case enter(requestId: Client.RequestId, object: [String : AnyObject])
    case leave(requestId: Client.RequestId, object: [String : AnyObject])
    case update(requestId: Client.RequestId, object: [String : AnyObject])
    case create(requestId: Client.RequestId, object: [String : AnyObject])
    case delete(requestId: Client.RequestId, object: [String : AnyObject])

    case error(requestId: Client.RequestId?, code: Int, error: String, reconnect: Bool)

    init(json: [String : AnyObject]) throws {
        func jsonValue<T>(_ json: [String:AnyObject], _ key: String) throws -> T {
            guard let value =  json[key] as? T
                else {
                    throw LiveQueryErrors.InvalidJSONError(json: json, expectedKey: key)
            }
            return value
        }

        func jsonRequestId(_ json: [String:AnyObject]) throws -> Client.RequestId {
            let requestId: Int = try jsonValue(json, "requestId")
            return Client.RequestId(value: requestId)
        }

        func subscriptionEvent(
            _ json: [String:AnyObject],
            _ eventType: (Client.RequestId, [String : AnyObject]) -> ServerResponse
            ) throws -> ServerResponse {
                return eventType(try jsonRequestId(json), try jsonValue(json, "object"))
        }

        let rawOperation: String = try jsonValue(json, "op")
        switch rawOperation {
        case "connected":
            self = .connected()

        case "redirect":
            self = .redirect(url: try jsonValue(json, "url"))

        case "subscribed":
            self = .subscribed(requestId: try jsonRequestId(json))
        case "unsubscribed":
            self = .unsubscribed(requestId: try jsonRequestId(json))

        case "enter": self = try subscriptionEvent(json, ServerResponse.enter)
        case "leave": self = try subscriptionEvent(json, ServerResponse.leave)
        case "update": self = try subscriptionEvent(json, ServerResponse.update)
        case "create": self = try subscriptionEvent(json, ServerResponse.create)
        case "delete": self = try subscriptionEvent(json, ServerResponse.delete)

        case "error":
            self = .error(
                requestId: try? jsonRequestId(json),
                code: try jsonValue(json, "code"),
                error: try jsonValue(json, "error"),
                reconnect: try jsonValue(json, "reconnect")
            )

        default:
            throw LiveQueryErrors.InvalidJSONError(json: json, expectedKey: "op")
        }
    }
}
