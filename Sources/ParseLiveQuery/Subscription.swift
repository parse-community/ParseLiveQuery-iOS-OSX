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

/**
 This protocol describes the interface for handling events from a liveQuery client.

 You can use this protocol on any custom class of yours, instead of Subscription, if it fits your use case better.
 */
public protocol SubscriptionHandling: AnyObject {
    /// The type of the PFObject subclass that this handler uses.
    typealias PFObjectSubclass: PFObject

    /**
     Tells the handler that an event has been received from the live query server.

     - parameter event: The event that has been recieved from the server.
     - parameter query: The query that the event occurred on.
     - parameter client: The live query client which received this event.
     */
    func didReceive(event: Event<PFObjectSubclass>, forQuery query: PFQuery, inClient client: Client)

    /**
     Tells the handler that an error has been received from the live query server.

     - parameter error: The error that the server has encountered.
     - parameter query: The query that the error occurred on.
     - parameter client: The live query client which received this error.
     */
    func didEncounter(error: ErrorType, forQuery query: PFQuery, inClient client: Client)

    /**
     Tells the handler that a query has been successfully registered with the server.

     - note: This may be invoked multiple times if the client disconnects/reconnects.

     - parameter query: The query that has been subscribed.
     - parameter client: The live query client which subscribed this query.
     */
    func didSubscribe(toQuery query: PFQuery, inClient client: Client)

    /**
     Tells the handler that a query has been successfully deregistered from the server.

     - note: This is not called unless `unregister()` is explicitly called.

     - parameter query: The query that has been unsubscribed.
     - parameter client: The live query client which unsubscribed this query.
     */
    func didUnsubscribe(fromQuery query: PFQuery, inClient client: Client)
}

/**
 Represents an update on a specific object from the live query server.

 - Entered: The object has been updated, and is now included in the query.
 - Left:    The object has been updated, and is no longer included in the query.
 - Created: The object has been created, and is a part of the query.
 - Updated: The object has been updated, and is still a part of the query.
 - Deleted: The object has been deleted, and is no longer included in the query.
 */
public enum Event<T where T: PFObject> {
    /// The object has been updated, and is now included in the query
    case Entered(T)

    /// The object has been updated, and is no longer included in the query
    case Left(T)

    /// The object has been created, and is a part of the query
    case Created(T)

    /// The object has been updated, and is still a part of the query
    case Updated(T)

    /// The object has been deleted, and is no longer included in the query
    case Deleted(T)

    internal init<V where V: PFObject>(event: Event<V>) {
        switch event {
        case .Entered(let value as T): self = .Entered(value)
        case .Left(let value as T):    self = .Left(value)
        case .Created(let value as T): self = .Created(value)
        case .Updated(let value as T): self = .Updated(value)
        case .Deleted(let value as T): self = .Deleted(value)
        default: fatalError()
        }
    }
}

private func == <T: PFObject>(lhs: Event<T>, rhs: Event<T>) -> Bool {
    switch (lhs, rhs) {
    case (.Entered(let obj1), .Entered(let obj2)): return obj1 == obj2
    case (.Left(let obj1), .Left(let obj2)):       return obj1 == obj2
    case (.Created(let obj1), .Created(let obj2)): return obj1 == obj2
    case (.Updated(let obj1), .Updated(let obj2)): return obj1 == obj2
    case (.Deleted(let obj1), .Deleted(let obj2)): return obj1 == obj2
    default: return false
    }
}

/**
 A default implementation of the SubscriptionHandling protocol, using closures for callbacks.
 */
public class Subscription<T where T: PFObject>: SubscriptionHandling {
    private var errorHandlers: [(PFQuery, ErrorType) -> Void] = []
    private var eventHandlers: [(PFQuery, Event<T>) -> Void] = []
    private var subscribeHandlers: [PFQuery -> Void] = []
    private var unsubscribeHandlers: [PFQuery -> Void] = []

    /**
     Creates a new subscription that can be used to handle updates.
     */
    public init() {
    }

    /**
     Register a callback for when an error occurs.

     - parameter handler: The callback to register.

     - returns: The same subscription, for easy chaining
     */
    public func handleError(handler: (PFQuery, ErrorType) -> Void) -> Subscription {
        errorHandlers.append(handler)
        return self
    }

    /**
     Register a callback for when an event occurs.

     - parameter handler: The callback to register.

     - returns: The same subscription, for easy chaining.
     */
    public func handleEvent(handler: (PFQuery, Event<T>) -> Void) -> Subscription {
        eventHandlers.append(handler)
        return self
    }

    /**
     Register a callback for when a client succesfully subscribes to a query.

     - parameter handler: The callback to register.

     - returns: The same subscription, for easy chaining.
     */
    public func handleSubscribe(handler: PFQuery -> Void) -> Subscription {
        subscribeHandlers.append(handler)
        return self
    }

    /**
     Register a callback for when a query has been unsubscribed.

     - parameter handler: The callback to register.

     - returns: The same subscription, for easy chaining.
     */
    public func handleUnsubscribe(handler: PFQuery -> Void) -> Subscription {
        unsubscribeHandlers.append(handler)
        return self
    }

    // ---------------
    // MARK: SubscriptionHandling
    // TODO: Move to extension once swift compiler is less crashy
    // ---------------
    public typealias PFObjectSubclass = T

    public func didReceive(event: Event<PFObjectSubclass>, forQuery query: PFQuery, inClient client: Client) {
        eventHandlers.forEach { $0(query, event) }
    }

    public func didEncounter(error: ErrorType, forQuery query: PFQuery, inClient client: Client) {
        errorHandlers.forEach { $0(query, error) }
    }

    public func didSubscribe(toQuery query: PFQuery, inClient client: Client) {
        subscribeHandlers.forEach { $0(query) }
    }

    public func didUnsubscribe(fromQuery query: PFQuery, inClient client: Client) {
        unsubscribeHandlers.forEach { $0(query) }
    }
}

extension Subscription {
    /**
     Register a callback for when an error occcurs of a specific type

     Example:

         subscription.handle(LiveQueryErrors.InvalidJSONError.self) { query, error in
             print(error)
          }

     - parameter errorType: The error type to register for
     - parameter handler:   The callback to register

     - returns: The same subscription, for easy chaining
     */
    public func handle<E: ErrorType>(
        errorType: E.Type = E.self,
        _ handler: (PFQuery, E) -> Void
        ) -> Subscription {
            errorHandlers.append { query, error in
                if let error = error as? E {
                    handler(query, error)
                }
            }
            return self
    }

    /**
     Register a callback for when an event occurs of a specific type

     Example:

         subscription.handle(Event.Created) { query, object in
            // Called whenever an object is creaated
         }

     - parameter eventType: The event type to handle. You should pass one of the enum cases in `Event`
     - parameter handler:   The callback to register

     - returns: The same subscription, for easy chaining

     */
    public func handle(eventType: T -> Event<T>, _ handler: (PFQuery, T) -> Void) -> Subscription {
        return handleEvent { query, event in
            switch event {
            case .Entered(let obj) where eventType(obj) == event: handler(query, obj)
            case .Left(let obj)  where eventType(obj) == event: handler(query, obj)
            case .Created(let obj) where eventType(obj) == event: handler(query, obj)
            case .Updated(let obj) where eventType(obj) == event: handler(query, obj)
            case .Deleted(let obj) where eventType(obj) == event: handler(query, obj)
            default: return
            }
        }
    }
}
