//
//  IdentifiableMacro.swift
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

@attached(extension, conformances: Identifiable, names: named(id), named(ID))
public macro Identifiable<ID: Hashable>(
    id: KeyPath<AssociatedValue, ID> = \.id,
    options: Options = .default
) = #externalMacro(module: "MacroPlugin", type: "IdentifiableMacro")

@attached(extension, conformances: Identifiable, names: named(id), named(ID))
public macro Identifiable<ID: Hashable>(
    id: KeyPath<(AssociatedValue, AssociatedValue, AssociatedValue, AssociatedValue), ID>,
    options: Options = .default
) = #externalMacro(module: "MacroPlugin", type: "IdentifiableMacro")

@attached(peer)
public macro ID<ID: Hashable>(_ id: KeyPath<AssociatedValue, ID>) = #externalMacro(module: "MacroPlugin", type: "IDMacro")

@attached(peer)
public macro ID<ID: Hashable>(_ id: KeyPath<(AssociatedValue, AssociatedValue, AssociatedValue, AssociatedValue), ID>) = #externalMacro(module: "MacroPlugin", type: "IDMacro")

@attached(peer)
public macro ID<Root, ID: Hashable>(_ id: KeyPath<Root, ID>, type: ID.Type) = #externalMacro(module: "MacroPlugin", type: "IDMacro")

// Provides syntax for forming key paths to any associated value
public struct AssociatedValue: Hashable {
    public var id: AnyHashable { AnyHashable(0) }
}

public struct Options: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let customStringConvertible = Options(rawValue: 1 << 0)

    public static let `default`: Options = []
}
