import AttributedText
import Combine
import CombineSchedulers
import Markdown
import SwiftUI

public struct SwiftMarkdown: View {
    private enum Storage: Hashable {
        static func == (lhs: SwiftMarkdown.Storage, rhs: SwiftMarkdown.Storage) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
        
        case markdown(String)
        case document(Document)
        
        var document: Document {
            switch self {
            case .markdown(let string):
                return Document(parsing: string)
            case .document(let document):
                return document
            }
        }
        
        var hashValue: Int {
            self.document.debugDescription().hashValue
        }
    }

  private struct ViewState {
    var attributedString = NSAttributedString()
    var hashValue: Int?
  }

  @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection
  @Environment(\.multilineTextAlignment) private var textAlignment: TextAlignment
  @Environment(\.sizeCategory) private var sizeCategory: ContentSizeCategory
  @Environment(\.lineSpacing) private var lineSpacing: CGFloat
  @Environment(\.markdownStyle) private var style: MarkdownStyle
  @Environment(\.openMarkdownLink) private var openMarkdownLink
  @State private var viewState = ViewState()

  private var imageHandlers: [String: MarkdownImageHandler] = [
    "http": .networkImage,
    "https": .networkImage,
  ]

  private var storage: Storage
  private var baseURL: URL?
    
  public init(_ markdown: String, baseURL: URL? = nil) {
    self.storage = .markdown(markdown)
    self.baseURL = baseURL
  }
  public init(_ document: Document, baseURL: URL? = nil) {
    self.storage = .document(document)
    self.baseURL = baseURL
  }
  public init(baseURL: URL? = nil, content: [BlockMarkup]) {
    self.init(Document(content), baseURL: baseURL)
  }

  private var viewStatePublisher: AnyPublisher<ViewState, Never> {
    struct Input: Hashable {
      let storage: Storage
      let environment: AttributedStringRenderer.Environment
    }

    return Just(
      // This value helps determine if we need to render the markdown again
      Input(
        storage: self.storage,
        environment: .init(
          baseURL: self.baseURL,
          layoutDirection: self.layoutDirection,
          alignment: self.textAlignment,
          lineSpacing: self.lineSpacing,
          sizeCategory: self.sizeCategory,
          style: self.style
        )
      ).hashValue
    )
    .flatMap { hashValue -> AnyPublisher<ViewState, Never> in
      if self.viewState.hashValue == hashValue, !viewState.attributedString.hasMarkdownImages {
        return Empty().eraseToAnyPublisher()
      } else if self.viewState.hashValue == hashValue {
        return self.loadMarkdownImages(hashValue)
      } else {
        return self.renderAttributedString(hashValue)
      }
    }
    .eraseToAnyPublisher()
  }

  public var body: some View {
    AttributedText(self.viewState.attributedString, onOpenLink: openMarkdownLink?.handler)
      .onReceive(self.viewStatePublisher) { viewState in
        self.viewState = viewState
      }
  }

  private func loadMarkdownImages(_ hashValue: Int) -> AnyPublisher<ViewState, Never> {
    NSAttributedString.loadingMarkdownImages(
      from: self.viewState.attributedString,
      using: self.imageHandlers
    )
    .map { ViewState(attributedString: $0, hashValue: hashValue) }
    .receive(on: UIScheduler.shared)
    .eraseToAnyPublisher()
  }

  private func renderAttributedString(_ hashValue: Int) -> AnyPublisher<ViewState, Never> {
    self.storage.document.renderAttributedString(
      environment: .init(
        baseURL: self.baseURL,
        layoutDirection: self.layoutDirection,
        alignment: self.textAlignment,
        lineSpacing: self.lineSpacing,
        sizeCategory: self.sizeCategory,
        style: self.style
      ),
      imageHandlers: self.imageHandlers
    )
    .map { ViewState(attributedString: $0, hashValue: hashValue) }
    .receive(on: UIScheduler.shared)
    .eraseToAnyPublisher()
  }
}

extension SwiftMarkdown {
  public func setImageHandler(
    _ imageHandler: MarkdownImageHandler,
    forURLScheme urlScheme: String
  ) -> SwiftMarkdown {
    var result = self
    result.imageHandlers[urlScheme] = imageHandler

    return result
  }
}

extension View {
    public func markdownStyle(_ markdownStyle: MarkdownStyle) -> some View {
        environment(\.markdownStyle, markdownStyle)
    }
    
    public func onOpenMarkdownLink(perform action: ((URL) -> Void)? = nil) -> some View {
        environment(\.openMarkdownLink, action.map(OpenMarkdownLinkAction.init(handler:)))
    }
}

extension EnvironmentValues {
    fileprivate var markdownStyle: MarkdownStyle {
        get { self[MarkdownStyleKey.self] }
        set { self[MarkdownStyleKey.self] = newValue }
    }
    
    fileprivate var openMarkdownLink: OpenMarkdownLinkAction? {
        get { self[OpenMarkdownLinkKey.self] }
        set { self[OpenMarkdownLinkKey.self] = newValue }
    }
}

private struct MarkdownStyleKey: EnvironmentKey {
    static let defaultValue = MarkdownStyle()
}

private struct OpenMarkdownLinkAction {
    var handler: (URL) -> Void
}

private struct OpenMarkdownLinkKey: EnvironmentKey {
    static let defaultValue: OpenMarkdownLinkAction? = nil
}
