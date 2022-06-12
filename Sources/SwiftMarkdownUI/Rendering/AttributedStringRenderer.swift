//
//  AttributedStringRenderer.swift
//  
//
//  Created by 張智堯 on 2022/5/15.
//

import Foundation
import Markdown
import SwiftUI

struct AttributedStringRenderer: MarkupWalker {
    struct State {
        var font: MarkdownStyle.Font
        var foregroundColor: SwiftUI.Color
        var paragraphSpacing: CGFloat
        var headIndent: CGFloat = 0
        var tailIndent: CGFloat = 0
        var tabStops: [NSTextTab] = []
        var paragraphEdits: [ParagraphEdit] = []
        //var strikethroughStyle: NSUnderlineStyle = .init(rawValue: 0x00)

        mutating func setListMarker(_ listMarker: ListMarker?) {
            // Replace any previous list marker by two indents
            paragraphEdits = paragraphEdits.map { edit in
                guard case .listMarker = edit else { return edit }
                return .firstLineIndent(2)
            }
            guard let listMarker = listMarker else { return }
            paragraphEdits.append(.listMarker(listMarker, font: font))
        }
        mutating func addFirstLineIndent(_ count: Int = 1) {
            paragraphEdits.append(.firstLineIndent(count))
        }
    }
    
    enum ParagraphEdit {
        case firstLineIndent(Int)
        case listMarker(ListMarker, font: MarkdownStyle.Font)
    }

    enum ListMarker {
        case disc
        case decimal(Int)
    }
    
    let result = NSMutableAttributedString()
    
    private let environment: Environment
    private let state: State
    private let hasSuccessor: Bool?
    private let childCount: Int
    private var offset = 0
    
    init(_ environment: Environment, hasSuccessor: Bool, state: State) {
        self.environment = environment
        self.hasSuccessor = hasSuccessor
        self.state = state
        self.childCount = -1
    }
    init(_ environment: Environment, childCount: Int, state: State) {
        self.environment = environment
        self.childCount = childCount
        self.state = state
        self.hasSuccessor = nil
    }
    init(_ environment: Environment, state: State) {
        self.environment = environment
        self.state = state
        self.hasSuccessor = nil
        self.childCount = -1
    }
}

