//
//  ProfileView.swift
//  FinPilot
//

import SwiftUI

public struct ProfileView: View {
    @Bindable public var viewModel: ProfileViewModel
    public var onSignOut: (() -> Void)?

    private let currencyOptions = ["INR", "USD", "EUR", "GBP"]

    public init(viewModel: ProfileViewModel, onSignOut: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onSignOut = onSignOut
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                FPTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // User Profile Header
                        userHeaderCard

                        // Financial Goals Section
                        financialGoalsCard

                        // Security & Privacy Section
                        securityCard

                        // Notifications Section
                        notificationsCard

                        // Developer & Data Tools Section
                        dataManagementCard

                        // About & Legal Disclaimer
                        aboutSection

                        // Sign Out Button
                        signOutButton

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Profile & Settings")
            .task {
                await viewModel.loadProfile()
            }
            .alert("Reseed Demo Data?", isPresented: $viewModel.showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reseed Data", role: .destructive) {
                    viewModel.reseedDemoData()
                }
            } message: {
                Text("This will replace current local records with realistic Indian financial data (INR ₹) including salary, rent, Zomato, Zerodha SIP investments, and budgets.")
            }
        }
    }

    // MARK: - Subviews
    private var userHeaderCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(FPTheme.Gradients.primaryHero)
                    .frame(width: 60, height: 60)
                Text(String(viewModel.profile.displayName.prefix(1)))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.profile.displayName)
                    .font(.system(size: 18, weight: .bold))
                Text(viewModel.profile.email)
                    .font(.subheadline)
                    .foregroundColor(FPTheme.Colors.subtleText)
                HStack(spacing: 4) {
                    Circle().fill(FPTheme.Colors.mint).frame(width: 6, height: 6)
                    Text("Standard Tier • Private Local Storage")
                        .font(.caption2)
                        .foregroundColor(FPTheme.Colors.subtleText)
                }
            }

            Spacer()
        }
        .fpCard()
    }

    private var financialGoalsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Financial Targets")
                .font(.headline)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                // Currency Selector
                HStack {
                    Text("Currency")
                        .font(.subheadline)
                    Spacer()
                    Picker("Currency", selection: $viewModel.selectedCurrency) {
                        ForEach(currencyOptions, id: \.self) { curr in
                            Text(curr).tag(curr)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: viewModel.selectedCurrency) { _, _ in
                        Task { await viewModel.saveSettings() }
                    }
                }

                Divider()

                // Monthly Income Target
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Monthly Income Target")
                            .font(.subheadline)
                        Text("Baseline expected earnings")
                            .font(.caption2)
                            .foregroundColor(FPTheme.Colors.subtleText)
                    }
                    Spacer()
                    TextField("150000", text: $viewModel.incomeTargetString)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .onSubmit {
                            Task { await viewModel.saveSettings() }
                        }
                }

                Divider()

                // Monthly Savings Target
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Monthly Savings Target")
                            .font(.subheadline)
                        Text("Goal for investments and deposits")
                            .font(.caption2)
                            .foregroundColor(FPTheme.Colors.subtleText)
                    }
                    Spacer()
                    TextField("45000", text: $viewModel.savingsTargetString)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .onSubmit {
                            Task { await viewModel.saveSettings() }
                        }
                }
            }
        }
        .fpCard()
    }

    private var securityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Security & Privacy")
                .font(.headline)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                Toggle(isOn: Binding(
                    get: { viewModel.isBiometricEnabled },
                    set: { val in
                        Task { await viewModel.toggleBiometrics(val) }
                    }
                )) {
                    HStack(spacing: 10) {
                        Image(systemName: BiometricAuthManager.shared.biometryType.systemIcon)
                            .foregroundColor(FPTheme.Colors.primaryAccent)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Require \(BiometricAuthManager.shared.biometryType.title)")
                                .font(.subheadline)
                            Text("Lock app immediately when minimized")
                                .font(.caption2)
                                .foregroundColor(FPTheme.Colors.subtleText)
                        }
                    }
                }

                Divider()

                HStack(spacing: 10) {
                    Image(systemName: "key.fill")
                        .foregroundColor(FPTheme.Colors.mint)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Keychain Protected")
                            .font(.subheadline)
                        Text("Auth tokens encrypted with kSecClassGenericPassword")
                            .font(.caption2)
                            .foregroundColor(FPTheme.Colors.subtleText)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(FPTheme.Colors.mint)
                }
            }
        }
        .fpCard()
    }

    private var notificationsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Notifications")
                .font(.headline)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                Toggle(isOn: Binding(
                    get: { viewModel.isPushNotificationsEnabled },
                    set: { val in
                        viewModel.isPushNotificationsEnabled = val
                        Task {
                            if val {
                                _ = await NotificationManager.shared.requestAuthorization()
                                NotificationManager.shared.scheduleMonthlyReportNotification()
                            }
                            await viewModel.saveSettings()
                        }
                    }
                )) {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(FPTheme.Colors.primaryAccent)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Budget & Monthly Alerts")
                                .font(.subheadline)
                            Text("Warn when 85% of budget is reached")
                                .font(.caption2)
                                .foregroundColor(FPTheme.Colors.subtleText)
                        }
                    }
                }
            }
        }
        .fpCard()
    }

    private var dataManagementCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Data & Development Tools")
                .font(.headline)
                .fontWeight(.bold)

            VStack(spacing: 10) {
                Button {
                    FPHaptics.light()
                    viewModel.showResetConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(FPTheme.Colors.secondaryAccent)
                        Text("Reseed Realistic Indian Demo Data")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(FPTheme.Colors.subtleText)
                    }
                    .padding(.vertical, 4)
                }

                if let status = viewModel.statusMessage {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(FPTheme.Colors.mint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
            }
        }
        .fpCard()
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About FinPilot")
                .font(.headline)
                .fontWeight(.bold)

            Text("Version 1.0.0 (Build 100)")
                .font(.caption)
                .foregroundColor(FPTheme.Colors.subtleText)

            Text("Architected for high security: FinPilot operates with SwiftData local persistence and uses isolated Firebase Cloud Functions for AI processing. No raw financial credentials or OpenAI API secrets ever reside on this device.")
                .font(.caption)
                .foregroundColor(FPTheme.Colors.subtleText)
                .lineSpacing(3)

            Text("Disclaimer: FinPilot provides informational insights based on your activity and is not financial, investment, tax, or legal advice.")
                .font(.system(size: 11))
                .foregroundColor(FPTheme.Colors.subtleText)
                .padding(.top, 4)
        }
        .fpCard()
    }

    private var signOutButton: some View {
        Button(role: .destructive) {
            FPHaptics.light()
            onSignOut?()
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(FPTheme.Colors.coral)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(FPTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium)
                    .stroke(FPTheme.Colors.coral.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
