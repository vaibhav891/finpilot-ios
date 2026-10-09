//
//  AppRootView.swift
//  FinPilot
//

import SwiftUI
import SwiftData

public enum AppTab: Int, CaseIterable, Identifiable {
    case dashboard = 0
    case transactions = 1
    case aiCoach = 2
    case budgets = 3
    case analytics = 4

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .transactions: return "Transactions"
        case .aiCoach: return "AI Coach"
        case .budgets: return "Budgets"
        case .analytics: return "Analytics"
        }
    }

    public var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .transactions: return "list.bullet.rectangle.fill"
        case .aiCoach: return "sparkles"
        case .budgets: return "chart.bar.fill"
        case .analytics: return "chart.pie.fill"
        }
    }
}

public struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "has_completed_onboarding")
    @State private var authViewModel: AuthViewModel
    @State private var selectedTab: AppTab = .dashboard
    @State private var showingProfileSheet: Bool = false

    // ViewModels
    @State private var dashboardVM: DashboardViewModel
    @State private var transactionListVM: TransactionListViewModel
    @State private var aiCoachVM: AICoachViewModel
    @State private var budgetVM: BudgetViewModel
    @State private var analyticsVM: AnalyticsViewModel
    @State private var profileVM: ProfileViewModel

    public init() {
        let stack = SwiftDataStack.shared
        let txRepo = stack.makeTransactionRepository()
        let budgetRepo = stack.makeBudgetRepository()
        let profileRepo = stack.makeProfileRepository()
        let aiRepo = stack.makeAICoachRepository()

        _authViewModel = State(initialValue: AuthViewModel(profileRepository: profileRepo))
        _dashboardVM = State(initialValue: DashboardViewModel(
            transactionRepository: txRepo,
            budgetRepository: budgetRepo,
            profileRepository: profileRepo,
            aiCoachRepository: aiRepo
        ))
        _transactionListVM = State(initialValue: TransactionListViewModel(repository: txRepo))
        _aiCoachVM = State(initialValue: AICoachViewModel(
            aiCoachRepository: aiRepo,
            transactionRepository: txRepo,
            budgetRepository: budgetRepo,
            profileRepository: profileRepo
        ))
        _budgetVM = State(initialValue: BudgetViewModel(
            budgetRepository: budgetRepo,
            transactionRepository: txRepo
        ))
        _analyticsVM = State(initialValue: AnalyticsViewModel(transactionRepository: txRepo))
        _profileVM = State(initialValue: ProfileViewModel(
            profileRepository: profileRepo,
            context: stack.context
        ))
    }

    public var body: some View {
        ZStack {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else if !authViewModel.isAuthenticated {
                AuthView(viewModel: authViewModel)
            } else {
                mainAppContent
            }

            // Lock Overlay if Biometrics Enabled & Locked
            if BiometricAuthManager.shared.isLocked {
                AppLockView()
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                BiometricAuthManager.shared.handleAppDidEnterBackground()
            case .active:
                BiometricAuthManager.shared.handleAppWillEnterForeground()
            default:
                break
            }
        }
        .sheet(isPresented: $showingProfileSheet) {
            ProfileView(viewModel: profileVM) {
                authViewModel.signOut()
                showingProfileSheet = false
            }
        }
        .onAppear {
            // Seed realistic demo data if needed
            DemoDataSeeder.shared.seedInitialDataIfNeeded(context: modelContext)
        }
    }

    private var mainAppContent: some View {
        TabView(selection: $selectedTab) {
            // 1. Dashboard Tab
            NavigationStack {
                DashboardView(
                    viewModel: dashboardVM,
                    onNavigateToAICoach: { selectedTab = .aiCoach },
                    onNavigateToTransactions: { selectedTab = .transactions },
                    onNavigateToBudgets: { selectedTab = .budgets }
                )
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            FPHaptics.light()
                            showingProfileSheet = true
                        } label: {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 20))
                                .foregroundColor(FPTheme.Colors.primaryAccent)
                        }
                        .accessibilityLabel("Profile & Settings")
                    }
                }
            }
            .tabItem {
                Label(AppTab.dashboard.title, systemImage: AppTab.dashboard.icon)
            }
            .tag(AppTab.dashboard)

            // 2. Transactions Tab
            TransactionListView(viewModel: transactionListVM)
                .tabItem {
                    Label(AppTab.transactions.title, systemImage: AppTab.transactions.icon)
                }
                .tag(AppTab.transactions)

            // 3. AI Coach Tab
            AICoachView(viewModel: aiCoachVM)
                .tabItem {
                    Label(AppTab.aiCoach.title, systemImage: AppTab.aiCoach.icon)
                }
                .tag(AppTab.aiCoach)

            // 4. Budgets Tab
            BudgetListView(viewModel: budgetVM)
                .tabItem {
                    Label(AppTab.budgets.title, systemImage: AppTab.budgets.icon)
                }
                .tag(AppTab.budgets)

            // 5. Analytics Tab
            AnalyticsView(viewModel: analyticsVM)
                .tabItem {
                    Label(AppTab.analytics.title, systemImage: AppTab.analytics.icon)
                }
                .tag(AppTab.analytics)
        }
        .tint(FPTheme.Colors.primaryAccent)
    }
}
