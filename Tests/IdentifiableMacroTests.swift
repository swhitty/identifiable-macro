//
//  IdentifiableMacroTests.swift
//  identifiable-macro
//
//  Created by Simon Whitty on 07/06/2024.
//  Copyright 2024 Simon Whitty
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/swhitty/identifiable-macro
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import IdentifiableMacro
import XCTest

final class IdentifiableMacroTests: XCTestCase {

    func testDefaults() {
        let items: [ItemA] = [
            .foo(Foo(id: 10, title: "Fish")),
            .bar(Bar(id: "chips", title: "shrimp")),
            .baz,
            .zut(.distantFuture)
        ]

        XCTAssertEqual(
            items.map(\.id),
            [.foo(10), .bar("chips"), .baz, .zut(.distantFuture)]
        )
    }

    func testIDKeyPath() {
        let items: [ItemB] = [
            .foo(Foo(id: 5), 100),
            .bar(Bar(id: "6"), 200),
            .baz,
            .fooBar(Foo(id: 7), Bar(id: "8"), 300),
            .zut(9, "Fish")
        ]

        XCTAssertEqual(
            items.map(\.id),
            [
                .foo(100),
                .bar("6"),
                .baz,
                .fooBar(300),
                .zut(4)
            ]
        )

        XCTAssertEqual(
            items.map(\.id.description),
            [
                "foo(100)",
                "bar(6)",
                "baz",
                "fooBar(300)",
                "zut(4)"
            ]
        )
    }

    func testIDWithRedundantSelf() {
        let items: [ItemC] = [
            .foo(Foo(title: "Fish")),
            .bar,
            .foobar(FooBar(bar: Bar(title: "Chips")))
        ]

        XCTAssertEqual(
            items.map(\.id),
            [
                .foo,
                .bar,
                .foobar(Bar(title: "Chips"))
            ]
        )
    }

    func testIDWithSelf() {
        let items: [ItemD] = [
            .foo(Foo(title: "Fish")),
            .bar(Bar(title: "Chips")),
            .foobar(Foo(title: "Shrimp"), Bar(title: "MusyPeas"))
        ]

        XCTAssertEqual(
            items.map(\.id),
            [
                .foo,
                .bar,
                .foobar
            ]
        )
    }
}

@Identifiable
enum ItemA {
    case foo(Foo)
    case bar(Bar)
    case baz
    case zut(Date)
}

@Identifiable(id: \.1, options: .customStringConvertible)
public enum ItemB {
    case foo(Foo, Int)

    @ID(\.0.id)
    case bar(Bar, Int)

    @ID(\.self)
    case baz

    @ID(\.2)
    case fooBar(Foo, Bar, Int)

    @ID(\(Int, String).1.count, type: Int.self)
    case zut(Int, String)
}

@Identifiable
enum ItemC {

    @ID(\.self.self.self.self)
    case foo(Foo)

    case bar

    @ID(\FooBar.bar.self.self.self, type: Bar.self)
    case foobar(FooBar)
}

@Identifiable(id: \.self)
enum ItemD {
    case foo(Foo)
    case bar(Bar)
    case foobar(Foo, Bar)
}

@Identifiable(id: \.1)
private enum ItemZ {
  case foo(Int, Foo)
  case bar(String, Int)
  @ID(\.id)
  case baz(Bar)
}

public struct Foo: Identifiable, Hashable {
    public var id: Int = -1
    public var title: String = "Foo"
}

public struct Bar: Identifiable, Hashable {
    public var id: String = "-1"
    public var title: String = "Bar"
}

public struct FooBar: Identifiable, Hashable {

    var foo: Foo = .init()
    var bar: Bar = .init()

    public var id: ID {
        .init(foo: foo.id, bar: bar.id)
    }

    public struct ID: Hashable {
        var foo: Foo.ID
        var bar: Bar.ID
    }
}