// MARK: Visitor
extension AttributedStringRenderer {
    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        result.append(
            renderBlockQuote(
                blockQuote,
                hasSuccessor: hasSuccessor ?? (offset < childCount - 1),
                state: state
            )
        )
        if hasSuccessor == nil { offset += 1 }
    }
    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        result.append(
            renderCodeBlock(
                codeBlock,
                hasSuccessor: hasSuccessor ?? (offset < childCount - 1),
                state: state
            )
        )
        if hasSuccessor == nil { offset += 1 }
    }
    mutating func visitHeading(_ heading: Heading) {
        result.append(
            renderHeading(
                heading,
                hasSuccessor: hasSuccessor ?? (offset < childCount - 1),
                state: state
            )
        )
        if hasSuccessor == nil { offset += 1 }
    }
    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        result.append(
            renderThematicBreak(
                hasSuccessor: hasSuccessor ?? (offset < childCount - 1),
                state: state
            )
        )
        if hasSuccessor == nil { offset += 1 }
    }
    mutating func visitHTMLBlock(_ html: HTMLBlock) {
        result.append(
            renderHTMLBlock(
                html,
                hasSuccessor: hasSuccessor ?? (offset < childCount - 1),
                state: state
            )
        )
        if hasSuccessor == nil { offset += 1 }
    }
    mutating func visitListItem(_ listItem: ListItem) {
        result.append(
            renderListItem(
                listItem,
                listMarker: .disc,
                parentParagraphSpacing: state.paragraphSpacing,
                hasSuccessor: hasSuccessor ?? (offset < childCount - 1),
                state: state
            )
        )
        if hasSuccessor == nil { offset += 1 }
    }
    mutating func visitOrderedList(_ orderedList: OrderedList) {
        result.append(
            renderOrderList(
                orderedList,
                hasSuccessor: hasSuccessor ?? (offset < childCount - 1),
                state: state
            )
        )
    }
    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        result.append(
            renderUnorderedList(
                unorderedList,
                hasSuccessor: hasSuccessor ?? (offset < childCount - 1),
                state: state
            )
        )
        if hasSuccessor == nil { offset += 1 }
    }
    mutating func visitParagraph(_ paragraph: Paragraph) {
        result.append(
            renderParagraph(
                paragraph,
                hasSuccessor: hasSuccessor ?? (offset < childCount - 1),
                state: state
            )
        )
        if hasSuccessor == nil { offset += 1 }
    }
    //mutating func visitBlockDirective(_ blockDirective: BlockDirective) {
    //    return defaultVisit(blockDirective) }
    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        result.append(renderInlineCode(inlineCode, state: state))
        offset += 1
    }
    mutating func visitEmphasis(_ emphasis: Emphasis) {
        result.append(renderEmphasis(emphasis, state: state))
        offset += 1
    }
    mutating func visitImage(_ image: Markdown.Image) {
        result.append(renderImage(image, state: state))
        offset += 1
    }
    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) {
        result.append(renderInlineHTML(inlineHTML, state: state))
        offset += 1
    }
    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        result.append(renderLineBreak(state: state))
        offset += 1
    }
    mutating func visitLink(_ link: Markdown.Link) {
        result.append(renderLink(link, state: state))
        offset += 1
    }
    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        result.append(renderSoftBreak(state: state))
        offset += 1
    }
    mutating func visitStrong(_ strong: Strong) {
        result.append(renderStrong(strong, state: state))
        offset += 1
    }
    mutating func visitText(_ text: Markdown.Text) {
        result.append(renderText(text.plainText, state: state))
        offset += 1
    }
    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        result.append(renderStrikethrough(strikethrough, state: state))
        offset += 1
    }
    mutating func visitSymbolLink(_ symbolLink: SymbolLink) {
        result.append(renderSymbolLink(symbolLink, state: state))
        offset += 1
    }
    
    /* Not Support Table yet
    mutating func visitTable(_ table: Table) {
        return defaultVisit(table) }
    mutating func visitTableHead(_ tableHead: Table.Head) {
        return defaultVisit(tableHead) }
    mutating func visitTableBody(_ tableBody: Table.Body) {
        return defaultVisit(tableBody) }
    mutating func visitTableRow(_ tableRow: Table.Row) {
        return defaultVisit(tableRow) }
    mutating func visitTableCell(_ tableCell: Table.Cell) {
        return defaultVisit(tableCell) }
    */
}

// MARK: Render block
extension AttributedStringRenderer {
    private func renderBlock(
        _ block: BlockMarkup,
        hasSuccessor: Bool,
        state: State
    ) -> NSAttributedString {
        var attributedStringRenderer = AttributedStringRenderer(
            environment,
            hasSuccessor: hasSuccessor,
            state: state
        )
        attributedStringRenderer.visit(block)
        
        return attributedStringRenderer.result
    }
    
    private func renderBlockQuote(
        _ blockQuote: BlockQuote,
        hasSuccessor: Bool,
        state: State
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        var state = state
        state.font = state.font.italic()
        state.headIndent += environment.style.measurements.headIndentStep
        state.tailIndent += environment.style.measurements.tailIndentStep
        state.tabStops.append(
          .init(textAlignment: .natural, location: state.headIndent)
        )
        state.addFirstLineIndent()
        
        for (offset, block) in blockQuote.blockChildren.enumerated() {
            result.append(
                renderBlock(block, hasSuccessor: offset < blockQuote.childCount - 1, state: state)
            )
        }
        
        if hasSuccessor {
            result.append(string: .paragraphSeparator)
        }
        
        return result
    }
    
    private func renderCodeBlock(
        _ codeBlock: CodeBlock,
        hasSuccessor: Bool,
        state: State
    ) -> NSAttributedString {
        var state = state
        state.font = state.font.scale(environment.style.measurements.codeFontScale).monospaced()
        state.headIndent += environment.style.measurements.headIndentStep
        state.tabStops.append(
          .init(textAlignment: .natural, location: state.headIndent)
        )
        state.addFirstLineIndent()
        
        var code = codeBlock.code.replacingOccurrences(of: "\n", with: String.lineSeparator)
        code.removeLast()
        
        return renderParagraph(.init([InlineCode(code)]), hasSuccessor: hasSuccessor,state: state)
    }
    
