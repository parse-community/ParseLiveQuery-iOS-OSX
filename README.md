# Parse LiveQuery Client for iOS/OSX

[![Platforms][platforms-svg]][platforms-link]
[![Carthage compatible][carthage-svg]][carthage-link]

[![Podspec][podspec-svg]][podspec-link]
[![License][license-svg]][license-link]

[![Build Status][build-status-svg]][build-status-link]

`PFQuery` is one of the key concepts for Parse. It allows you to retrieve `PFObject`s by specifying some conditions, making it easy to build apps such as a dashboard, a todo list or even some strategy games. However, `PFQuery` is based on a pull model, which is not suitable for apps that need real-time support.

Suppose you are building an app that allows multiple users to edit the same file at the same time. `PFQuery` would not be an ideal tool since you can not know when to query from the server to get the updates.

To solve this problem, we introduce Parse LiveQuery. This tool allows you to subscribe to a `PFQuery` you are interested in. Once subscribed, the server will notify clients whenever a `PFObject` that matches the `PFQuery` is created or updated, in real-time.

## Setup Server

Parse LiveQuery contains two parts, the LiveQuery server and the LiveQuery clients. In order to use live queries, you need to set up both of them.

The easiest way to setup the LiveQuery server is to make it run with the [Open Source Parse Server](https://github.com/ParsePlatform/parse-server/wiki/Parse-LiveQuery#server-setup).

## Install Client

### Cocoapods

You can install the LiveQuery client via including it in your Podfile:

    pod 'ParseLiveQuery'


## Use Client

The LiveQuery client interface is based around the concept of `Subscription`s. You can register any `PFQuery` for live updates from the associated live query server, by simply calling `subscribe()` on a query:
```swift
let myQuery = Message.query()!.where(....)
let subscription: Subscription<Message> = Client.shared.subscribe(myQuery)
```

Where `Message` is a registered subclass of PFObject.

Once you've subscribed to a query, you can `handle` events on them, like so:
```swift
subscription.handleEvent { query, event in
    // Handle event
}
```

You can also handle a single type of event, if that's all you're interested in:
```swift
// Note it's handle(), not handleEvent()
subscription.handle(Event.created) { query, object in
    // Called whenever an object was created
}
```

By default, it will print the logs from WebSocket / WebSocketDelegate. You can turn it off:
```swift
Client.shared.shouldPrintWebSocketLog = false
```

Handling errors is and other events is similar, take a look at the `Subscription` class for more information.

## Advanced Usage

You are not limited to a single Live Query Client - you can create your own instances of `Client` to manually control things like reconnecting, server URLs, and more.

## How Do I Contribute?

We want to make contributing to this project as easy and transparent as possible. Please refer to the [Contribution Guidelines][contributing].

-----

As of April 5, 2017, Parse, LLC has transferred this code to the parse-community organization, and will no longer be contributing to or distributing this code.

 [releases]: https://github.com/parse-community/ParseLiveQuery-iOS-OSX/releases
 [contributing]: https://github.com/parse-community/ParseLiveQuery-iOS-OSX/blob/master/CONTRIBUTING.md

 [build-status-svg]: https://img.shields.io/travis/parse-community/ParseLiveQuery-iOS-OSX/master.svg
 [build-status-link]: https://travis-ci.org/parse-community/ParseLiveQuery-iOS-OSX/branches

 [coverage-status-svg]: https://img.shields.io/codecov/c/github/parse-community/ParseLiveQuery-iOS-OSX/master.svg
 [coverage-status-link]: https://codecov.io/github/parse-community/ParseLiveQuery-iOS-OSX?branch=master

 [license-svg]: https://img.shields.io/badge/license-BSD-lightgrey.svg
 [license-link]: https://github.com/parse-community/ParseLiveQuery-iOS-OSX/blob/master/LICENSE

 [podspec-svg]: https://img.shields.io/cocoapods/v/ParseLiveQuery.svg
 [podspec-link]: https://cocoapods.org/pods/ParseLiveQuery

 [platforms-svg]: http://img.shields.io/cocoapods/p/ParseLiveQuery.svg?style=flat
 [platforms-link]: https://github.com/parse-community/ParseLiveQuery-iOS-OSX

 [carthage-svg]:https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat
 [carthage-link]:https://github.com/Carthage/Carthage
