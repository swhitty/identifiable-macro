[![Build](https://github.com/swhitty/identifiable-macro/actions/workflows/build.yml/badge.svg)](https://github.com/swhitty/identifiable-macro/actions/workflows/build.yml)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fswhitty%2Fidentifiable-macro%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/swhitty/identifiable-macro)
[![Swift 6.1](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fswhitty%2Fidentifiable-macro%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/swhitty/identifiable-macro)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)

# Introduction

**swift-identifiable-enum** is a macro that synthesises [`Identifiable`](https://developer.apple.com/documentation/swift/identifiable) conformance for enums creating unique IDs for each case.

# Installation

The macro can be installed by using Swift Package Manager.

 **Note:** requires Swift 5.10 on Xcode 15.3+. It runs on iOS 13+, tvOS 13+, macOS 10.15+, Linux and Windows.
To install using Swift Package Manager, add this to the `dependencies:` section in your Package.swift file:

```swift
.package(url: "https://github.com/swhitty/swift-identifiable-enum.git", .upToNextMajor(from: "0.2.1"))
```

# Usage

Annotate an enum declaration with `@Identifiable`:

```swift
import IdentifiableEnum

@Identifiable
enum Item {
  case foo(Foo)
  case bar(Int)
  case baz
}
```

Synthesises a nested `ID`:

```swift
extension Item: Identifable {

  enum ID: Hashable {
    case foo(Foo.ID)
    case bar(Int)
    case baz
  }

  var id: ID {
    switch self {
    case .foo(let f): .foo(f.id)
    case .bar(let b): .bar(b)
    case .baz:        .baz
    }
  }
}
```

A key path to a `Hashable` value must be provided for cases with two or more associated values:

```swift
@Identifiable
enum Item {
  @ID(\.1)
  case foo(Any, Foo)
  @ID(\.0)
  case bar(Int, Bar)
  case baz
}
```

Synthesises a nested `ID`:

```swift
extension Item: Identifable {

  enum ID: Hashable {
    case foo(Foo.ID)
    case bar(Int)
    case baz
  }

  var id: ID {
    switch self {
    case .foo(_, let f): .foo(f.id)
    case .bar(let b, _): .bar(b)
    case .baz:           .baz
    }
  }
}
```

The key path `\.self` bases the ID on case names only, ignoring associated values:

```swift
@Identifiable(id: \.self)
enum Item {
  case foo(Foo)
  case bar(Int)
  case baz
}
```

Synthesises a nested `ID`:

```swift
extension Item: Identifable {

  enum ID: Hashable {
    case foo
    case bar
    case baz
  }

  var id: ID {
    switch self {
    case .foo: .foo
    case .bar: .bar
    case .baz: .baz
    }
  }
}
```

# Options

Conformance to [CustomStringConvertible](https://developer.apple.com/documentation/swift/customstringconvertible) can also be sythensied on the `ID` via option:

```swift
@Identifiable(options: .customStringConvertible)
enum Item {
  case foo(Foo)
  case baz
}
```

Synthesises a description property:

```swift
extension Item: Identifable {
  enum ID: Hashable, CustomStringConvertible {
    case foo(Foo.ID)
    case baz

    var description: String {
      switch self {
      case .foo(let f): "foo(\(f))"
      case .baz:        "baz"
      }
    }
  }
}
```

# Credits

swift-identifiable-enum is primarily the work of [Simon Whitty](https://github.com/swhitty).

([Full list of contributors](https://github.com/swhitty/swift-identifiable-enum/graphs/contributors))