    private func renderHTMLBlock(
        _ htmlBlock: HTMLBlock,
        hasSuccessor: Bool,
        state: State
    ) -> NSAttributedString {
        var html = htmlBlock.rawHTML.replacingOccurrences(of: "\n", with: String.lineSeparator)
        html.removeLast()
        
        return renderParagraph(.init([InlineHTML(html)]), hasSuccessor: hasSuccessor,state: state)
    }
    
    private func renderUnorderedList(
        _ unorderedList: UnorderedList,
        hasSuccessor: Bool,
        state: State
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        var itemState = state
        itemState.paragraphSpacing = environment.style.measurements.paragraphSpacing
        itemState.headIndent += environment.style.measurements.headIndentStep
        itemState.tabStops.append(
              contentsOf: [
                .init(
                  textAlignment: .trailing(environment.baseWritingDirection),
                  location: itemState.headIndent - environment.style.measurements.listMarkerSpacing
                ),
                .init(textAlignment: .natural, location: itemState.headIndent),
              ]
            )
        itemState.setListMarker(nil)
        
        for (offset, item) in unorderedList.listItems.enumerated() {
            result.append(
                renderListItem(
                    item,
                    listMarker: .disc,
                    parentParagraphSpacing: state.paragraphSpacing,
                    hasSuccessor: offset < unorderedList.childCount - 1,
                    state: itemState
                )
            )
        }
        
        if hasSuccessor {
            result.append(string: .paragraphSeparator)
        }
        
        return result
    }
    
    private func renderOrderList(
        _ orderedList: OrderedList,
        hasSuccessor: Bool,
        state: State
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        let highestNumber = orderedList.childCount - 1
        let headIndentStep = max(
            environment.style.measurements.headIndentStep,
            NSAttributedString(
                string: "\(highestNumber)",
                attributes: [
                    .font : state.font.monospacedDigit().resolve(sizeCategory: environment.sizeCategory)
                ]
            ).em() + environment.style.measurements.listMarkerSpacing
        )
        var itemState = state
        itemState.paragraphSpacing = environment.style.measurements.paragraphSpacing
        itemState.headIndent += headIndentStep
        itemState.tabStops.append(
            contentsOf: [
                .init(
                    textAlignment: .trailing(environment.baseWritingDirection),
                    location: itemState.headIndent - environment.style.measurements.listMarkerSpacing
                ),
                .init(textAlignment: .natural, location: itemState.headIndent)
            ]
        )
        itemState.setListMarker(nil)
        
        for (offset, item) in orderedList.listItems.enumerated() {
            result.append(
                renderListItem(
                    item,
                    listMarker: .decimal(offset),
                    parentParagraphSpacing: state.paragraphSpacing,
                    hasSuccessor: offset < orderedList.childCount - 1,
                    state: itemState
                )
            )
        }
        
        if hasSuccessor {
            result.append(string: .paragraphSeparator)
        }
        
        return result
    }
    
    private func renderListItem(
        _ listItem: ListItem,
        listMarker: ListMarker,
        parentParagraphSpacing: CGFloat,
        hasSuccessor: Bool,
        state: State
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for (offset, block) in listItem.blockChildren.enumerated() {
            var blockState = state
            
            
            if offset == 0 {
                blockState.setListMarker(listMarker)
            } else {
                blockState.addFirstLineIndent(2)
            }
            
            if !hasSuccessor, offset == listItem.childCount - 1 {
                blockState.paragraphSpacing = max(parentParagraphSpacing, state.paragraphSpacing)
            }
            
            result.append(
                renderBlock(block, hasSuccessor: offset < listItem.childCount - 1, state: state)
            )
        }
        
        if hasSuccessor {
            result.append(string: .paragraphSeparator)
        }
        
        return result
    }
    
