import SwiftUI

// MARK: - PollComposer

/// Poll composer — build a multi-option poll with optional multi-select.
/// Spec: Composer/PollComposer (`PollComposerView`).
public struct PollComposerView: View {
    private let maxOptions: Int
    private let onSubmit: ((String, [String], Bool) -> Void)?
    private let onCancel: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var question = ""
    @State private var options: [String] = ["", ""]
    @State private var multiple = false

    public init(maxOptions: Int = 10,
                onSubmit: ((String, [String], Bool) -> Void)? = nil,
                onCancel: (() -> Void)? = nil) {
        self.maxOptions = maxOptions; self.onSubmit = onSubmit; self.onCancel = onCancel
    }

    private var filledOptions: [String] {
        options.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
    private var canSubmit: Bool {
        !question.trimmingCharacters(in: .whitespaces).isEmpty && filledOptions.count >= 2
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("发起投票").font(.system(size: 15, weight: .semibold)).foregroundColor(colors.textPrimary)
                Spacer(minLength: 0)
                Button { onCancel?() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                        .foregroundColor(colors.textTertiary)
                }.buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 4) {
                TextField("输入问题", text: $question)
                    .font(.system(size: 15, weight: .medium)).foregroundColor(colors.textPrimary)
                    .textFieldStyle(.plain)
                Rectangle().fill(colors.borderPrimary).frame(height: 1)
            }

            ForEach(options.indices, id: \.self) { i in
                optionRow(colors, i)
            }

            if options.count < maxOptions {
                Button { options.append("") } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus").font(.system(size: 12, weight: .semibold))
                        Text("添加选项").font(.system(size: 13, weight: .medium))
                    }.foregroundColor(colors.primary)
                }.buttonStyle(.plain)
            }

            Button { multiple.toggle() } label: {
                HStack(spacing: 8) {
                    Image(systemName: multiple ? "checkmark.square" : "square")
                        .font(.system(size: 15)).foregroundColor(multiple ? colors.primary : colors.textTertiary)
                    Text("允许多选").font(.system(size: 13)).foregroundColor(colors.textSecondary)
                    Spacer(minLength: 0)
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)

            Button {
                onSubmit?(question.trimmingCharacters(in: .whitespaces), filledOptions, multiple)
            } label: {
                Text("创建投票").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(
                            LinearGradient(colors: [colors.primary, colors.primary.opacity(0.82)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.5)
        }
        .padding(16)
        .frame(width: 320)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
    }

    private func optionRow(_ colors: FlareColors, _ i: Int) -> some View {
        HStack(spacing: 8) {
            TextField("选项 \(i + 1)", text: $options[i])
                .font(.system(size: 14)).foregroundColor(colors.textPrimary)
                .textFieldStyle(.plain)
            if options.count > 2 {
                Button { options.remove(at: i) } label: {
                    Image(systemName: "xmark").font(.system(size: 11, weight: .semibold))
                        .foregroundColor(colors.textTertiary)
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
    }
}
