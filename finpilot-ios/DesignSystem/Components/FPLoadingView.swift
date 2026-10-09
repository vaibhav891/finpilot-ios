//
//  FPLoadingView.swift
//  FinPilot
//

import SwiftUI

public struct FPLoadingView: View {
    public var message: String = "Analyzing finances..."

    public init(message: String = "Analyzing finances...") {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
                .tint(FPTheme.Colors.primaryAccent)

            Text(message)
                .font(.subheadline)
                .foregroundColor(FPTheme.Colors.subtleText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
