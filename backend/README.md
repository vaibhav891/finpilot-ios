# FinPilot — Backend Cloud Functions & Firestore Setup

This directory contains the production-ready Firebase backend for **FinPilot — AI Personal Finance Coach**.

## Architecture & Security Boundary

```
[iOS App (FinPilot)]
      │  (HTTPS POST with Auth Token & Structured Financial Summary)
      ▼
[Firebase Cloud Function: askAICoach]
      │  (Appends System Prompts, Validates JSON Schema)
      ▼
[OpenAI API (gpt-4o-mini / gpt-4o)]
      │  (Structured JSON Output)
      ▼
[Firebase Cloud Function: askAICoach]
      │  (Schema Verification)
      ▼
[iOS App (FinPilot)]
```

### Key Security Guardrails:
1. **Zero Client Secret Storage**: The OpenAI API key (`OPENAI_API_KEY`) is securely stored in Google Secret Manager / Firebase Cloud Functions environment variables.
2. **Context Minimization**: Only aggregated financial snapshots (monthly totals, top 5 categories, recent 8 transactions) are sent, protecting sensitive user data.
3. **Structured Response Guarantees**: Forces JSON Object output mode to eliminate hallucinations and formatting errors.

---

## Prerequisites

1. Node.js 18+ installed
2. Firebase CLI (`npm install -g firebase-tools`)
3. An active Firebase project with Blaze (Pay-as-you-go) plan enabled (required for outbound network calls to OpenAI)

---

## Local Development & Emulators

1. Navigate to the functions directory:
   ```bash
   cd backend/functions
   npm install
   ```

2. Set up environment variables:
   ```bash
   cp .env.example .env
   # Edit .env and enter your valid OpenAI API Key
   ```

3. Run the Firebase Emulator suite:
   ```bash
   npm run serve
   ```

4. The local endpoint will be available at:
   `http://127.0.0.1:5001/<your-project-id>/us-central1/askAICoach`

---

## Deployment to Production

1. Login to Firebase CLI:
   ```bash
   firebase login
   ```

2. Link your Firebase project:
   ```bash
   firebase use <your-firebase-project-id>
   ```

3. Set OpenAI API secret securely:
   ```bash
   firebase functions:secrets:set OPENAI_API_KEY
   ```

4. Deploy Firestore security rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

5. Deploy Cloud Functions:
   ```bash
   firebase deploy --only functions
   ```

6. After deployment, update `cloudFunctionBaseURL` in `FirebaseFunctionClient.swift` with your production URL:
   ```swift
   public var cloudFunctionBaseURL: String = "https://<region>-<project-id>.cloudfunctions.net"
   ```
