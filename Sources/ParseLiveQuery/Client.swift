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
import BoltsSwift
import SocketRocket

/**
 This is the 'advanced' view of live query subscriptions. It allows you to customize your subscriptions
 to a live query server, have connections to multiple servers, cleanly handle disconnect and reconnect.
 */
@objc(PFLiveQueryClient)
public class Client: NSObject {
    internal let host: NSURL
    internal let applicationId: String
    internal let clientKey: String?

    internal var socket: SRWebSocket?
    internal var disconnected = false

    // This allows us to easily plug in another request ID generation scheme, or more easily change the request id type
    // if needed (technically this could be a string).
    internal let requestIdGenerator: () -> RequestId
    internal var subscriptions = [SubscriptionRecord]()

    internal let queue = dispatch_queue_create("com.parse.livequery", DISPATCH_QUEUE_SERIAL)

    /**
     Creates a Client which automatically attempts to connect to the custom parse-server URL set in Parse.currentConfiguration().
     */
    public override convenience init() {
        self.init(server: Parse.validatedCurrentConfiguration().server)
    }

    /**
     Creates a client which will connect to a specific server with an optional application id and client key

     - parameter server:        The server to connect to
     - parameter applicationId: The application id to use
     - parameter clientKey:     The client key to use
     */
    public init(server: String, applicationId: String? = nil, clientKey: String? = nil) {
        guard let components = NSURLComponents(string: server) else {
            fatalError("Server should be a valid URL.")
        }
        components.scheme = "ws"
        components.path = "/LQ"

        // Simple incrementing generator - can't use ++, that operator is deprecated!
        var currentRequestId = 0
        requestIdGenerator = {
            currentRequestId += 1
            return RequestId(value: currentRequestId)
        }

        self.applicationId = applicationId ?? Parse.validatedCurrentConfiguration().applicationId!
        self.clientKey = clientKey ?? Parse.validatedCurrentConfiguration().clientKey

        self.host = components.URL!
    }
}

extension Client {
    // Swift is lame and doesn't allow storage to directly be in extensions.
    // So we create an inner struct to wrap it up.
    private class Storage {
        static var onceToken: dispatch_once_t = 0
        static var sharedStorage: Storage!
        static var shared: Storage {
            dispatch_once(&onceToken) {
                sharedStorage = Storage()
            }
            return sharedStorage
        }

        let queue: dispatch_queue_t = dispatch_queue_create("com.parse.livequery.client.storage", DISPATCH_QUEUE_SERIAL)
        var client: Client?
    }

    /// Gets or sets shared live query client to be used for default subscriptions
    @objc(sharedClient)
    public static var shared: Client! {
        get {
            let storage = Storage.shared
            var client: Client?
            dispatch_sync(storage.queue) {
                client = storage.client
                if client == nil {
                    let configuration = Parse.validatedCurrentConfiguration()
                    client = Client(
                        server: configuration.server,
                        applicationId: configuration.applicationId,
                        clientKey: configuration.clientKey
                    )
                    storage.client = client
                }
            }
            return client
        }
        set {
            let storage = Storage.shared
            dispatch_sync(storage.queue) {
                storage.client = newValue
            }
        }
    }
}

extension Client {
    /**
     Registers a query for live updates, using the default subscription handler

     - parameter query:        The query to register for updates.
     - parameter subclassType: The subclass of PFObject to be used as the type of the Subscription.
                               This parameter can be automatically inferred from context most of the time

     - returns: The subscription that has just been registered
     */
    public func subscribe<T where T: PFObject>(
        query: PFQuery,
        subclassType: T.Type = T.self
        ) -> Subscription<T> {
            return subscribe(query, handler: Subscription<T>())
    }

    /**
     Registers a query for live updates, using a custom subscription handler

     - parameter query:   The query to register for updates.
     - parameter handler: A custom subscription handler.

     - returns: Your subscription handler, for easy chaining.
     */
    public func subscribe<T where T: SubscriptionHandling>(
        query: PFQuery,
        handler: T
        ) -> T {
            let subscriptionRecord = SubscriptionRecord(
                query: query,
                requestId: requestIdGenerator(),
                handler: handler
            )
            subscriptions.append(subscriptionRecord)

            if socket == nil {
                if !disconnected {
                    reconnect()
                }
            } else {
                sendOperationAsync(.Subscribe(requestId: subscriptionRecord.requestId, query: query))
            }

            return handler
    }

    /**
     Unsubscribes all current subscriptions for a given query.

     - parameter query: The query to unsubscribe from.
     */
    @objc(unsubscribeFromQuery:)
    public func unsubscribe(query: PFQuery) {
        unsubscribe { $0.query == query }
    }

    /**
     Unsubscribes from a specific query-handler pair.

     - parameter query:   The query to unsubscribe from.
     - parameter handler: The specific handler to unsubscribe from.
     */
    public func unsubscribe<T where T: SubscriptionHandling>(query: PFQuery, handler: T) {
        unsubscribe { $0.query == query && $0.subscriptionHandler === handler }
    }

    internal func unsubscribe(@noescape matching matcher: SubscriptionRecord -> Bool) {
        subscriptions.filter {
            matcher($0)
        }.forEach {
            sendOperationAsync(.Unsubscribe(requestId: $0.requestId))
        }
    }
}

extension Client {
    /**
     Reconnects this client to the server.

     This will disconnect and resubscribe all existing subscriptions. This is not required to be called the first time
     you use the client, and should usually only be called when an error occurs.
     */
    public func reconnect() {
        socket?.close()
        socket = {
            let socket = SRWebSocket(URL: host)
            socket.delegate = self
            socket.setDelegateDispatchQueue(queue)
            socket.open()

            return socket
            }()
    }

    /**
     Explicitly disconnects this client from the server.

     This does not remove any subscriptions - if you `reconnect()` your existing subscriptions will be restored.
     Use this if you wish to dispose of the live query client.
     */
    public func disconnect() {
        guard let socket = socket
            else {
                return
        }
        socket.close()
        self.socket = nil
        disconnected = true
    }
}
