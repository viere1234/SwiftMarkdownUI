import Combine
import Markdown
import SwiftUI

extension Document {
    func renderAttributedString(
        environment: AttributedStringRender.Environment
    ) -> NSAttributedString {
        var attributedStringRender = AttributedStringRender(
            environment,
            state: .init(
                font: environment.style.font,
                foregroundColor: environment.style.foregroundColor,
                paragraphSpacing: environment.style.measurements.paragraphSpacing
            )
        )
        attributedStringRender.visit(self)
        return attributedStringRender.result
    }

  func renderAttributedString(
    environment: AttributedStringRender.Environment,
    imageHandlers: [String: MarkdownImageHandler]
  ) -> AnyPublisher<NSAttributedString, Never> {
      Deferred {
      Just(self.renderAttributedString(environment: environment))
    }
    .flatMap { attributedString -> AnyPublisher<NSAttributedString, Never> in
        guard attributedString.hasMarkdownImages else {
        return Just(attributedString).eraseToAnyPublisher()
      }
      return NSAttributedString.loadingMarkdownImages(
        from: attributedString,
        using: imageHandlers
      )
      .prepend(attributedString)
      .eraseToAnyPublisher()
    }
    .eraseToAnyPublisher()
  }
}