    private func renderHeading(
        _ heading: Heading,
        hasSuccessor: Bool,
        state: State
    ) -> NSAttributedString {
        let result = renderParagraphEdits(state: state)
        
        var inlineState = state
        inlineState.font = inlineState.font.bold().scale(
          environment.style.measurements.headingScales[heading.level - 1]
        )
        
        result.append(renderInlines(heading.inlineChildren, state: state))
        
        var paragraphState = state
        paragraphState.paragraphSpacing = environment.style.measurements.headingSpacing
        
        result.addAttribute(
            .paragraphStyle,
            value: paragraphStyle(state: paragraphState),
            range: NSRange(0..<result.length)
        )
        
        if hasSuccessor {
            result.append(string: .paragraphSeparator)
        }
        
        return result
    }
    
    private func renderThematicBreak(hasSuccessor: Bool ,state: State) -> NSAttributedString {
        let result = renderParagraphEdits(state: state)
        
        result.append(
            .init(
                string: .nbsp,
                attributes: [
                    .font: state.font.resolve(sizeCategory: environment.sizeCategory),
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: PlatformColor.separator,
                ]
            )
        )
        
        result.addAttribute(
            .paragraphStyle,
            value: paragraphStyle(state: state),
            range: NSRange(0..<result.length)
        )
        
        if hasSuccessor {
            result.append(string: .paragraphSeparator)
        }
        
        return result
    }
    
    private func renderParagraph(
        _ paragraph: Paragraph,
        hasSuccessor: Bool,
        state: State
    ) -> NSAttributedString {
        let result = renderParagraphEdits(state: state)
        result.append(renderInlines(paragraph.inlineChildren, state: state))
        result.addAttribute(
            .paragraphStyle,
            value: paragraphStyle(state: state),
            range: NSRange(0..<result.length)
        )
        
        if hasSuccessor {
            result.append(string: .paragraphSeparator)
        }
        
        return result
    }
    
    private func renderParagraphEdits(state: State) -> NSMutableAttributedString {
        let result = NSMutableAttributedString()
        
        for paragraphEdit in state.paragraphEdits {
            switch paragraphEdit {
            case .firstLineIndent(let count):
                result.append(
                    renderText(.init(repeating: "\t", count: count), state: state)
                )
            case .listMarker(let listMarker, let font):
                switch listMarker {
                case .disc:
                    var state = state
                    state.font = font
                    result.append(renderText("\t•\t", state: state))
                case .decimal(let value):
                    var state = state
                    state.font = font.monospacedDigit()
                    result.append(renderText("\t\(value).\t", state: state))
                }
            }
        }
        
        return result
    }
    
    private func paragraphStyle(state: State) -> NSParagraphStyle {
        let pointSize = state.font.resolve(sizeCategory: environment.sizeCategory).pointSize
        let result = NSMutableParagraphStyle()
        result.setParagraphStyle(.default)
        result.baseWritingDirection = environment.baseWritingDirection
        result.alignment = environment.alignment
        result.lineSpacing = environment.lineSpacing
        result.paragraphSpacing = round(pointSize * state.paragraphSpacing)
        result.headIndent = round(pointSize * state.headIndent)
        result.tailIndent = round(pointSize * state.tailIndent)
        result.tabStops = state.tabStops.map {
          NSTextTab(
            textAlignment: $0.alignment,
            location: round(pointSize * $0.location),
            options: $0.options
          )
        }
        return result
    }
}

// MARK: Render inline
extension AttributedStringRenderer {
    private func renderInlines(_ inlines: LazyMapSequence<MarkupChildren, InlineMarkup>, state: State) -> NSMutableAttributedString {
        let result = NSMutableAttributedString()
        
        for inline in inlines {
            var attributedStringRenderer = AttributedStringRenderer(environment, state: state)
            attributedStringRenderer.visit(inline)
            result.append(attributedStringRenderer.result)
        }
        
        return result
    }
    
    private func renderSoftBreak(state: State) -> NSAttributedString {
        renderText(" ", state: state)
    }
    
    private func renderLineBreak(state: State) -> NSAttributedString {
        renderText(.lineSeparator, state: state)
    }
    
