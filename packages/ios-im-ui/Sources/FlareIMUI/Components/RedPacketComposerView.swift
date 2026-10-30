import SwiftUI

/// The kind of red packet a composer sends. Spec: RedPacketComposer `kind`.
///
/// `lucky` splits a total at random, `normal` sends the same amount in each share, `exclusive` goes to one
/// chosen member. The host offers the kinds the conversation allows (a direct chat only has `normal`).
public enum FlareRedPacketKind: String, Sendable, CaseIterable {
    case lucky, normal, exclusive
}

/// What the composer's fields accept (`spec/red-packet-vectors.json`). Format only: ranges, balances and limits
/// are the host's to check.
enum RedPacketInput {
    /// The currency exponent the composer works with: the host's value held to 0...12.
    static func exponent(_ value: Int) -> Int { min(max(value, 0), 12) }

    /// Digits (full-width ones folded) and one decimal point (`.`, `．` or `。`), at most `exponent` digits after
    /// it (the currency's ISO 4217 exponent; at 0 every point is dropped and the field takes whole numbers); a
    /// leading point gains a zero and leading zeros fold away.
    static func amount(_ text: String, exponent: Int = 2) -> String {
        let places = Self.exponent(exponent)
        var out = ""
        var point = false
        var decimals = 0
        for ch in text {
            if let digit = asciiDigit(ch) {
                if point {
                    guard decimals < places else { continue }
                    decimals += 1
                }
                out.append(digit)
            } else if decimalPoints.contains(ch), !point, places > 0 {
                point = true
                out += out.isEmpty ? "0." : "."
            }
        }
        // Leading zeros before another digit go: "007" is 7, "00.50" is 0.50.
        while out.count > 1, out.first == "0", let next = out.dropFirst().first, next.isNumber {
            out.removeFirst()
        }
        return out
    }

    /// Digits only (full-width ones folded), at most three after leading zeros, as a number; empty is 0.
    static func count(_ text: String) -> Int {
        var digits = ""
        for ch in text {
            guard let digit = asciiDigit(ch), digits.count < 3, !(digit == "0" && digits.isEmpty) else { continue }
            digits.append(digit)
        }
        return Int(digits) ?? 0
    }

    /// What the count field shows for `count`: nothing for 0.
    static func countText(_ count: Int) -> String { count > 0 ? String(count) : "" }

    private static let decimalPoints: Set<Character> = [".", "．", "。"]

    private static func asciiDigit(_ ch: Character) -> Character? {
        guard let scalar = ch.unicodeScalars.first, ch.unicodeScalars.count == 1 else { return nil }
        switch scalar.value {
        case 0x30...0x39: return ch
        case 0xFF10...0xFF19: return Character(UnicodeScalar(scalar.value - 0xFF10 + 0x30)!)
        default: return nil
        }
    }
}

