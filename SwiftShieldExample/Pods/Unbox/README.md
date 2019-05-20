<p align="center">
    <img src="logo.png" width="300" max-width="50%" alt="Unbox" />
</p>

<p align="center">
    <b>Unbox</b>
    |
    <a href="https://github.com/johnsundell/wrap">Wrap</a>
</p>

<p align="center">
    <a href="https://travis-ci.org/JohnSundell/Unbox/branches">
        <img src="https://img.shields.io/travis/JohnSundell/Unbox/master.svg" alt="Travis status" />
    </a>
    <a href="https://cocoapods.org/pods/Unbox">
        <img src="https://img.shields.io/cocoapods/v/Unbox.svg" alt="CocoaPods" />
    </a>
    <a href="https://github.com/Carthage/Carthage">
        <img src="https://img.shields.io/badge/carthage-compatible-4BC51D.svg?style=flat" alt="Carthage" />
    </a>
    <a href="https://twitter.com/johnsundell">
        <img src="https://img.shields.io/badge/contact-@johnsundell-blue.svg?style=flat" alt="Twitter: @johnsundell" />
    </a>
</p>

Unbox is an easy to use Swift JSON decoder. Don't spend hours writing JSON decoding code - just unbox it instead!

Unbox is lightweight, non-magical and doesn't require you to subclass, make your JSON conform to a specific schema or completely change the way you write model code. It can be used on any model with ease.

### Basic example

Say you have your usual-suspect `User` model:

```swift
struct User {
    let name: String
    let age: Int
}
```

That can be initialized with the following JSON:

```json
{
    "name": "John",
    "age": 27
}
```

To decode this JSON into a `User` instance, all you have to do is make `User` conform to `Unboxable` and unbox its properties:

```swift
struct User {
    let name: String
    let age: Int
}

extension User: Unboxable {
    init(unboxer: Unboxer) throws {
        self.name = try unboxer.unbox(key: "name")
        self.age = try unboxer.unbox(key: "age")
    }
}
```

Unbox automatically (or, actually, Swift does) figures out what types your properties are, and decodes them accordingly. Now, we can decode a `User` like this:

```swift
let user: User = try unbox(dictionary: dictionary)
```
or even:
```swift
let user: User = try unbox(data: data)
```

### Advanced example

The first was a pretty simple example, but Unbox can decode even the most complicated JSON structures for you, with both required and optional values, all without any extra code on your part:

```swift
struct SpaceShip {
    let type: SpaceShipType
    let weight: Double
    let engine: Engine
    let passengers: [Astronaut]
    let launchLiveStreamURL: URL?
    let lastPilot: Astronaut?
    let lastLaunchDate: Date?
}

extension SpaceShip: Unboxable {
    init(unboxer: Unboxer) throws {
        self.type = try unboxer.unbox(key: "type")
        self.weight = try unboxer.unbox(key: "weight")
        self.engine = try unboxer.unbox(key: "engine")
        self.passengers = try unboxer.unbox(key: "passengers")
        self.launchLiveStreamURL = try? unboxer.unbox(key: "liveStreamURL")
        self.lastPilot = try? unboxer.unbox(key: "lastPilot")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        self.lastLaunchDate = try? unboxer.unbox(key: "lastLaunchDate", formatter: dateFormatter)
    }
}

enum SpaceShipType: Int, UnboxableEnum {
    case apollo
    case sputnik
}

struct Engine {
    let manufacturer: String
    let fuelConsumption: Float
}

extension Engine: Unboxable {
    init(unboxer: Unboxer) throws {
        self.manufacturer = try unboxer.unbox(key: "manufacturer")
        self.fuelConsumption = try unboxer.unbox(key: "fuelConsumption")
    }
}

struct Astronaut {
    let name: String
}

extension Astronaut: Unboxable {
    init(unboxer: Unboxer) throws {
        self.name = try unboxer.unbox(key: "name")
    }
}
```

### Error handling

Decoding JSON is inherently a failable operation. The JSON might be in an unexpected format, or a required value might be missing. Thankfully, Unbox takes care of handling both missing and mismatched values gracefully, and uses Swift’s `do, try, catch` pattern to return errors to you.

