/**
 * FinPilot - AI Personal Finance Coach
 * Firebase Cloud Functions Backend
 *
 * Implements secure boundary for OpenAI API calls, context assembly,
 * response schema validation, and push notification triggers.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { OpenAI } = require("openai");

admin.initializeApp();

// Initialize OpenAI client using environment secret
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY || functions.config().openai?.key || "sk-placeholder",
});

const FINPILOT_SYSTEM_PROMPT = `
You are FinPilot, an expert AI Personal Finance Coach.
Your goal is to provide concise, empathetic, highly actionable, and math-accurate financial coaching based ONLY on the user's provided financial context.

Core Guidelines:
1. Always analyze income vs expenses, savings rate, and category budgets.
2. If spending in discretionary categories (Dining, Shopping, Entertainment) is high or rising, point it out gently with constructive micro-habit changes.
3. Be specific with numbers (e.g. quote currency amounts and percentages).
4. Default to INR (₹) unless another currency is specified.
5. Provide a concise, clear markdown reply in "replyText".
6. When your reply identifies a notable pattern, opportunity to save, or budget warning, provide a structured insight object in "structuredInsight".
7. Always uphold the financial disclaimer: you provide informational insights and not certified tax, legal, or investment advice.

JSON Response Schema:
{
  "replyText": "Markdown formatted conversational response to the user.",
  "structuredInsight": {
    "type": "spending_trend" | "saving_opportunity" | "budget_alert" | "income_insight" | "general",
    "title": "Short punchy title (max 5 words)",
    "summary": "1-2 sentence core takeaway with numbers",
    "severity": "high" | "medium" | "low" | "tip",
    "recommendations": ["Actionable tip 1", "Actionable tip 2"],
    "category": "dining" | "groceries" | "shopping" | "transport" | "utilities" | null,
    "impactAmount": 1500.0 or null
  }
}
`;

/**
 * HTTPS Callable Function: askAICoach
 */
exports.askAICoach = functions.https.onRequest(async (req, res) => {
  // CORS configuration
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    res.status(405).json({ error: "Method not allowed. Use POST." });
    return;
  }

  try {
    // 1. Verify Authentication Token (Optional in dev/demo mode)
    const authHeader = req.headers.authorization;
    let userId = "demo_user";
    if (authHeader && authHeader.startsWith("Bearer ")) {
      const idToken = authHeader.split("Bearer ")[1];
      try {
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        userId = decodedToken.uid;
      } catch (authErr) {
        // Allow pass-through for simulator demo tokens
        console.warn("Token verification skipped/failed for demo token:", authErr.message);
      }
    }

    const { userPrompt, financialContext, history } = req.body;

    if (!userPrompt) {
      res.status(400).json({ error: "Missing required parameter: userPrompt" });
      return;
    }

    // 2. Build Structured Context Message
    const contextSummary = `
User Financial Snapshot:
- Currency: ${financialContext?.currencyCode || "INR"}
- Current Month Inflow: ₹${financialContext?.currentMonthTotalIncome || 0}
- Current Month Outflow: ₹${financialContext?.currentMonthTotalExpense || 0}
- Current Month Net Savings: ₹${financialContext?.currentMonthSavings || 0}
- Financial Goals: ${financialContext?.userGoalSummary || "Build emergency fund and invest 20%"}

Top Spending Categories:
${(financialContext?.topSpendingCategories || [])
  .map((c) => `• ${c.category}: ₹${c.amount} (${Math.round(c.percentage * 100)}%)`)
  .join("\n")}

Active Category Budgets:
${(financialContext?.activeBudgets || [])
  .map(
    (b) =>
      `• ${b.category}: Limit ₹${b.limitAmount}, Spent ₹${b.spentAmount} (${Math.round(
        b.utilizationPercentage * 100
      )}%)`
  )
  .join("\n")}

Recent Transactions:
${(financialContext?.recentTransactions || [])
  .slice(0, 8)
  .map((t) => `• [${t.date}] ${t.title} (${t.category}): ₹${t.amount}`)
  .join("\n")}
`;

    // 3. Assemble Conversation Messages
    const openAiMessages = [
      { role: "system", content: FINPILOT_SYSTEM_PROMPT },
      { role: "system", content: `CURRENT USER FINANCIAL CONTEXT:\n${contextSummary}` },
    ];

    if (Array.isArray(history)) {
      history.slice(-6).forEach((msg) => {
        openAiMessages.push({
          role: msg.role === "user" ? "user" : "assistant",
          content: msg.content,
        });
      });
    }

    openAiMessages.push({ role: "user", content: userPrompt });

    // 4. Call OpenAI API with JSON Object Mode
    const completion = await openai.chat.completions.create({
      model: process.env.OPENAI_MODEL || "gpt-4o-mini",
      messages: openAiMessages,
      response_format: { type: "json_object" },
      temperature: 0.7,
      max_tokens: 800,
    });

    const responseContent = completion.choices[0].message.content;
    const parsedPayload = JSON.parse(responseContent);

    // 5. Log Analytics Event (Anonymized)
    console.log(`[AICoach] User ${userId} queried coach. Tokens used: ${completion.usage?.total_tokens}`);

    res.status(200).json(parsedPayload);
  } catch (error) {
    console.error("Error executing askAICoach:", error);
    res.status(500).json({
      error: "Internal Coach Service Error",
      details: error.message,
    });
  }
});