    private func renderInlineCode(_ inlineCode: InlineCode, state: State) -> NSAttributedString {
        var state = state
        state.font = state.font.scale(environment.style.measurements.codeFontScale).monospaced()
        return renderText(inlineCode.code, state: state)
    }
    
    private func renderInlineHTML(_ inlineHTML: InlineHTML, state: State) -> NSAttributedString {
        renderText(inlineHTML.rawHTML, state: state)
    }
    
    private func renderEmphasis(_ emphasis: Emphasis, state: State) -> NSAttributedString {
        var state = state
        state.font = state.font.italic()
        
        return renderInlines(emphasis.inlineChildren, state: state)
    }
    
    private func renderStrong(_ strong: Strong, state: State) -> NSAttributedString {
        var state = state
        state.font = state.font.bold()
        
        return renderInlines(strong.inlineChildren, state: state)
    }
    
    private func renderStrikethrough(_ strikethrough: Strikethrough, state: State) -> NSAttributedString {
        var state = state
        //state.strikethroughStyle = .single
        
        return renderInlines(strikethrough.inlineChildren, state: state)
    }
    
    private func renderLink(_ link: Markdown.Link, state: State) -> NSAttributedString {
        let result = renderInlines(link.inlineChildren, state: state)
        
        let absoluteURL = link.destination
            .flatMap { URL(string: $0, relativeTo: environment.baseURL) }
        
        if let url = absoluteURL {
            result.addAttribute(.link, value: url, range: NSRange(0..<result.length))
        }
        
        #if os(macOS)
        if let title = link.title {
            result.addAttribute(.toolTip, value: title, range: NSRange(0..<result.length))
        }
        #endif
        
        return result
    }
    
    // TODO: Adjust
    private func renderSymbolLink(_ symbolLink: SymbolLink, state: State) -> NSAttributedString {
        let result = NSMutableAttributedString()
        result.append(renderText(symbolLink.plainText, state: state))
        
        let absoluteURL = symbolLink.destination
            .flatMap { URL(string: $0, relativeTo: environment.baseURL) }
        
        if let url = absoluteURL {
            result.addAttribute(.link, value: url, range: NSRange(0..<result.length))
        }
        
        return result
    }
    
    private func renderImage(_ image: Markdown.Image, state: State) -> NSAttributedString {
        image.source
            .flatMap { URL(string: $0, relativeTo: environment.baseURL) }
            .map {
                NSAttributedString(markdownImageURL: $0)
            } ?? NSAttributedString()
    }
    
    private func renderText(_ text: String, state: State) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .font: state.font.resolve(sizeCategory: environment.sizeCategory),
                .foregroundColor: PlatformColor(state.foregroundColor),
                //.strikethroughStyle: state.strikethroughStyle
            ]
        )
    }
}

extension String {
    fileprivate static let lineSeparator = "\u{2028}"
    fileprivate static let paragraphSeparator = "\u{2029}"
    fileprivate static let nbsp = "\u{00A0}"
}

extension NSMutableAttributedString {
    fileprivate func append(string: String) {
        self.append(
            .init(
                string: string,
                attributes: self.length > 0
                ? self.attributes(at: self.length - 1, effectiveRange: nil) : nil
            )
        )
    }
}

extension NSAttributedString {
    /// Returns the width of the string in `em` units.
    fileprivate func em() -> CGFloat {
        guard let font = attribute(.font, at: 0, effectiveRange: nil) as? PlatformFont
        else { fatalError("Font attribute not found!") }
        return size().width / font.pointSize
    }
}

extension NSTextAlignment {
    fileprivate static func trailing(_ writingDirection: NSWritingDirection) -> NSTextAlignment {
        switch writingDirection {
        case .rightToLeft:
            return .left
        default:
            return .right
        }
    }
}

// MARK: - PlatformColor

#if os(macOS)
private typealias PlatformColor = NSColor

extension NSColor {
    fileprivate static var separator: NSColor { .separatorColor }
}
#elseif os(iOS) || os(tvOS)
private typealias PlatformColor = UIColor
#endif