You don’t have to deal with multiple error types and perform any checking yourself, and you always have the option to manually exit an unboxing process by `throwing`. All errors returned by Unbox are of the type `UnboxError`.

### Supported types

Unbox supports decoding all standard JSON types, like:

- `Bool`
- `Int`, `Double`, `Float`
- `String`
- `Array`
- `Dictionary`

It also supports all possible combinations of nested arrays & dictionaries. As you can see in the **Advanced example** above (where an array of the unboxable `Astronaut` struct is being unboxed), we can unbox even a complicated data structure with one simple call to `unbox()`.

Finally, it also supports `URL` through the use of a transformer, and `Date` by using any `DateFormatter`.

### Transformations

Unbox also supports transformations that let you treat any value or object as if it was a raw JSON type.

It ships with a default `String` -> `URL` transformation, which lets you unbox any `URL` property from a string describing an URL without writing any transformation code.

The same is also true for `String` -> `Int, Double, Float, CGFloat` transformations. If you’re unboxing a number type and a string was found, that string will automatically be converted to that number type (if possible).

To enable your own types to be unboxable using a transformation, all you have to do is make your type conform to `UnboxableByTransform` and implement its protocol methods.

Here’s an example that makes a native Swift `UniqueIdentifier` type unboxable using a transformation:

```swift
struct UniqueIdentifier: UnboxableByTransform {
    typealias UnboxRawValueType = String

    let identifierString: String

    init?(identifierString: String) {
        if let UUID = NSUUID(uuidString: identifierString) {
            self.identifierString = UUID.uuidString
        } else {
            return nil
        }
    }

    static func transform(unboxedValue: String) -> UniqueIdentifier? {
        return UniqueIdentifier(identifierString: unboxedValue)
    }
}
```

### Formatters

If you have values that need to be formatted before use, Unbox supports using formatters to automatically format an unboxed value. Any `DateFormatter` can out of the box be used to format dates, but you can also add formatters for your own custom types, like this:

```swift
enum Currency {
    case usd(Int)
    case sek(Int)
    case pln(Int)
}

struct CurrencyFormatter: UnboxFormatter {
    func format(unboxedValue: String) -> Currency? {
        let components = unboxedValue.components(separatedBy: ":")

        guard components.count == 2 else {
            return nil
        }

        let identifier = components[0]

        guard let value = Int(components[1]) else {
            return nil
        }

        switch identifier {
        case "usd":
            return .usd(value)
        case "sek":
            return .sek(value)
        case "pln":
            return .pln(value)
        default:
            return nil
        }
    }
}
```

You can now easily unbox any `Currency` using a given `CurrencyFormatter`:

```swift
struct Product: Unboxable {
    let name: String
    let price: Currency

    init(unboxer: Unboxer) throws {
        name = try unboxer.unbox(key: "name")
        price = try unboxer.unbox(key: "price", formatter: CurrencyFormatter())
    }
}
```

### Supports JSON with both Array and Dictionary root objects

No matter if the root object of the JSON that you want to unbox is an `Array` or `Dictionary` - you can use the same `Unbox()` function and Unbox will return either a single model or an array of models (based on type inference).

### Built-in enum support

You can also unbox `enums` directly, without having to handle the case if they failed to initialize. All you have to do is make any `enum` type you wish to unbox conform to `UnboxableEnum`, like this:

```swift
enum Profession: Int, UnboxableEnum {
    case developer
    case astronaut
}
```

Now `Profession` can be unboxed directly in any model

```swift
struct Passenger: Unboxable {
    let profession: Profession

    init(unboxer: Unboxer) throws {
        self.profession = try unboxer.unbox(key: "profession")
    }
}
```

### Contextual objects

Sometimes you need to use data other than what's contained in a dictionary during the decoding process. For this, Unbox has support for strongly typed contextual objects that can be made available in the unboxing initializer.

To use contextual objects, make your type conform to `UnboxableWithContext`, which can then be unboxed using `unbox(dictionary:context)` where `context` is of the type of your choice.

### Key path support

You can also use key paths (for both dictionary keys and array indexes) to unbox values from nested JSON structures. Let's expand our User model:

```json
{
    "name": "John",
    "age": 27,
    "activities": {
        "running": {
            "distance": 300
        }
    },
    "devices": [
        "Macbook Pro",
        "iPhone",
        "iPad"
    ]
}
```

