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
import SocketRocket
import BoltsSwift

private func parseObject<T: PFObject>(objectDictionary: [String:AnyObject]) throws -> T {
    guard let parseClassName = objectDictionary["className"] as? String else {
        throw LiveQueryErrors.InvalidJSONError(json: objectDictionary, expectedKey: "parseClassName")
    }
    guard let objectId = objectDictionary["objectId"] as? String else {
        throw LiveQueryErrors.InvalidJSONError(json: objectDictionary, expectedKey: "objectId")
    }

    let parseObject = T(withoutDataWithClassName: parseClassName, objectId: objectId)
    objectDictionary.filter { key, _ in
        key != "parseClassName" && key != "objectId"
        }.forEach { key, value in
            parseObject[key] = value
    }
    return parseObject
}

// ---------------
// MARK: Subscriptions
// ---------------

internal extension Client {
    internal class SubscriptionRecord {
        weak var subscriptionHandler: AnyObject?

        // HandlerClosure captures the generic type info passed into the constructor of SubscriptionRecord,
        // and 'unwraps' it so that it can be used with just a 'PFObject' instance.
        // Technically, this should be a compiler no-op, as no witness tables should be used as 'PFObject' currently inherits from NSObject.
        // Should we make PFObject ever a native swift class without the backing Objective-C runtime however,
        // this becomes extremely important to have, and makes a ton more sense than just unsafeBitCast-ing everywhere.
        var eventHandlerClosure: (Event<PFObject>, Client) -> Void
        var errorHandlerClosure: (ErrorType, Client) -> Void
        var subscribeHandlerClosure: Client -> Void
        var unsubscribeHandlerClosure: Client -> Void

        let query: PFQuery
        let requestId: RequestId

        init<T: SubscriptionHandling>(query: PFQuery, requestId: RequestId, handler: T) {
            self.query = query
            self.requestId = requestId

            subscriptionHandler = handler

            // This is needed because swift requires 'handlerClosure' to be fully initialized before we setup the
            // capture list for the closure.
            eventHandlerClosure = { _, _ in }
            errorHandlerClosure = { _, _ in }
            subscribeHandlerClosure = { _ in }
            unsubscribeHandlerClosure = { _ in }

            eventHandlerClosure = { [weak self] event, client in
                guard let handler = self?.subscriptionHandler as? T else {
                    return
                }

                handler.didReceive(Event(event: event), forQuery: query, inClient: client)
            }

            errorHandlerClosure = { [weak self] error, client in
                guard let handler = self?.subscriptionHandler as? T else {
                    return
                }

                handler.didEncounter(error, forQuery: query, inClient: client)
            }

            subscribeHandlerClosure = { [weak self] client in
                guard let handler = self?.subscriptionHandler as? T else {
                    return
                }

                handler.didSubscribe(toQuery: query, inClient: client)
            }

            unsubscribeHandlerClosure = { [weak self] client in
                guard let handler = self?.subscriptionHandler as? T else {
                    return
                }

                handler.didUnsubscribe(fromQuery: query, inClient: client)
            }
        }
    }

    // An opaque placeholder structed used to ensure that we type-safely create request IDs and don't shoot ourself in
    // the foot with array indexes.
    internal struct RequestId: Equatable {
        internal let value: Int

        internal init(value: Int) {
            self.value = value
        }
    }
}

func == (first: Client.RequestId, second: Client.RequestId) -> Bool {
    return first.value == second.value
}

// ---------------
// MARK: Web Socket
// ---------------

extension Client: SRWebSocketDelegate {
    public func webSocketDidOpen(webSocket: SRWebSocket!) {
        // TODO: Add support for session token and user authetication.
        self.sendOperationAsync(.Connect(applicationId: applicationId, sessionToken: ""))
    }

    public func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
        print("Error: \(error)")

