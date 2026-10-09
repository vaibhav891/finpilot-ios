# FinPilot — AI Personal Finance Coach

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat&logo=swift)](https://developer.apple.com/swift/)
[![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue.svg?style=flat&logo=apple)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-purple.svg?style=flat&logo=swift)](https://developer.apple.com/xcode/swiftui/)
[![SwiftData](https://img.shields.io/badge/Persistence-SwiftData-green.svg?style=flat&logo=apple)](https://developer.apple.com/xcode/swiftdata/)
[![Security](https://img.shields.io/badge/Security-Face_ID_%2B_Keychain-success.svg?style=flat&logo=apple)](https://developer.apple.com/documentation/localauthentication)
[![Tests](https://img.shields.io/badge/Tests-10%20Passed-brightgreen.svg?style=flat)](https://developer.apple.com/documentation/testing)

> **FinPilot** is a production-grade native iOS personal finance coach built with Swift, SwiftUI, SwiftData, and an isolated Firebase Cloud Functions backend. It transforms personal expense tracking into actionable coaching with on-device intelligence, native charts, home-screen widgets, biometric authentication, and bank-grade privacy.

---

## 📱 Feature Highlights

- **Dynamic Financial Dashboard**: Net balance hero card, monthly inflow/outflow metrics, net savings rate, budget utilization gauge, daily spending trend mini-chart, top spending categories, and recent transactions.
- **AI Coach (Conversational & Structured)**: Ask natural language questions (*"Where am I spending the most?"*, *"How much did I spend on dining out?"*, *"How much can I save if I reduce dining expenses by 20%?"*). The coach injects structured financial context and returns conversational markdown along with rich embedded **AI Insight Cards**.
- **Smart Category Budgets**: Category limits with real-time utilization progress bars, threshold warning badges (`On Track` <85%, `Near Limit` 85–100%, `Over Budget` >100%), and automatic user notifications when nearing caps.
- **Deep Analytics & Charts**: Native SwiftUI `Charts` (`SectorMark` donut chart for category breakdown, `BarMark` daily spending trends, month-over-month percentage comparisons, and one-tap native **Share Sheet** summary).
- **Comprehensive Transaction Management**: Instant search, category filters, income vs expense segmentation, payment method tracking (UPI, Credit Card, Debit Card, Net Banking, Cash), and full receipt detail view.
- **WidgetKit Home Screen Widget**: Small iOS home screen widget displaying current month spending, remaining budget, and utilization progress.
- **Bank-Grade Biometric Security**: Face ID / Touch ID authentication using Apple's `LocalAuthentication` framework. Automatically locks when minimized or returning from background after inactivity.
- **Apple Keychain Credential Storage**: Sensitive session tokens and security preferences stored securely via `Security.framework` (`kSecClassGenericPassword`, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
- **Realistic Indian Seed Data (INR ₹)**: Preloaded with realistic Indian financial data (Tech Lead monthly salary, freelance income, rent, Zerodha SIP investments, Swiggy, Zomato, Nature's Basket, Zepto, Blinkit, Uber, electricity bills, and month-over-month dining deltas). One-tap reseed available anytime in Settings.
- **Offline-First Resilience**: Instant local writes using Apple's `SwiftData`. Outbox queue (`SDSyncQueueItem`) queues offline transactions and syncs automatically when network connectivity is restored (`NWPathMonitor`).

---

## 🏛 Clean Architecture & System Design

FinPilot strictly adheres to Clean Architecture and MVVM principles, separating pure domain business rules from presentation and persistence details:

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                     │
│  SwiftUI Views, ViewModels (@Observable), Design System     │
│  (Dashboard, Transactions, Budgets, Analytics, AI Coach)    │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                         Domain Layer                        │
│  Entities: Transaction, Budget, FinancialProfile, AIInsight  │
│  Use Cases: AnalyticsCalculator, AICoachUseCase             │
│  Repository Interfaces (Protocols)                          │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                          Data Layer                         │
│  SwiftData Stack (@Model: SDTransaction, SDBudget, ...)     │
│  Repositories (Offline-First + Sync Queue)                  │
│  LocalDataSource (ModelContext CRUD)                        │
│  RemoteDataSource (Cloud Firestore / REST Client)           │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                     Core & Infrastructure                   │
│  KeychainHelper, BiometricAuthManager, NotificationManager  │
│  NetworkMonitor (NWPathMonitor), CurrencyFormatter          │
└─────────────────────────────────────────────────────────────┘
```

---

## 🤖 AI Coach: Privacy & Secure Backend Boundary

### The Problem
Exposing OpenAI API keys inside client-side iOS apps creates critical security vulnerabilities and risks rate-limit abuse and quota drainage. Furthermore, uploading entire raw financial databases violates data minimization principles.

### FinPilot's Solution
1. **Isolated Cloud Function**: The iOS application never contains an OpenAI API key. All AI queries pass through a Firebase Cloud Function (`askAICoach`).
2. **Aggregated Financial Context**: FinPilot extracts a minimized, compact JSON payload containing only calculated monthly aggregates, active budget utilizations, and top category percentages.
3. **Structured Schema Validation**: The backend utilizes OpenAI's JSON mode to return a strictly typed `AICoachResponsePayload` containing `replyText` and an optional `structuredInsight` object.
4. **Offline Heuristic Fallback**: When offline or in demo mode without cloud configuration, an on-device rule-based heuristic coach generates immediate responses for common financial questions.
5. **Prominent Financial Disclaimer**: Displayed in chat and profile views:
   > *"FinPilot provides informational insights based on your activity and is not financial, investment, tax, or legal advice."*

```
[iOS App (FinPilot)]
      │  (HTTPS POST + Minimized Financial Snapshot)
      ▼
[Firebase Cloud Function: askAICoach]
      │  (Injects System Guardrails, Secret Management)
      ▼
[OpenAI API (gpt-4o-mini)]
      │  (Structured JSON Response)
      ▼
[Firebase Cloud Function: askAICoach]
      │  (Schema Verification)
      ▼
[iOS App (FinPilot)]
```

---

## 🗄 Data Models

### Domain Entities
- [`Transaction`](file:///Users/vaibhavsultania/Library/Developer/Xcode/UntitledProjects/Untitled%20Project/MyApp/Domain/Entities/Transaction.swift): `id`, `title`, `amount`, `type` (`expense`/`income`), `category`, `date`, `merchant`, `paymentMethod` (`UPI`, `Credit Card`, `Debit Card`, `Net Banking`, `Cash`), `notes`, `isSynced`.
- [`Budget`](file:///Users/vaibhavsultania/Library/Developer/Xcode/UntitledProjects/Untitled%20Project/MyApp/Domain/Entities/Budget.swift): `id`, `category`, `limitAmount`, `month`, `year`, `userId`.
- [`BudgetStatus`](file:///Users/vaibhavsultania/Library/Developer/Xcode/UntitledProjects/Untitled%20Project/MyApp/Domain/Entities/Budget.swift): `utilizationPercentage`, `remainingAmount`, `isWarning`, `isOverBudget`, `healthState`.
- [`FinancialProfile`](file:///Users/vaibhavsultania/Library/Developer/Xcode/UntitledProjects/Untitled%20Project/MyApp/Domain/Entities/FinancialProfile.swift): `userId`, `displayName`, `email`, `currencyCode`, `monthlyIncomeTarget`, `monthlySavingsTarget`, `isBiometricEnabled`, `isPushNotificationsEnabled`.
- [`AIInsight`](file:///Users/vaibhavsultania/Library/Developer/Xcode/UntitledProjects/Untitled%20Project/MyApp/Domain/Entities/AIInsight.swift): `id`, `type`, `title`, `summary`, `severity` (`high`, `medium`, `low`, `tip`), `recommendations`, `category`, `impactAmount`.

### SwiftData Models (`@Model`)
- `SDTransaction`
- `SDBudget`
- `SDFinancialProfile`
- `SDAIInsight`
- `SDSyncQueueItem`

---

## 🧪 Unit Testing Suite

The project includes unit tests written in Apple's modern **Swift Testing** framework (`@Test`, `#expect(...)`):

| Test Case | Description | Status |
| :--- | :--- | :--- |
| `currencyFormattingINR` | Verifies Indian number system grouping (`1,50,000`), signs (`+₹`, `-₹`) | **PASSED** |
| `compactCurrencyFormatting` | Verifies Lakhs (`₹2.5 L`), Crores (`₹1.50 Cr`), Thousands (`₹5.0 k`) | **PASSED** |
| `dateExtensionCalculations` | Verifies `startOfMonth`, `previousMonthStart`, and month boundaries | **PASSED** |
| `analyticsMonthlySummary` | Verifies inflow, outflow, net savings, and savings rate math | **PASSED** |
| `analyticsCategoryBreakdown` | Verifies category sorting and percentage calculation | **PASSED** |
| `analyticsMonthOverMonthComparison` | Verifies MoM difference, percentage change, and increase flag | **PASSED** |
| `budgetStatusCalculations` | Verifies On Track (<85%), Warning (85–100%), and Over Budget (>100%) | **PASSED** |
| `aiCoachFinancialContextAssembly` | Verifies extraction of compact financial context DTO | **PASSED** |
| `aiCoachHeuristicDiningResponse` | Verifies dining spending query matching and insight extraction | **PASSED** |
| `aiCoachHeuristic20PercentReduction`| Verifies 20% savings calculation and annual extrapolation | **PASSED** |

---

## 🚀 Getting Started

### Requirements
- macOS Sonoma or later
- Xcode 16.0+
- iOS 17.0+ Simulator or Device

### Running the App
1. Open `Untitled Project.xcodeproj` in Xcode:
   ```bash
   open "Untitled Project.xcodeproj"
   ```
2. Select the `MyApp` scheme and an iOS Simulator (e.g. `iPhone 16 Pro` or `iPhone 18 Pro`).
3. Press **Cmd + R** to run.
4. On first launch, tap **"Explore with Demo Portfolio"** to instantly explore realistic preloaded Indian financial records (INR ₹), interactive charts, category budgets, and AI insights.

### Running Unit Tests
1. In Xcode, select the `MyApp` scheme.
2. Press **Cmd + U** to run all unit tests in `MyAppTests`.

---

## ☁️ Backend Deployment (Firebase)

See [`backend/README.md`](file:///Users/vaibhavsultania/Library/Developer/Xcode/UntitledProjects/Untitled%20Project/backend/README.md) for complete instructions:
```bash
cd backend/functions
npm install
firebase login
firebase use <your-project-id>
firebase functions:secrets:set OPENAI_API_KEY
firebase deploy --only functions,firestore:rules
```

---

## ⚖️ Legal & Financial Disclaimer
FinPilot provides informational insights based on your activity and is not financial, investment, tax, or legal advice.
