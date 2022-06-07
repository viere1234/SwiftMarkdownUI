//
//  AttributedStringRenderer.swift
//  
//
//  Created by 張智堯 on 2022/5/15.
//

import Foundation
import Markdown
import SwiftUI

struct AttributedStringRender: MarkupWalker {
    let environment: Environment
    var state: State
    var result: AttributedString = AttributedString()
    
    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        result.append(renderBlockQuote(blockQuote, state: state)) }
    mutating func visitCodeBlock(_ codeBlock: CodeBlock) { //TODO: renderCodeBlock
        return defaultVisit(codeBlock) }
    mutating func visitCustomBlock(_ customBlock: CustomBlock) {
        return defaultVisit(customBlock) }
    mutating func visitDocument(_ document: Document) {
        return defaultVisit(document) }
    mutating func visitHeading(_ heading: Heading) {
        return defaultVisit(heading) }
    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        return defaultVisit(thematicBreak) }
    mutating func visitHTMLBlock(_ html: HTMLBlock) {
        return defaultVisit(html) }
    mutating func visitListItem(_ listItem: ListItem) {
        return defaultVisit(listItem) }
    mutating func visitOrderedList(_ orderedList: OrderedList) {
        return defaultVisit(orderedList) }
    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        return defaultVisit(unorderedList) }
    mutating func visitParagraph(_ paragraph: Paragraph) {
        return defaultVisit(paragraph) }
    mutating func visitBlockDirective(_ blockDirective: BlockDirective) {
        return defaultVisit(blockDirective) }
    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        return defaultVisit(inlineCode) }
    mutating func visitCustomInline(_ customInline: CustomInline) {
        return defaultVisit(customInline) }
    mutating func visitEmphasis(_ emphasis: Emphasis) {
        return defaultVisit(emphasis) }
    mutating func visitImage(_ image: Markdown.Image) {
        return defaultVisit(image) }
    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) {
        return defaultVisit(inlineHTML) }
    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        return defaultVisit(lineBreak) }
    mutating func visitLink(_ link: Markdown.Link) {
        return defaultVisit(link) }
    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        return defaultVisit(softBreak) }
    mutating func visitStrong(_ strong: Strong) {
        return defaultVisit(strong) }
    mutating func visitText(_ text: Markdown.Text) {
        return defaultVisit(text) }
    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        return defaultVisit(strikethrough) }
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
    mutating func visitSymbolLink(_ symbolLink: SymbolLink) {
        return defaultVisit(symbolLink)}
}

extension AttributedStringRender {
    private func renderBlockQuote(_ blockQuote: BlockQuote, state: State) -> AttributedString {
        var result = AttributedString()
        var state = state
        state.font = state.font.italic()
        state.headIndent += environment.style.measurements.headIndentStep
        state.tailIndent += environment.style.measurements.tailIndentStep
        state.tabStops.append(
          .init(textAlignment: .natural, location: state.headIndent)
        )
        state.addFirstLineIndent()
        
        for markup in blockQuote.children {
            var attributedStringRender = AttributedStringRender(
                environment: environment,
                state: state
            )
            attributedStringRender.visit(markup)
            result.append(attributedStringRender.result)
        }
        
        result.append(string: .paragraphSeparator)
        
        return result
    }
    
    private func renderCodeBlock(_ codeBlock: CodeBlock, state: State) -> AttributedString {
        var state = state
        state.font = state.font.scale(environment.style.measurements.codeFontScale).monospaced()
        state.headIndent += environment.style.measurements.headIndentStep
        state.tabStops.append(
          .init(textAlignment: .natural, location: state.headIndent)
        )
        state.addFirstLineIndent()
        
        var code = codeBlock.code.replacingOccurrences(of: "\n", with: String.lineSeparator)
        code.removeLast()
        
        return renderParagraph(.init(InlineMarkup(codeBlock)), state: state)
    }
    
    private func renderInlines(_ inlines: [InlineMarkup], state: State) -> AttributedString {
        var result = AttributedString()
        
        for inline in inlines {
            var attributedStringRender = AttributedStringRender(
                environment: environment,
                state: state
            )
            attributedStringRender.visit(inline)
            result.append(attributedStringRender.result)
        }
        
        return result
    }
    
    private func renderParagraph(_ paragraph: Paragraph, state: State) -> AttributedString{
        var result = renderParagraphEdits(state: state)
        result.append(renderInlines(Array(paragraph.inlineChildren), state: state))
        
        result.setAttributes(AttributeContainer([.paragraphStyle : paragraphStyle(state: state)]))
        
        return result
    }
    
    private func renderParagraphEdits(state: State) -> AttributedString {
        var result = AttributedString()
        
        for paragraphEdit in state.paragraphEdits {
            switch paragraphEdit {
            case .firstLineIndent(let count):
                result.append(renderText(String(repeating: "\t", count: count), state: state))
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
    
    private func renderText(_ text: String, state: State) -> AttributedString {
        AttributedString(text, attributes: AttributeContainer([
            .font: state.font,
            .foregroundColor: state.foregroundColor
        ]))
    }
    
    private func paragraphStyle(state: State) -> NSParagraphStyle {
        let pointSize = UIFont.preferredFont(forTextStyle: .body).pointSize
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

extension AttributedStringRender {
    struct Environment: Hashable {
        let baseURL: URL?
        let baseWritingDirection: NSWritingDirection
        let alignment: NSTextAlignment
        let lineSpacing: CGFloat
        let sizeCategory: ContentSizeCategory
        let style: MarkdownStyle
        
        init(
            baseURL: URL?,
            layoutDirection: LayoutDirection,
            alignment: TextAlignment,
            lineSpacing: CGFloat,
            sizeCategory: ContentSizeCategory,
            style: MarkdownStyle
        ) {
            self.baseURL = baseURL
            self.baseWritingDirection = .init(layoutDirection)
            self.alignment = .init(layoutDirection, alignment)
            self.lineSpacing = lineSpacing
            self.sizeCategory = sizeCategory
            self.style = style
        }
    }
    
    struct State {
        var font: SwiftUI.Font
        var foregroundColor: SwiftUI.Color
        var paragraphSpacing: CGFloat
        var headIndent: CGFloat = 0
        var tailIndent: CGFloat = 0
        var tabStops: [NSTextTab] = []
        var paragraphEdits: [ParagraphEdit] = []

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
        case listMarker(ListMarker, font: SwiftUI.Font)
    }

    enum ListMarker {
        case disc
        case decimal(Int)
    }
}

extension NSWritingDirection {
  fileprivate init(_ layoutDirection: LayoutDirection) {
    switch layoutDirection {
    case .leftToRight:
      self = .leftToRight
    case .rightToLeft:
      self = .rightToLeft
    @unknown default:
      self = .natural
    }
  }
}

extension NSTextAlignment {
  fileprivate init(_ layoutDirection: LayoutDirection, _ textAlignment: TextAlignment) {
    switch (layoutDirection, textAlignment) {
    case (_, .leading):
      self = .natural
    case (_, .center):
      self = .center
    case (.leftToRight, .trailing):
      self = .right
    case (.rightToLeft, .trailing):
      self = .left
    default:
      self = .natural
    }
  }
}

extension String {
    fileprivate static let lineSeparator = "\u{2028}"
    fileprivate static let paragraphSeparator = "\u{2029}"
    fileprivate static let nbsp = "\u{00A0}"
}

extension AttributedString {
    fileprivate mutating func append(string: String) {
        self.append(AttributedString(string))
    }
}