        if !disconnected {
            reconnect()
        }
    }

    public func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        print("code: \(code) reason: \(reason)")

        // TODO: Better retry logic, unless `disconnect()` was explicitly called
        if !disconnected {
            reconnect()
        }
    }

    public func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject?) {
        guard let messageString = message as? String else {
            fatalError("Socket got into inconsistent state and received \(message) instead.")
        }
        handleOperationAsync(messageString).continueWith { task in
            if let error = task.error {
                print("Error: \(error)")
            }
        }
    }
}

// -------------------
// MARK: Operations
// -------------------

internal extension Event {
    init(serverResponse: ServerResponse, inout requestId: Client.RequestId) throws {
        switch serverResponse {
        case .Enter(let reqId, let object):
            requestId = reqId
            self = .Entered(try parseObject(object))

        case .Leave(let reqId, let object):
            requestId = reqId
            self = .Left(try parseObject(object))

        case .Create(let reqId, let object):
            requestId = reqId
            self = .Created(try parseObject(object))

        case .Update(let reqId, let object):
            requestId = reqId
            self = .Updated(try parseObject(object))

        case .Delete(let reqId, let object):
            requestId = reqId
            self = .Deleted(try parseObject(object))

        default: fatalError("Invalid state reached")
        }
    }
}

internal extension Client {
    private func subscriptionRecord(requestId: RequestId) -> SubscriptionRecord? {
        guard
            let recordIndex = self.subscriptions.indexOf({ $0.requestId == requestId }),
            let record: SubscriptionRecord = self.subscriptions[recordIndex]
            where record.subscriptionHandler != nil else {
                return nil
        }

        return record
    }

    internal func sendOperationAsync(operation: ClientOperation) -> Task<Void> {
        return Task(.Queue(queue)) {
            let jsonEncoded = operation.JSONObjectRepresentation
            let jsonData = try NSJSONSerialization.dataWithJSONObject(jsonEncoded, options: NSJSONWritingOptions(rawValue: 0))
            let jsonString = String(data: jsonData, encoding: NSUTF8StringEncoding)

            self.socket?.send(jsonString)
        }
    }

    internal func handleOperationAsync(string: String) -> Task<Void> {
        return Task(.Queue(queue)) {
            guard
                let jsonData = string.dataUsingEncoding(NSUTF8StringEncoding),
                let jsonDecoded = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions(rawValue: 0))
                    as? [String:AnyObject],
                let response: ServerResponse = try ServerResponse(json: jsonDecoded)
                else {
                    throw LiveQueryErrors.InvalidResponseError(response: string)
            }

            switch response {
            case .Connected:
                self.subscriptions.forEach {
                    self.sendOperationAsync(.Subscribe(requestId: $0.requestId, query: $0.query))
                }

            case .Redirect:
                // TODO: Handle redirect.
                break

            case .Subscribed(let requestId):
                self.subscriptionRecord(requestId)?.subscribeHandlerClosure(self)

            case .Unsubscribed(let requestId):
                guard
                    let recordIndex = self.subscriptions.indexOf({ $0.requestId == requestId }),
                    let record: SubscriptionRecord = self.subscriptions[recordIndex] else {
                        break
                }

                record.unsubscribeHandlerClosure(self)
                self.subscriptions.removeAtIndex(recordIndex)

            case .Create, .Delete, .Enter, .Leave, .Update:
                guard
                    var requestId: RequestId = RequestId(value: 0),
                    let event: Event<PFObject> = try Event(serverResponse: response, requestId: &requestId),
                    let record = self.subscriptionRecord(requestId)
                    else {
                        break
                }

                record.eventHandlerClosure(event, self)

            case .Error(let requestId, let code, let error, let reconnect):
                let error = LiveQueryErrors.ServerReportedError(code: code, error: error, reconnect: reconnect)
                if let requestId = requestId {
                    self.subscriptionRecord(requestId)?.errorHandlerClosure(error, self)
                } else {
                    throw error
                }
            }
        }
    }
}
