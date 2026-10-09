//
//  OnboardingView.swift
//  FinPilot
//

import SwiftUI

public struct OnboardingView: View {
    @Binding public var hasCompletedOnboarding: Bool
    @State private var currentStep: Int = 0

    private struct OnboardingStep {
        let title: String
        let subtitle: String
        let icon: String
        let color: Color
    }

    private let steps: [OnboardingStep] = [
        OnboardingStep(
            title: "Meet FinPilot",
            subtitle: "Your intelligent native iOS personal finance coach with real-time financial tracking and AI insights.",
            icon: "sparkles",
            color: FPTheme.Colors.primaryAccent
        ),
        OnboardingStep(
            title: "Private & Bank-Grade Secure",
            subtitle: "Protected with on-device Face ID, Apple Keychain encryption, and isolated cloud security.",
            icon: "lock.shield.fill",
            color: FPTheme.Colors.mint
        ),
        OnboardingStep(
            title: "AI-Powered Analysis",
            subtitle: "Ask questions naturally about your spending habits, detect trends, and optimize monthly savings.",
            icon: "bubble.left.and.bubble.right.fill",
            color: FPTheme.Colors.purple
        )
    ]

    public init(hasCompletedOnboarding: Binding<Bool>) {
        self._hasCompletedOnboarding = hasCompletedOnboarding
    }

    public var body: some View {
        ZStack {
            FPTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: 32) {
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(FPTheme.Colors.subtleText)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                }

                Spacer()

                TabView(selection: $currentStep) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        stepCard(step: steps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 380)

                Spacer()

                VStack(spacing: 16) {
                    if currentStep < steps.count - 1 {
                        FPButton(title: "Continue", icon: "arrow.right") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    } else {
                        FPButton(title: "Get Started", icon: "checkmark.circle.fill") {
                            completeOnboarding()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func stepCard(step: OnboardingStep) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(step.color.opacity(0.15))
                    .frame(width: 110, height: 110)
                Image(systemName: step.icon)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(step.color)
            }
            .padding(.bottom, 12)

            Text(step.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text(step.subtitle)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(FPTheme.Colors.subtleText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
        }
    }

    private func completeOnboarding() {
        FPHaptics.medium()
        UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
        hasCompletedOnboarding = true
    }
}
