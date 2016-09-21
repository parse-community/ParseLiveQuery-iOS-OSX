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

private func parseObject<T: PFObject>(_ objectDictionary: [String:AnyObject]) throws -> T {
    guard let parseClassName = objectDictionary["className"] as? String else {
        throw LiveQueryErrors.InvalidJSONError(json: objectDictionary, expectedKey: "parseClassName")
    }
    guard let objectId = objectDictionary["objectId"] as? String else {
        throw LiveQueryErrors.InvalidJSONError(json: objectDictionary, expectedKey: "objectId")
    }

    let parseObject = T(withoutDataWithClassName: parseClassName, objectId: objectId)

    // Map of strings to closures to determine if the key is valid. Allows for more advanced checking of
    // classnames and such.
    let invalidKeys: [String:(Void)->Bool] = [
        "objectId": { true },
        "parseClassName": { true },
        "sessionToken": { parseClassName == "_User" }
    ]

    objectDictionary.filter { key, _ in
        return !(invalidKeys[key].map { $0() } ?? false)
    }.forEach { key, value in
        parseObject[key] = value
    }
    return parseObject
}

// ---------------
// MARK: Subscriptions
// ---------------

extension Client {
    class SubscriptionRecord {
        weak var subscriptionHandler: AnyObject?

        // HandlerClosure captures the generic type info passed into the constructor of SubscriptionRecord,
        // and 'unwraps' it so that it can be used with just a 'PFObject' instance.
        // Technically, this should be a compiler no-op, as no witness tables should be used as 'PFObject' currently inherits from NSObject.
        // Should we make PFObject ever a native swift class without the backing Objective-C runtime however,
        // this becomes extremely important to have, and makes a ton more sense than just unsafeBitCast-ing everywhere.
        var eventHandlerClosure: (Event<PFObject>, Client) -> Void
        var errorHandlerClosure: (Error, Client) -> Void
        var subscribeHandlerClosure: (Client) -> Void
        var unsubscribeHandlerClosure: (Client) -> Void

        let query: PFQuery<PFObject>
        let requestId: RequestId

        init<T: SubscriptionHandling>(query: PFQuery<PFObject>, requestId: RequestId, handler: T) {
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
    struct RequestId: Equatable {
        let value: Int

        init(value: Int) {
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
    public func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        // TODO: Add support for session token and user authetication.
        self.sendOperationAsync(.connect(applicationId: applicationId, sessionToken: ""))
    }

    @nonobjc public func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: NSError!) {
        print("Error: \(error)")

        if !userDisconnected {
            reconnect()
        }
    }

    public func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        print("code: \(code) reason: \(reason)")

        // TODO: Better retry logic, unless `disconnect()` was explicitly called
        if !userDisconnected {
            reconnect()
        }
    }

    public func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
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

extension Event {
    init(serverResponse: ServerResponse, requestId: inout Client.RequestId) throws {
        switch serverResponse {
        case .enter(let reqId, let object):
            requestId = reqId
            self = .entered(try parseObject(object))

        case .leave(let reqId, let object):
            requestId = reqId
            self = .left(try parseObject(object))

        case .create(let reqId, let object):
            requestId = reqId
            self = .created(try parseObject(object))

        case .update(let reqId, let object):
            requestId = reqId
            self = .updated(try parseObject(object))

        case .delete(let reqId, let object):
            requestId = reqId
            self = .deleted(try parseObject(object))

        default: fatalError("Invalid state reached")
        }
    }
}

extension Client {
    fileprivate func subscriptionRecord(_ requestId: RequestId) -> SubscriptionRecord? {
        guard
            let recordIndex = self.subscriptions.index(where: { $0.requestId == requestId }),
            let record: SubscriptionRecord = self.subscriptions[recordIndex]
            , record.subscriptionHandler != nil else {
                return nil
        }

        return record
    }

    func sendOperationAsync(_ operation: ClientOperation) -> Task<Void> {
        return Task(.queue(queue)) {
            let jsonEncoded = operation.JSONObjectRepresentation
            let jsonData = try JSONSerialization.data(withJSONObject: jsonEncoded, options: JSONSerialization.WritingOptions(rawValue: 0))
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)

            self.socket?.send(jsonString)
        }
    }

    func handleOperationAsync(_ string: String) -> Task<Void> {
        return Task(.queue(queue)) {
            guard
                let jsonData = string.data(using: String.Encoding.utf8),
                let jsonDecoded = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions(rawValue: 0))
                    as? [String:AnyObject],
                let response: ServerResponse = try ServerResponse(json: jsonDecoded)
                else {
                    throw LiveQueryErrors.InvalidResponseError(response: string)
            }

            switch response {
            case .connected:
                self.subscriptions.forEach {
                    self.sendOperationAsync(.subscribe(requestId: $0.requestId, query: $0.query))
                }

            case .redirect:
                // TODO: Handle redirect.
                break

            case .subscribed(let requestId):
                self.subscriptionRecord(requestId)?.subscribeHandlerClosure(self)

            case .unsubscribed(let requestId):
                guard
                    let recordIndex = self.subscriptions.index(where: { $0.requestId == requestId }),
                    let record: SubscriptionRecord = self.subscriptions[recordIndex] else {
                        break
                }

                record.unsubscribeHandlerClosure(self)
                self.subscriptions.remove(at: recordIndex)

            case .create, .delete, .enter, .leave, .update:
                guard
                    var requestId: RequestId = RequestId(value: 0),
                    let event: Event<PFObject> = try Event(serverResponse: response, requestId: &requestId),
                    let record = self.subscriptionRecord(requestId)
                    else {
                        break
                }

                record.eventHandlerClosure(event, self)

            case .error(let requestId, let code, let error, let reconnect):
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