```swift
struct User {
    let name: String
    let age: Int
    let runningDistance: Int
    let primaryDeviceName: String
}

extension User: Unboxable {
    init(unboxer: Unboxer) throws {
        self.name = try unboxer.unbox(key: "name")
        self.age = try unboxer.unbox(key: "age")
        self.runningDistance = try unboxer.unbox(keyPath: "activities.running.distance")
        self.primaryDeviceName = try unboxer.unbox(keyPath: "devices.0")
    }
}
```

You can also use key paths to directly unbox nested JSON structures. This is useful when you only need to extract a specific object (or objects) out of the JSON body.

```json
{
    "company": {
        "name": "Spotify",
    },
    "jobOpenings": [
        {
            "title": "Swift Developer",
            "salary": 120000
        },
        {
            "title": "UI Designer",
            "salary": 100000
        },
    ]
}
```

```swift
struct JobOpening {
    let title: String
    let salary: Int
}

extension JobOpening: Unboxable {
    init(unboxer: Unboxer) throws {
        self.title = try unboxer.unbox(key: "title")
        self.salary = try unboxer.unbox(key: "salary")
    }
}

struct Company {
    let name: String
}

extension Company: Unboxable {
    init(unboxer: Unboxer) throws {
        self.name = try unboxer.unbox(key: "name")
    }
}
```

```swift
let company: Company = try unbox(dictionary: json, atKey: "company")
let jobOpenings: [JobOpening] = try unbox(dictionary: json, atKey: "jobOpenings")
let featuredOpening: JobOpening = try unbox(dictionary: json, atKeyPath: "jobOpenings.0")
```

### Custom unboxing

Sometimes you need more fine grained control over the decoding process, and even though Unbox was designed for simplicity, it also features a powerful custom unboxing API that enables you to take control of how an object gets unboxed. This comes very much in handy when using Unbox together with Core Data, when using dependency injection, or when aggregating data from multiple sources. Here's an example:

```swift
let dependency = DependencyManager.loadDependency()

let model: Model = try Unboxer.performCustomUnboxing(dictionary: dictionary, closure: { unboxer in
    var model = Model(dependency: dependency)
    model.name = try? unboxer.unbox(key: "name")
    model.count = try? unboxer.unbox(key: "count")

    return model
})
```

### Installation

**CocoaPods:**

Add the line `pod "Unbox"` to your `Podfile`

**Carthage:**

Add the line `github "johnsundell/unbox"` to your `Cartfile`

**Manual:**

Clone the repo and drag the file `Unbox.swift` into your Xcode project.

**Swift Package Manager:**

Add the line `.Package(url: "https://github.com/johnsundell/unbox.git", from: "3.0.0")` to your `Package.swift`

### Platform support

Unbox supports all current Apple platforms with the following minimum versions:

- iOS 8
- OS X 10.11
- watchOS 2
- tvOS 9

### Debugging tips

In case your unboxing code isn’t working like you expect it to, here are some tips on how to debug it:

**Compile time error: `Ambiguous reference to member 'unbox'`**

Swift cannot find the appropriate overload of the `unbox` method to call. Make sure you have conformed to any required protocol (such as `Unboxable`, `UnboxableEnum`, etc). Note that you can only conform to one Unbox protocol for each type (that is, a type cannot be both an `UnboxableEnum` and `UnboxableByTransform`). Also remember that you can only reference concrete types (not `Protocol` types) in order for Swift to be able to select what overload to use.

**`unbox()` throws**

Use the `do, try, catch` pattern to catch and handle the error:

```swift
do {
    let model: Model = try unbox(data: data)
} catch {
    print("An error occurred: \(error)")
}
```

If you need any help in resolving any problems that you might encounter while using Unbox, feel free to open an Issue.

### Community Extensions

- [UnboxedAlamofire](https://github.com/serejahh/UnboxedAlamofire) - the easiest way to use Unbox with Alamofire

### Hope you enjoy unboxing your JSON!

For more updates on Unbox, and my other open source projects, follow me on Twitter: [@johnsundell](http://www.twitter.com/johnsundell)

Also make sure to check out [Wrap](http://github.com/johnsundell/wrap) that let’s you easily **encode** JSON.