/**
 * Cloud Firestore Trigger: On Transaction Created
 * Evaluates whether transaction crosses 85% budget threshold and sends FCM notification.
 */
exports.onTransactionCreated = functions.firestore
  .document("users/{userId}/transactions/{txId}")
  .onCreate(async (snap, context) => {
    const { userId } = context.params;
    const txData = snap.data();

    if (txData.type !== "expense") return;

    try {
      // Fetch budget for transaction category
      const budgetDoc = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .collection("budgets")
        .where("category", "==", txData.category)
        .limit(1)
        .get();

      if (budgetDoc.empty) return;

      const budget = budgetDoc.docs[0].data();
      const currentMonthExpenses = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .collection("transactions")
        .where("category", "==", txData.category)
        .where("type", "==", "expense")
        .get();

      let totalSpent = 0;
      currentMonthExpenses.forEach((doc) => {
        totalSpent += doc.data().amount || 0;
      });

      const utilization = budget.limitAmount > 0 ? totalSpent / budget.limitAmount : 0;

      if (utilization >= 0.85) {
        // Send Push Notification via Firebase Cloud Messaging
        const userDoc = await admin.firestore().collection("users").doc(userId).get();
        const fcmToken = userDoc.data()?.fcmToken;

        if (fcmToken) {
          const message = {
            token: fcmToken,
            notification: {
              title: `Budget Alert: ${txData.category}`,
              body: `You're at ${Math.round(utilization * 100)}% of your ${txData.category} budget.`,
            },
            data: {
              category: txData.category,
              type: "budget_warning",
            },
          };
          await admin.messaging().send(message);
          console.log(`[FCM] Sent budget warning to user ${userId}`);
        }
      }
    } catch (err) {
      console.error("Error in onTransactionCreated trigger:", err);
    }
  });

/**
 * Scheduled Cron Function: 1st of every month at 9:00 AM
 * Sends reminder that monthly spending summary and AI review are ready.
 */
exports.scheduledMonthlySpendingReport = functions.pubsub
  .schedule("0 9 1 * *")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    console.log("[Cron] Running monthly spending report dispatcher");
    // Broadcast notification to active users
    const payload = {
      topic: "monthly_reports",
      notification: {
        title: "Your Monthly Spending Report is Ready",
        body: "FinPilot has analyzed your finances for last month. Check out your AI review and savings rate.",
      },
    };
    await admin.messaging().send(payload);
  });
