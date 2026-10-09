//
//  AICoachView.swift
//  FinPilot
//

import SwiftUI

public struct AICoachView: View {
    @Bindable public var viewModel: AICoachViewModel
    @FocusState private var isInputFocused: Bool

    public init(viewModel: AICoachViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                FPTheme.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Chat Messages Scroll
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(viewModel.messages) { message in
                                    chatMessageRow(message: message)
                                        .id(message.id)
                                }

                                if viewModel.isThinking {
                                    thinkingBubble
                                        .id("thinking_indicator")
                                }

                                Color.clear.frame(height: 10).id("bottom_anchor")
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            withAnimation {
                                proxy.scrollTo("bottom_anchor", anchor: .bottom)
                            }
                        }
                        .onChange(of: viewModel.isThinking) { _, thinking in
                            if thinking {
                                withAnimation {
                                    proxy.scrollTo("thinking_indicator", anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Suggested Questions Chips
                    suggestedPromptsRow

                    // Input Bar
                    inputBar

                    // Disclaimer Footer
                    disclaimerFooter
                }
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(role: .destructive, action: viewModel.clearChat) {
                            Label("Clear Chat", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16))
                            .foregroundColor(FPTheme.Colors.primaryAccent)
                    }
                }
            }
        }
    }

    // MARK: - Subviews
    private func chatMessageRow(message: AICoachMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if message.sender == .coach {
                ZStack {
                    Circle()
                        .fill(FPTheme.Gradients.aiAccent)
                        .frame(width: 32, height: 32)
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 8) {
                Text(.init(message.text))
                    .font(.system(size: 15))
                    .lineSpacing(3)
                    .foregroundColor(message.sender == .user ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(message.sender == .user ? FPTheme.Colors.primaryAccent : FPTheme.Colors.cardBackground)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: FPTheme.CornerRadius.medium,
                            style: .continuous
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium, style: .continuous)
                            .stroke(message.sender == .user ? Color.clear : FPTheme.Colors.cardBorder, lineWidth: 1)
                    )

                if let insight = message.structuredInsight {
                    InsightCardView(insight: insight)
                        .frame(maxWidth: 320)
                }

                Text(AppDateFormatters.shortTime.string(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(FPTheme.Colors.subtleText)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: .infinity, alignment: message.sender == .user ? .trailing : .leading)

            if message.sender == .user {
                ZStack {
                    Circle()
                        .fill(FPTheme.Colors.secondaryBackground)
                        .frame(width: 32, height: 32)
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundColor(FPTheme.Colors.subtleText)
                }
            }
        }
    }

    private var thinkingBubble: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(FPTheme.Gradients.aiAccent)
                    .frame(width: 32, height: 32)
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(FPTheme.Colors.primaryAccent)
                Text("Analyzing your financial context...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(FPTheme.Colors.subtleText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(FPTheme.Colors.cardBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(FPTheme.Colors.cardBorder, lineWidth: 1)
            )

            Spacer()
        }
    }

    private var suggestedPromptsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.suggestedQuestions, id: \.self) { question in
                    Button {
                        Task {
                            await viewModel.sendMessage(question)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 10))
                            Text(question)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(FPTheme.Colors.cardBackground)
                        .foregroundColor(FPTheme.Colors.primaryAccent)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(FPTheme.Colors.primaryAccent.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask FinPilot a question...", text: $viewModel.inputText, axis: .vertical)
                .focused($isInputFocused)
                .lineLimit(1...4)
                .font(.system(size: 15))
                .padding(12)
                .background(FPTheme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium)
                        .stroke(FPTheme.Colors.cardBorder, lineWidth: 1)
                )

            Button {
                Task {
                    await viewModel.sendMessage()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : FPTheme.Colors.primaryAccent)
                        .frame(width: 44, height: 44)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isThinking)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var disclaimerFooter: some View {
        Text("FinPilot provides informational insights based on your activity and is not financial, investment, tax, or legal advice.")
            .font(.system(size: 10))
            .foregroundColor(FPTheme.Colors.subtleText)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.bottom, 6)
    }
}