/// The send-a-red-packet form: the kind switch, the amount, the share count (lucky and normal), the recipient
/// slot (exclusive), the greeting, the host-formatted total in large type, the error line and the red submit
/// button. Spec: RedPacketComposer (`RedPacketComposerView`).
///
/// - Values come in and changes go out through the `on…Change` callbacks; the host owns the form. The amount
///   field takes digits and `currencyExponent` decimals (the currency's ISO 4217 exponent from the plugin's limits:
///   0 for JPY, 2 by default, 3 for KWD; its placeholder has as many), the count field digits (0 while empty), as
///   `spec/red-packet-vectors.json` fixes for every kit; the filtered text is written back to the field.
///   ``flareRedPacketAmountMinor(_:exponent:)`` turns the field's text into minor units.
/// - The switch shows only when the host offers more than one kind; a `kind` outside `kinds` shows as the first.
///   The amount's label follows the kind: the total for `lucky`, each share's amount for `normal`, the amount
///   for `exclusive`. The count row is there for `lucky` and `normal`, the recipient row (the host's member
///   picker) for `exclusive`.
/// - A direct chat (`kinds` is exactly `[.normal]`) sends one share: no count row, and the label is the amount.
/// - The greeting's placeholder is the default greeting the packet carries when nothing is typed.
/// - `busy` locks every field and shows progress on the button. `locked` (a sent command whose result is still
///   being checked) makes the form read-only and the button inert without progress; VoiceOver reads the fields as
///   not enabled. The host usually explains why in a status banner above. Place it on the canvas surface: the
///   field groups are drawn on the primary background.
/// - The kind switch marks the chosen kind in `redPacketAccent`.
public struct RedPacketComposerView<Recipient: View>: View {
    private let kinds: [FlareRedPacketKind]
    private let kind: FlareRedPacketKind
    private let amount: String
    private let currencyExponent: Int
    private let count: Int
    private let greeting: String
    private let total: String
    private let error: String?
    private let busy: Bool
    private let locked: Bool
    private let submitLabel: String?
    private let onKindChange: ((FlareRedPacketKind) -> Void)?
    private let onAmountChange: ((String) -> Void)?
    private let onCountChange: ((Int) -> Void)?
    private let onGreetingChange: ((String) -> Void)?
    private let onSubmit: (() -> Void)?
    private let recipient: Recipient
    @State private var amountText: String
    @State private var countText: String
    @FocusState private var focus: Field?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    private enum Field: Hashable { case amount, count, greeting }

    public init(kinds: [FlareRedPacketKind], kind: FlareRedPacketKind, amount: String, currencyExponent: Int = 2,
                count: Int = 0, greeting: String = "", total: String, error: String? = nil, busy: Bool = false,
                locked: Bool = false, submitLabel: String? = nil,
                onKindChange: ((FlareRedPacketKind) -> Void)? = nil,
                onAmountChange: ((String) -> Void)? = nil,
                onCountChange: ((Int) -> Void)? = nil,
                onGreetingChange: ((String) -> Void)? = nil,
                onSubmit: (() -> Void)? = nil,
                @ViewBuilder recipient: () -> Recipient) {
        self.kinds = kinds; self.kind = kind; self.amount = amount
        self.currencyExponent = RedPacketInput.exponent(currencyExponent)
        self.count = count; self.greeting = greeting
        self.total = total; self.error = error; self.busy = busy; self.locked = locked; self.submitLabel = submitLabel
        self.onKindChange = onKindChange; self.onAmountChange = onAmountChange; self.onCountChange = onCountChange
        self.onGreetingChange = onGreetingChange; self.onSubmit = onSubmit; self.recipient = recipient()
        _amountText = State(initialValue: amount)
        _countText = State(initialValue: RedPacketInput.countText(count))
    }

    /// The amount field's placeholder: zero with the currency's decimals ("0", "0.00", "0.000").
    static func amountPlaceholder(_ exponent: Int) -> String {
        FlareRedPacketMoney.text(minor: "0", exponent: RedPacketInput.exponent(exponent)) ?? "0"
    }

    /// The kind the form shows: `kind`, or the first offered one when `kind` is not offered.
    static func shownKind(_ kind: FlareRedPacketKind, kinds: [FlareRedPacketKind]) -> FlareRedPacketKind {
        kinds.contains(kind) ? kind : (kinds.first ?? kind)
    }

    /// A direct chat's composer: the host offers only the normal kind, and a normal packet there has one share.
    static func isDirect(_ kinds: [FlareRedPacketKind]) -> Bool { kinds == [.normal] }

    /// Whether the share-count row is drawn: lucky and normal packets, outside a direct chat.
    static func showsCount(kind: FlareRedPacketKind, kinds: [FlareRedPacketKind]) -> Bool {
        kind != .exclusive && !isDirect(kinds)
    }

    /// The amount row's label for `kind`: the total, each share's amount, or (exclusive, direct chat) the amount.
    static func amountLabel(kind: FlareRedPacketKind, kinds: [FlareRedPacketKind], strings: FlareStrings) -> String {
        switch kind {
        case .lucky: return strings.packetFieldTotal
        case .normal: return isDirect(kinds) ? strings.packetFieldAmount : strings.packetFieldEach
        case .exclusive: return strings.packetFieldAmount
        }
    }

