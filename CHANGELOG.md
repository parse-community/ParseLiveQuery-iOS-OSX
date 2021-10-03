## ParseLiveQuery-iOS-OSX Changelog

### Main

[Full Changelog](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/compare/2.8.1...main)

### 2.8.1

[Full Changelog](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/compare/2.8.0...2.8.1)

- Add missing WebSocketEvent cases ([#250](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/250)), thanks to [tmg-mlyons](https://github.com/tmg-mlyons).
- Move Event outside of ObjCCompat to work around a compiler issue ([#245](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/245)), thanks to [Frédéric Maquin](https://github.com/ephread).
- Allows for nested inQuery and orQuery ([#240](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/240)), thanks to [Jonathan Lott](https://github.com/jlott1).

### 2.8.0

[Full Changelog](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/compare/2.7.3...2.8.0)

- Bump Starscream dependency to >= 4.0.4 ([#236](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/236)), thanks to [Corey Baker](https://github.com/cbaker6).
- Bump Parse SDK to v.1.19.1 ([#236](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/236)), thanks to [Corey Baker](https://github.com/cbaker6).
- Minimum support due to Xcode 12 and dependencies (iOS 9) ([#236](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/236)), thanks to [Corey Baker](https://github.com/cbaker6).

### 2.7.3

[Full Changelog](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/compare/2.7.2...2.7.3)

- Add watchOS and tvOS support ([#235](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/235)), thanks to [Corey Baker](https://github.com/cbaker6)
- Add caching to CI for faster builds ([#235](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/235)), thanks to [Corey Baker](https://github.com/cbaker6)
- Update project and podspecs with respect to dependencies ([#235](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/235)), thanks to [Corey Baker](https://github.com/cbaker6)
- Update jazzy docs to newer version ([#235](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/235)), thanks to [Corey Baker](https://github.com/cbaker6)
- Minimum support due to dependencies (iOS 8, macOS 10.10, tvOS 10, watchOS 2.0) ([#235](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/235)), thanks to [Corey Baker](https://github.com/cbaker6)

### 2.7.2

[Full Changelog](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/compare/2.7.1...2.7.2)

- Bump Parse SDK to v.1.19.0 ([#229](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/229)), thanks to [Tom Fox](https://github.com/TomWFox).

### 2.7.1

[Full Changelog](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/compare/2.7.0...2.7.1)

- Bump Parse SDK to v1.18.0
([#226](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/226)), thanks to [Nathan Kellert](https://github.com/noobs2ninjas).

- Remove Bolts-ObjC as dependency
([#223](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/223)), thanks to [Joe Szymanski](https://github.com/JoeSzymanski).

### 2.7.0

[Full Changelog](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/compare/2.6.1...2.7.0)

- Build compatibility with Xcode 11 and iOS 13 ([#210](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/210)), thanks to [Nathan Kellert](https://github.com/noobs2ninjas) & [Darren Black](https://github.com/drdaz).
- Bump Parse SDK to v1.17.3 ([#210](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/210)), thanks to [Nathan Kellert](https://github.com/noobs2ninjas) & [Darren Black](https://github.com/drdaz).
- Moves to Swift 5 ([#210](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/210)), thanks to [Nathan Kellert](https://github.com/noobs2ninjas) & [Darren Black](https://github.com/drdaz).
- Bump Bolts-Swift dependency to v1.5.0 ([#210](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/210)), thanks to [Nathan Kellert](https://github.com/noobs2ninjas) & [Darren Black](https://github.com/drdaz).
- Properly encode Array of GeoPoints ([#208](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/208)), thanks to [Diamond Lewis](https://github.com/dplewis).

### 2.6.1

[Full Changelog](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/compare/2.6.0...2.6.1)

**This will be the final release for Swift 4.2**

- Fix #190, thanks to [rostopira](https://github.com/rostopira).
- Bumps Parse SDK to 1.17.1.
- Bumps Starscream to 3.0.5.

### 2.6.0

- Fixed issue where no "where" property sent when no constraints where added to a query. This is required by the LiveQuery protocol. 
- Support for `.or` queries. Fixes #156, #47, and #85. Allows orQuery to be encoded without throwing, thanks to [dblythy](https://github.com/dblythy).
- Added @objc to compile with objective-c ([#184](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/184)), thanks to [Junya Yamaguchi](https://github.com/junya100).
- Encode Date object with __type: Date ([#186](https://github.com/parse-community/ParseLiveQuery-iOS-OSX/pull/186)), thanks to [anafang](https://github.com/ananfang).

### 2.5.0

- Bumps Bolts-Swift to 1.4.0.
- Bumps Swift version to 4.2.

### 2.4.0

- Bumps Parse SDK to 1.17.0.
- Bumps cocoapods to 1.4.0.
- Set Swift version to 3.2.

### 2.3.0

- Bumps Parse SDK to 1.16.0.
- Bumps Starscream to 3.0.4.
- Fixes warnings in Swift 4.

### 2.2.3

- Bumps Parse SDK to 1.15.4 and Bolts to 1.9.0, thanks to [marcgovi](https://github.com/marcgovi).
- Updates logging strategy for websockets, thanks to [Joe Szymanski](https://github.com/JoeSzymanski).
- Ensures unsubscribed queries are removed from subscriptions list, thanks to [Joe Szymanski](https://github.com/JoeSzymanski).
- Do not attempt to reconnect if a connection is already in progress, thanks to [Joe Szymanski](https://github.com/JoeSzymanski).

### 2.2.2

- Adds ability to set the clientKey on the connect message, thanks to [bryandel](https://github.com/bryandel).
- Adds ability to silence the logs, thanks to [ananfang](https://github.com/ananfang).
- Ensures that `wss` URL's are properly handled, thanks to [Joe Szymanski](https://github.com/JoeSzymanski).

### 2.0.0

- Full carthage support, thanks to [David Starke](https://github.com/dstarke).

**Deprecates usage of SocketRocket in favour of Starscream**

- Adds support for sessionToken and user authentication, thanks to [Andrew Gordeev](https://github.com/andrew8712).
- Adds support for tvOS, thanks to [Kurt (kajensen)](https://github.com/kajensen).
- Adds support for updating subscription, thanks to [Florent Vilmart](https://github.com/flovilmart).
- Fixes for object decoding.

### 1.1.0

- Breaking change: Swift 3 support.
- Breaking change: OSX deployment target to 10.10.
- New: Carthage support, thanks to [Florent Vilmart](https://github.com/flovilmart).
- New: Supports PFGeoPoints, thanks to [Nikita Lutsenko](https://github.com/nlutsenko).
- Fix: Deduplicates subscription requests, thanks to [Nathan Kellert](https://github.com/noobs2ninjas).
- New: Support for wss, thanks to [@kajensen](https://github.com/kajensen).
- Fix: Properly deliver events back to obj-c, thanks to [Richard Ross](https://github.com/richardjrossiii).
