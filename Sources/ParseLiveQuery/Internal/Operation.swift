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

internal enum ClientOperation {
    case Connect(applicationId: String, sessionToken: String)
    case Subscribe(requestId: Client.RequestId, query: PFQuery)
    case Unsubscribe(requestId: Client.RequestId)

    var JSONObjectRepresentation: [String : AnyObject] {
        switch self {
        case .Connect(let applicationId, let sessionToken):
            return [ "op": "connect", "applicationId": applicationId, "sessionToken": sessionToken ]

        case .Subscribe(let requestId, let query):
            return [ "op": "subscribe", "requestId": requestId.value, "query": Dictionary<String, AnyObject>(query: query) ]

        case .Unsubscribe(let requestId):
            return [ "op": "unsubscribe", "requestId": requestId.value ]
        }
    }
}

internal enum ServerResponse {
    case Redirect(url: String)
    case Connected()

    case Subscribed(requestId: Client.RequestId)
    case Unsubscribed(requestId: Client.RequestId)

    case Enter(requestId: Client.RequestId, object: [String : AnyObject])
    case Leave(requestId: Client.RequestId, object: [String : AnyObject])
    case Update(requestId: Client.RequestId, object: [String : AnyObject])
    case Create(requestId: Client.RequestId, object: [String : AnyObject])
    case Delete(requestId: Client.RequestId, object: [String : AnyObject])

    case Error(requestId: Client.RequestId?, code: Int, error: String, reconnect: Bool)

    internal init(json: [String : AnyObject]) throws {
        func jsonValue<T>(json: [String:AnyObject], _ key: String) throws -> T {
            guard let value =  json[key] as? T
                else {
                    throw LiveQueryErrors.InvalidJSONError(json: json, expectedKey: key)
            }
            return value
        }

        func jsonRequestId(json: [String:AnyObject]) throws -> Client.RequestId {
            let requestId: Int = try jsonValue(json, "requestId")
            return Client.RequestId(value: requestId)
        }

        func subscriptionEvent(
            json: [String:AnyObject],
            _ eventType: (Client.RequestId, [String : AnyObject]) -> ServerResponse
            ) throws -> ServerResponse {
                return eventType(try jsonRequestId(json), try jsonValue(json, "object"))
        }

        let rawOperation: String = try jsonValue(json, "op")
        switch rawOperation {
        case "connected":
            self = .Connected()

        case "redirect":
            self = .Redirect(url: try jsonValue(json, "url"))

        case "subscribed":
            self = .Subscribed(requestId: try jsonRequestId(json))
        case "unsubscribed":
            self = .Unsubscribed(requestId: try jsonRequestId(json))

        case "enter": self = try subscriptionEvent(json, ServerResponse.Enter)
        case "leave": self = try subscriptionEvent(json, ServerResponse.Leave)
        case "update": self = try subscriptionEvent(json, ServerResponse.Update)
        case "create": self = try subscriptionEvent(json, ServerResponse.Create)
        case "delete": self = try subscriptionEvent(json, ServerResponse.Delete)

        case "error":
            self = .Error(
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