    static func kindLabel(_ kind: FlareRedPacketKind, strings: FlareStrings) -> String {
        switch kind {
        case .lucky: return strings.packetKindLucky
        case .normal: return strings.packetKindNormal
        case .exclusive: return strings.packetKindExclusive
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let shown = Self.shownKind(kind, kinds: kinds)
        let amountLabel = Self.amountLabel(kind: shown, kinds: kinds, strings: strings)
        VStack(spacing: FlareSizes.spacingLg) {
            if kinds.count > 1 {
                SegmentedControlView(options: kinds.map { Self.kindLabel($0, strings: strings) },
                                     selectedIndex: kinds.firstIndex(of: shown) ?? 0,
                                     onSelect: { index in
                                         guard kinds.indices.contains(index), kinds[index] != shown else { return }
                                         onKindChange?(kinds[index])
                                     },
                                     accent: colors.redPacketAccent)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(strings.packetKindPicker)
            }
            group(colors) {
                fieldRow(amountLabel, field: .amount, colors) {
                    editor(text: $amountText, placeholder: Self.amountPlaceholder(currencyExponent), label: amountLabel,
                           field: .amount, colors)
                    #if os(iOS)
                        .keyboardType(currencyExponent == 0 ? .numberPad : .decimalPad)
                    #endif
                }
                if Self.showsCount(kind: shown, kinds: kinds) {
                    divider(colors)
                    fieldRow(strings.packetFieldCount, field: .count, colors) {
                        editor(text: $countText, placeholder: strings.packetCountPlaceholder,
                               label: strings.packetFieldCount, field: .count, colors)
                        #if os(iOS)
                            .keyboardType(.numberPad)
                        #endif
                    }
                }
                if shown == .exclusive {
                    divider(colors)
                    recipientRow(colors)
                }
            }
            group(colors) {
                greetingEditor(colors)
            }
            Text(total)
                .font(.system(size: FlareSizes.componentRedPacketAmountFontSize, weight: .semibold))
                .foregroundColor(colors.textPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.top, FlareSizes.spacingLg)
            if let error, !error.isEmpty {
                Text(error)
                    .font(.system(size: FlareSizes.fontSizeMd))
                    .foregroundColor(colors.errorText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            RedPacketActionButton(label: submitLabel ?? strings.packetSubmit, loading: busy, disabled: locked,
                                  action: onSubmit)
                .padding(.top, FlareSizes.spacingSm)
        }
        .padding(FlareSizes.spacingLg)
        .frame(maxWidth: .infinity)
        .disabled(busy || locked)
        .onChange(of: amountText) { next in
            let clean = RedPacketInput.amount(next, exponent: currencyExponent)
            if clean != next { amountText = clean; return }
            if clean != amount { onAmountChange?(clean) }
        }
        .onChange(of: amount) { next in if next != amountText { amountText = next } }
        .onChange(of: countText) { next in
            let value = RedPacketInput.count(next)
            let clean = RedPacketInput.countText(value)
            if clean != next { countText = clean; return }
            if value != count { onCountChange?(value) }
        }
        .onChange(of: count) { next in
            let text = RedPacketInput.countText(next)
            if text != countText { countText = text }
        }
    }

    private func group<Content: View>(_ colors: FlareColors, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusCard).fill(colors.bgPrimary))
    }

    private func divider(_ colors: FlareColors) -> some View {
        Rectangle().fill(colors.borderSecondary).frame(height: RedPacketMetrics.hairline)
            .padding(.leading, FlareSizes.spacingLg)
    }

    /// A label on the leading side and the field trailing; a tap anywhere on the row focuses the field. The
    /// field carries the label for VoiceOver, so the drawn one is skipped.
    private func fieldRow<Control: View>(_ label: String, field: Field, _ colors: FlareColors,
                                         @ViewBuilder control: () -> Control) -> some View {
        HStack(spacing: FlareSizes.spacingMd) {
            rowLabel(label, colors).accessibilityHidden(true)
            control()
        }
        .padding(.horizontal, FlareSizes.spacingLg)
        .frame(maxWidth: .infinity, minHeight: FlareSizes.touchTarget)
        .contentShape(Rectangle())
        .onTapGesture { focus = field }
    }

    /// The host's member picker under the recipient label; the picker is its own control.
    private func recipientRow(_ colors: FlareColors) -> some View {
        HStack(spacing: FlareSizes.spacingMd) {
            rowLabel(strings.packetFieldRecipient, colors)
            recipient.frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, FlareSizes.spacingLg)
        .frame(maxWidth: .infinity, minHeight: FlareSizes.touchTarget)
    }

    private func rowLabel(_ label: String, _ colors: FlareColors) -> some View {
        Text(label)
            .font(.system(size: FlareSizes.fontSizeXl))
            .foregroundColor(colors.textPrimary)
            .fixedSize()
    }

    private func editor(text: Binding<String>, placeholder: String, label: String, field: Field,
                        _ colors: FlareColors) -> some View {
        ZStack(alignment: .trailing) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.system(size: FlareSizes.fontSizeXl))
                    .foregroundColor(colors.textTertiary)
                    .lineLimit(1)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            TextField("", text: text)
                .textFieldStyle(.plain)
                .font(.system(size: FlareSizes.fontSizeXl))
                .foregroundColor(colors.textPrimary)
                .multilineTextAlignment(.trailing)
                .focused($focus, equals: field)
                .accessibilityLabel(label)
        }
        .frame(maxWidth: .infinity)
    }

    private func greetingEditor(_ colors: FlareColors) -> some View {
        let text = Binding(get: { greeting }, set: { onGreetingChange?($0) })
        return ZStack(alignment: .leading) {
            if greeting.isEmpty {
                Text(strings.packetDefaultGreeting)
                    .font(.system(size: FlareSizes.fontSizeXl))
                    .foregroundColor(colors.textTertiary)
                    .lineLimit(1)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            TextField("", text: text, axis: .vertical)
                .lineLimit(1...3)
                .textFieldStyle(.plain)
                .font(.system(size: FlareSizes.fontSizeXl))
                .foregroundColor(colors.textPrimary)
                .focused($focus, equals: .greeting)
                .accessibilityLabel(strings.packetGreetingLabel)
                .accessibilityHint(greeting.isEmpty ? strings.packetDefaultGreeting : "")
        }
        .padding(.horizontal, FlareSizes.spacingLg)
        .padding(.vertical, FlareSizes.spacingMd)
        .frame(maxWidth: .infinity, minHeight: FlareSizes.touchTarget, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { focus = .greeting }
    }
}

public extension RedPacketComposerView where Recipient == EmptyView {
    /// A composer without a recipient picker: for hosts that never offer the exclusive kind.
    init(kinds: [FlareRedPacketKind], kind: FlareRedPacketKind, amount: String, count: Int = 0,
         greeting: String = "", total: String, error: String? = nil, busy: Bool = false,
         locked: Bool = false, submitLabel: String? = nil,
         onKindChange: ((FlareRedPacketKind) -> Void)? = nil,
         onAmountChange: ((String) -> Void)? = nil,
         onCountChange: ((Int) -> Void)? = nil,
         onGreetingChange: ((String) -> Void)? = nil,
         onSubmit: (() -> Void)? = nil) {
        self.init(kinds: kinds, kind: kind, amount: amount, count: count, greeting: greeting, total: total,
                  error: error, busy: busy, locked: locked, submitLabel: submitLabel, onKindChange: onKindChange,
                  onAmountChange: onAmountChange, onCountChange: onCountChange,
                  onGreetingChange: onGreetingChange, onSubmit: onSubmit, recipient: { EmptyView() })
    }
}
