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
import Starscream
import BoltsSwift

private func parseObject<T: PFObject>(_ objectDictionary: [String:AnyObject]) throws -> T {
    guard let _ = objectDictionary["className"] as? String else {
        throw LiveQueryErrors.InvalidJSONError(json: objectDictionary, expectedKey: "parseClassName")
    }
    guard let _ = objectDictionary["objectId"] as? String else {
        throw LiveQueryErrors.InvalidJSONError(json: objectDictionary, expectedKey: "objectId")
    }

    guard let object =  PFDecoder.object().decode(objectDictionary) as? T else {
        throw LiveQueryErrors.InvalidJSONObject(json: objectDictionary, details: "cannot decode json into \(T.self)")
    }

    return object
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

        init<T>(query: PFQuery<T.PFObjectSubclass>, requestId: RequestId, handler: T) where T:SubscriptionHandling {
            self.query = query as! PFQuery<PFObject>
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
}
extension Client {
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

extension Client: WebSocketDelegate {

    public func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print("Received binary data but we don't handle it...")
    }

    public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        handleOperationAsync(text).continueWith { task in
            if let error = task.error {
                print("Error: \(error)")
            }
        }
    }

    public func websocketDidConnect(socket: WebSocket) {
        let sessionToken = PFUser.current()?.sessionToken ?? ""
        _ = self.sendOperationAsync(.connect(applicationId: applicationId, sessionToken: sessionToken, clientKey: clientKey))
    }

    public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print("error: \(error)")

        // TODO: Better retry logic, unless `disconnect()` was explicitly called
        if !userDisconnected {
            reconnect()
        }
    }

    public func webSocket(_ webSocket: WebSocket, didCloseWithCode code: Int, reason: String?, wasClean: Bool) {
        print("code: \(code) reason: \(reason)")

        // TODO: Better retry logic, unless `disconnect()` was explicitly called
        if !userDisconnected {
            reconnect()
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
            let recordIndex = self.subscriptions.index(where: { $0.requestId == requestId }) else {
                return nil
        }
        let record = self.subscriptions[recordIndex]
        return record.subscriptionHandler != nil ? record : nil
    }

    func sendOperationAsync(_ operation: ClientOperation) -> Task<Void> {
        return Task(.queue(queue)) {
            let jsonEncoded = operation.JSONObjectRepresentation
            let jsonData = try JSONSerialization.data(withJSONObject: jsonEncoded, options: JSONSerialization.WritingOptions(rawValue: 0))
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
            self.socket?.write(string: jsonString!)
        }
    }

    func handleOperationAsync(_ string: String) -> Task<Void> {
        return Task(.queue(queue)) {
            guard
                let jsonData = string.data(using: String.Encoding.utf8),
                let jsonDecoded = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions(rawValue: 0))
                    as? [String:AnyObject],
                let response: ServerResponse = try? ServerResponse(json: jsonDecoded)
                else {
                    throw LiveQueryErrors.InvalidResponseError(response: string)
            }



            switch response {
            case .connected:
                let sessionToken = PFUser.current()?.sessionToken
                self.subscriptions.forEach {
                    _ = self.sendOperationAsync(.subscribe(requestId: $0.requestId, query: $0.query, sessionToken: sessionToken))
                }

            case .redirect:
                // TODO: Handle redirect.
                break

            case .subscribed(let requestId):
                self.subscriptionRecord(requestId)?.subscribeHandlerClosure(self)

            case .unsubscribed(let requestId):
                guard
                    let recordIndex = self.subscriptions.index(where: { $0.requestId == requestId })
                     else {
                        break
                }
                let record: SubscriptionRecord = self.subscriptions[recordIndex]
                record.unsubscribeHandlerClosure(self)
                self.subscriptions.remove(at: recordIndex)

            case .create, .delete, .enter, .leave, .update:
                var requestId: RequestId = RequestId(value: 0)
                guard
                    let event: Event<PFObject> = try? Event(serverResponse: response, requestId: &requestId),
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
