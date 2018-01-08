# ParseLiveQuery-iOS-OSX Changelog

# 2.2.3

- Bumps Parse SDK to 1.15.4 and Bolts to 1.9.0, thanks to [marcgovi](https://github.com/marcgovi)
- Updates logging strategy for websockets, thanks to [Joe Szymanski](https://github.com/JoeSzymanski)
- Ensures unsubscribed queries are removed from subscriptions list, thanks to [Joe Szymanski](https://github.com/JoeSzymanski)
- Do not attempt to reconnect if a connection is already in progress, thanks to [Joe Szymanski](https://github.com/JoeSzymanski)

# 2.2.2

- Adds ability to set the clientKey on the connect message, thanks to [bryandel](https://github.com/bryandel)
- Adds ability to silence the logs, thanks to [ananfang](https://github.com/ananfang)
- Ensures that `wss` URL's are properly handled, thanks to [Joe Szymanski](https://github.com/JoeSzymanski)

# 2.0.0

- Full carthage support, thanks to [David Starke](https://github.com/dstarke)

**Deprecates usage of SocketRocket in favour of Starscream**

- Adds support for sessionToken and user authentication, thanks to [Andrew Gordeev](https://github.com/andrew8712)
- Adds support for tvOS, thanks to [Kurt (kajensen)](https://github.com/kajensen)
- Adds support for updating subscription, thanks to [Florent Vilmart](https://github.com/flovilmart)
- Fixes for object decoding

# 1.1.0

- Breaking change: Swift 3 support
- Breaking change: OSX deployment target to 10.10
- New: Carthage support, thanks to [Florent Vilmart](https://github.com/flovilmart)
- New: Supports PFGeoPoints, thanks to [Nikita Lutsenko](https://github.com/nlutsenko)
- Fix: Deduplicates subscription requests, thanks to [Nathan Kellert](https://github.com/noobs2ninjas)
- New: Support for wss, thanks to [@kajensen](https://github.com/kajensen)
- Fix: Properly  deliver events back to obj-c, thanks to [Richard Ross](https://github.com/richardjrossiii)

