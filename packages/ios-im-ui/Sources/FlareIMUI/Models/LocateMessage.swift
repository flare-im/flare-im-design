import Foundation

/// How a tapped quote's trip ended.
public enum FlareLocateOutcome: Equatable, Sendable {
    /// The list is showing the message.
    case shown
    /// The history was read to its end (or to the budget) without finding it. This is the only answer the
    /// host says out loud, and it chooses the words: a page that failed and a message that is genuinely
    /// gone read differently, and only the host knows which happened.
    case notInHistory
    /// The reader left the conversation while the trip was running. Nothing is said.
    case cancelled
}

/// The trip a tapped quote takes when the message it names is not loaded yet: ask the list, read a page of
/// older history, ask again, and stop with one of three answers.
///
/// The rule is shared with the Vue, Flutter and Compose kits and tested against
/// `spec/locate-orchestration-vectors.json`. It lives in the kit rather than in each app because all four
/// were writing it, and writing it differently: the page budgets were 24, 20, 5 and 24, only one of them
/// waited for the list to draw the page it had just read, and only one stopped when the reader left.
public enum FlareLocate {
    /// Older pages one locate may read before it gives up.
    public static let maxPages = 24

    /// How many more times the list is asked after the history is spent. The rows of the last page read may
    /// not be drawn yet, and a list answers for the pass it last drew — on this platform there is no frame
    /// to await, so `settle` is usually a short sleep.
    public static let settleAttempts = 6

    /// - Parameters:
    ///   - showInList: Asks the list to show the message; answers whether it had it. On this kit that is
    ///     `FlareMessageListController.scrollToMessage`.
    ///   - hasOlder: Whether there is older history left to read.
    ///   - readOlder: Reads one older page; answers whether it brought anything in. A page that failed
    ///     answers false and ends the search.
    ///   - settle: Lets the list draw one pass.
    ///   - isCurrent: False once the reader has left this conversation.
    @MainActor
    public static func run(
        showInList: @MainActor () async -> Bool,
        hasOlder: @MainActor () -> Bool,
        readOlder: @MainActor () async -> Bool,
        settle: @MainActor () async -> Void,
        isCurrent: @MainActor () -> Bool
    ) async -> FlareLocateOutcome {
        var advanced = true
        var pages = 0
        while true {
            if !isCurrent() { return .cancelled }
            if await showInList() { return .shown }
            guard hasOlder(), advanced, pages < maxPages else { break }
            advanced = await readOlder()
            pages += 1
            await settle()
        }
        for _ in 0..<settleAttempts {
            if !isCurrent() { return .cancelled }
            await settle()
            if await showInList() { return .shown }
        }
        return .notInHistory
    }
}
