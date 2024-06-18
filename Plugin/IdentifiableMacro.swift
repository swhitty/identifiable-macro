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

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum IdentifiableMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {

        let id = IDDecl.make(from: node, named: .identifiable)

        guard declaration.as(EnumDeclSyntax.self) != nil else {
            throw Invalid("Can only be applied to enum")
        }

        let options = IdentifiableOptions.make(from: node)

        let accessControl = declaration.modifiers.compactMap(AccessControl.make).first ?? .internal

        let memberList = declaration.memberBlock.members

        let cases = try memberList.compactMap { member -> CaseDecl? in
            try CaseDecl.make(from: member, id: id)
        }

        var idConformance = ["Hashable"]
        var idDescription = ""
        if options.contains(.customStringConvertible) {
            idConformance.append("CustomStringConvertible")
            idDescription = #"""
            \#(accessControl.syntax)var description: String {
                        switch self {
                            \#(cases.map(\.idDescCaseSyntax).joined(separator: "\n"))
                        }
            }
            """#
        }

        let identifiableDecl = try ExtensionDeclSyntax(
            #"""
            extension \#(type.trimmed): Identifiable {
                \#(raw: accessControl.syntax)enum ID: \#(raw: idConformance.joined(separator: ", ")) {
                    \#(raw: cases.map(\.idCaseDeclSyntax).joined(separator: "\n"))
            
                    \#(raw: idDescription)
                }
                \#(raw: accessControl.syntax)var id: ID {
                    switch self {
                    \#(raw: cases.map(\.idCaseSyntax).joined(separator: "\n"))
                    }
                }
            }
            """#
        )

        return [
            identifiableDecl
        ]
    }
}

struct CaseDecl {
    var name: String
    var associatedTypes: [String]
    var id: IDDecl
}

struct IDDecl {
    var idx: Int = 0
    var path: String
    var typeName: String?
}

enum AccessControl: String {
    case `fileprivate`
    case `private`
    case `internal`
    case `package`
    case `public`
}

extension AccessControl {
    static func make(from syntax: DeclModifierSyntax) -> Self? {
        AccessControl(rawValue: syntax.name.text)
    }

    var syntax: String {
        switch self {
        case .package, .public:
            return "\(rawValue) "
        case .private, .fileprivate, .internal:
            return ""
        }
    }
}

extension CaseDecl {
    static func make(from syntax: MemberBlockItemSyntax, id: IDDecl?) throws -> Self? {
        guard let caseSyntax = syntax.decl.as(EnumCaseDeclSyntax.self) else {
            return nil
        }
        guard let el = caseSyntax.elements.first else {
            return nil
        }
        let params = el.parameterClause?.parameters ?? []
        let associatedTypes = params.compactMap {
            $0.type.as(IdentifierTypeSyntax.self)?.name.text
        }

        let idDecl = caseSyntax.attributes.compactMap(IDDecl.make).first ?? id

        guard idDecl != nil || associatedTypes.count <= 1 else {
            throw Invalid("Multiple associated values requires @ID keypath")
        }

        var idDecla = idDecl ?? .init(path: "")
        try idDecla.updateForAssociatedTypes(associatedTypes)

        return CaseDecl(
            name: el.name.text,
            associatedTypes: associatedTypes,
            id: idDecla
        )
    }

    var idCaseDeclSyntax: String {
        if let typeName = id.typeName {
            return "case \(name)(\(typeName))"
        } else {
            return "case \(name)"
        }
    }

    var idCaseSyntax: String {
        if id.typeName == nil {
            return "case .\(name): .\(name)"
        } else {
            var letPattern = Array<String>(repeating: "_", count: associatedTypes.count)
            let varID = String(name.first!)
            letPattern[id.idx] = "let \(varID)"
            let val = letPattern.joined(separator: ", ")
            return "case .\(name)(\(val)): .\(name)(\(id.makeValSyntax(varNamed: varID)))"
        }
    }

    var idDescCaseSyntax: String {
        if id.typeName == nil {
            return #"case .\#(name): "\#(name)""#
        } else {
            let varID = String(name.first!)
            return #"case .\#(name)(let \#(varID)): "\#(name)(\(\#(varID)))""#
        }
    }
}

extension IDDecl {

    func makeValSyntax(varNamed name: String) -> String {
        if path == "self" {
            return name
        } else {
            return  [name, path].joined(separator: ".")
        }
    }

    func makeDescSyntax(varNamed name: String) -> String {
        if typeName == "String" {
            return name
        } else if typeName?.isKnownStringConvertible == true {
            return #"\(String(\#(name)))"#
        } else {
            return #"\(String(describing: \#(name)))"#
        }
    }

    enum AttributeName: String {
        case identifiable = "Identifiable"
        case id = "ID"
    }

    static func make(from syntax: AttributeListSyntax.Element) -> Self? {
        guard let attribute = syntax.as(AttributeSyntax.self) else { return nil }
        return make(from: attribute, named: .id)
    }

    static func make(from attribute: AttributeSyntax, named name: AttributeName) -> Self? {
        guard let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
              attributeName == name.rawValue else {
            return nil
        }

        guard let labelSyntax = attribute.arguments?.as(LabeledExprListSyntax.self),
              let keyPathSyntax = labelSyntax.first?.expression.as(KeyPathExprSyntax.self) else {
            return nil
        }

        let typeName = labelSyntax
            .first(where: { $0.label?.text == "type" })?
            .expression
            .as(MemberAccessExprSyntax.self)?
            .base?
            .as(DeclReferenceExprSyntax.self)?
            .baseName
            .text

        var keyPathComps = keyPathSyntax.components.compactMap {
            $0.component.as(KeyPathPropertyComponentSyntax.self)?.declName.baseName.text
        }.removingRedundantSelf()

        let idx = keyPathComps.first.flatMap(Int.init)

        if idx != nil {
            keyPathComps = Array(keyPathComps.dropFirst())
        }

        return IDDecl(
            idx: idx ?? 0,
            path: keyPathComps.joined(separator: "."),
            typeName: typeName
        )
    }

    mutating func updateForAssociatedTypes(_ associatedTypes: [String]) throws {
        guard (associatedTypes.isEmpty && idx == 0) || associatedTypes.indices.contains(idx) else {
            let val = associatedTypes.joined(separator: ",")
            throw Invalid("Associated type does not exist at index: \(idx) in (\(val)")
        }

        if associatedTypes.isEmpty {
            path = "self"
            typeName = nil
        } else if path == "id" || path.hasSuffix(".id") {
            typeName = "\(associatedTypes[idx]).ID"
        } else if path == "self" || path.hasSuffix(".self") {
            typeName = associatedTypes[idx]
        } else if path.isEmpty {
            if associatedTypes[idx].isKnownNotIdentifiable {
                path = "self"
                typeName = associatedTypes[idx]
            } else {
                path = "id"
                typeName = "\(associatedTypes[idx]).ID"
            }
        }
    }
}

struct IdentifiableOptions: OptionSet, Sendable {
    let rawValue: Int
    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let customStringConvertible = Self(rawValue: 1 << 0)

    static let `default`: Self = []
}

extension IdentifiableOptions {

    static func make(from attribute: AttributeSyntax) -> Self {
        guard 
            let labelSyntax = attribute.arguments?.as(LabeledExprListSyntax.self),
            let firstOption = labelSyntax
                .first(where: { $0.label?.text == "options" })?
                .expression else {
            return .default
        }

        return "\(firstOption)" == ".customStringConvertible" ? .customStringConvertible : .customStringConvertible
    }
}

private struct Invalid: Error, CustomStringConvertible {
    var description: String

    init(_ message: String) {
        self.description = message
    }
}

private extension String {
    var isKnownNotIdentifiable: Bool {
        // todo: include containers: optional, array, set
        return Self.knownHashableScalarTypes.contains(self)
    }

    var isKnownStringConvertible: Bool {
        // todo: include containers: optional, array, set
        return Self.knownStringConvertible.contains(self)
    }

    static let knownHashableScalarTypes: Set<String> = knownStringConvertible.union([
        "Date"
    ])

    static let knownStringConvertible: Set<String> = [
        "Bool",
        "UInt8",
        "UInt16",
        "UInt32",
        "UInt64",
        "UInt",
        "Int8",
        "Int16",
        "Int32",
        "Int64",
        "Int",
        "Float",
        "Double",
        "Float32",
        "Float64",
        "String",
        "StaticString"
    ]
}

private extension Array<String> {

    func removingRedundantSelf() -> Self {
        var copy = Array<String>()
        for element in self {
            if element != "self" || copy.isEmpty {
                copy.append(element)
            }
        }
        return copy
    }
}
