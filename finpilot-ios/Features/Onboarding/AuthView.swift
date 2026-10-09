//
//  AuthView.swift
//  FinPilot
//

import SwiftUI

public struct AuthView: View {
    @Bindable public var viewModel: AuthViewModel

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            FPTheme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(FPTheme.Gradients.aiAccent)
                            .padding(.top, 40)

                        Text("FinPilot")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("AI Personal Finance Coach")
                            .font(.subheadline)
                            .foregroundColor(FPTheme.Colors.subtleText)
                    }

                    // Segmented Control
                    Picker("Auth Mode", selection: $viewModel.isSignUp) {
                        Text("Sign In").tag(false)
                        Text("Sign Up").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)

                    // Input Form
                    VStack(spacing: 16) {
                        if viewModel.isSignUp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Full Name")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(FPTheme.Colors.subtleText)

                                TextField("Your Name", text: $viewModel.displayName)
                                    .textFieldStyle(.plain)
                                    .padding(14)
                                    .background(FPTheme.Colors.secondaryBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium))
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Address")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(FPTheme.Colors.subtleText)

                            TextField("name@example.com", text: $viewModel.email)
                                .textFieldStyle(.plain)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(14)
                                .background(FPTheme.Colors.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(FPTheme.Colors.subtleText)

                            SecureField("••••••••", text: $viewModel.password)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(FPTheme.Colors.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium))
                        }

                        if let error = viewModel.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(error)
                            }
                            .font(.caption)
                            .foregroundColor(FPTheme.Colors.coral)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        FPButton(
                            title: viewModel.isSignUp ? "Create Account" : "Sign In",
                            icon: viewModel.isSignUp ? "person.badge.plus" : "arrow.right.circle",
                            style: .primary,
                            isLoading: viewModel.isLoading
                        ) {
                            Task {
                                await viewModel.authenticate()
                            }
                        }
                        .padding(.top, 8)

                        // Divider
                        HStack {
                            Rectangle().fill(FPTheme.Colors.cardBorder).frame(height: 1)
                            Text("OR")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(FPTheme.Colors.subtleText)
                                .padding(.horizontal, 8)
                            Rectangle().fill(FPTheme.Colors.cardBorder).frame(height: 1)
                        }
                        .padding(.vertical, 8)

                        // Demo Account Quick Sign-In
                        FPButton(
                            title: "Explore with Demo Portfolio",
                            icon: "sparkles",
                            style: .secondary,
                            isLoading: viewModel.isLoading
                        ) {
                            Task {
                                await viewModel.signInWithDemoAccount()
                            }
                        }
                    }
                    .padding(24)
                    .background(FPTheme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: FPTheme.CornerRadius.large))
                    .overlay(
                        RoundedRectangle(cornerRadius: FPTheme.CornerRadius.large)
                            .stroke(FPTheme.Colors.cardBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
        }
    }
}
