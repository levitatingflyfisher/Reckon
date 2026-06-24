# Reckon & ReckonParty — Product Requirements Document

**Version:** 0.1  
**Status:** Draft  
**Publisher:** [Foundation Name TBD] — 501(c)(3)  
**Stack:** Flutter (Android + PWA at launch, iOS later)  
**Backend:** Supabase (Postgres, Edge Functions, Realtime, Storage)  
**LLM:** Anthropic Claude API (server-side via Edge Functions) + Phi-3 Mini on-device via MediaPipe  
**State Management:** Riverpod with @riverpod code generation  

---

## 1. Vision

Reckon is a personal decision journal that makes you a better decision-maker — not by telling you what to decide, but by showing you what you already think, more clearly than you could see it alone.

ReckonParty is the group coordination mode inside the same app: fast, viral, fun preference aggregation for groups who need to converge without politics.

The product thesis: most people have never seen a graph of their own decision quality over time. They have vague feelings — "I'm bad at career moves" or "my gut is usually right" — but zero data. Reckon builds that mirror. It gets more accurate the longer you use it.

**The killer feature is not any single technique. It is your own track record confronting you.**

---

## 2. Product Philosophy

- The app is a protocol enforcer and a longitudinal record keeper, not an AI oracle
- It never tells you what to decide
- It shows you what you already think, aggregated across time
- Non-experts get 90% of utility without knowing any technique names
- Depth is always one tap deeper, never in your face
- No streaks, no badges, no social feed of other people's decisions
- No ads. Ever. The foundation's integrity depends on it
- Privacy is a genuine value, not a marketing claim — minimum identity for minimum necessary function

---

## 3. The Two Modes

### 3.1 Reckon (Type A — Personal Decision Journal)

For consequential, slow, personal decisions with a 1-week to multi-year regret horizon. Career moves, family decisions, major purchases, health choices, where to live. The full inner crowdsource protocol: time-series re-polling, blinded priors, outside view, community forecasting, calibration history.

### 3.2 ReckonParty (Type B — Group Coordination)

For preference aggregation among a group who needs to converge without politics. Where to eat, what to watch, what to read, travel destination. Fast, viral, shareable link. Approval voting or ranked choice. No rationales, no time-series, no calibration. Resolution in minutes.

**One app, two modes. Same account (or no account). Complementary brand personalities.**

ReckonParty is the top-of-funnel acquisition mechanism for Reckon. Someone receives a restaurant poll link, uses it without an account, thinks "this is clean" — that is the Reckon onramp.

---

## 4. Auth Model — Three Tiers

Presented as a genuine values choice at onboarding. No "recommended" nudge toward the data-collection-friendly option.

### Ghost
Mullvad-inspired. Random account token generated locally, written to device secure storage. No email, no name, no password. No cross-device sync. Local notifications only (no push). Community participation disabled — no persistent identity to attach contributions to. Private mode LLM only (on-device Phi-3 Mini). If device is lost, account is lost.

*Served threat model: maximum privacy. A data breach or subpoena reveals nothing because nothing is stored.*

### Token
Account token plus optional recovery email stored hashed and encrypted server-side — never in plaintext, never used for marketing, never visible to community participants. Push notifications via anonymous push token. Community participation enabled under a chosen pseudonym ("very stressed senior at ASU"). Connected mode and BYOK LLM available.

*Served threat model: practical privacy. Account recoverable. Full features. Breach reveals hashed emails and pseudonyms only.*

### Named
Standard email/password or social login. Full features. Frictionless onboarding for users who don't need privacy guarantees. Estimated ~60% of users.

**Onboarding copy:**

> *"How do you want to use Reckon?"*
>
> **Just me, privately** — your decisions stay on your device. No account, no recovery, no community.
>
> **Private but recoverable** — anonymous account recoverable with an email. All features included.
>
> **Simple login** — standard account. Everything works.

---

## 5. LLM Architecture — Three Modes

### Connected Mode (default for Token and Named)
All LLM calls route through Supabase Edge Functions. API key is server-side only, never in the app binary. Edge functions enforce per-account rate limits. User never sees the key.

Rate limits: 5 case intakes per day, 3 outside view syntheses per day, 1 reveal observation per case. Abuse surface is structurally minimal — a bad actor has to complete real cases to generate meaningful token spend.

### Private Mode (Ghost, or user preference)
Phi-3 Mini via MediaPipe LLM Inference API, running fully on-device. Works on any Android device with 4GB+ RAM. Nothing leaves the phone. Model weights ship with the app (~2GB, downloaded on first use with user consent). Handles intake structuring, re-poll sentiment detection, basic pattern matching. Degraded but real outside view via local SQLite reference class database (no synthesis, retrieval only).

### BYOK (Bring Your Own Key)
Power-user option in settings. User pastes their Anthropic API key. Stored encrypted in device secure storage. All LLM calls route through their key, zero token cost to the foundation. Clearly labeled "for developers." Explicit documentation. No support burden promises.

**The private mode / connected mode split is the free / paid tier split. Free tier is genuinely complete. Paid tier adds the cloud intelligence layer.**

---

## 6. Data Model

```
Account
  id (token, never email)
  auth_tier: ghost | token | named
  recovery_email_hash (nullable, token tier only)
  push_token (nullable)
  created_at
  pseudonym (nullable, user-chosen)

Case
  id
  account_id
  created_at
  deadline (nullable)
  status: open | decided | resolving | closed
  question (natural language, original)
  option_a, option_b (named options)
  stated_criteria: jsonb [{label, weight}]
  stakes: low | medium | high
  regret_horizon: weeks | months | years
  category: (classified from intake, see reference class taxonomy)
  community_visible: bool
  
Poll
  id
  case_id
  created_at
  poll_number
  lean: int 0-100 (toward option_b)
  rationale: text (nullable)
  voice_memo_url (nullable)
  confidence: low | medium | high
  revealed: bool (false until user marks decided)

Resolution
  id
  case_id
  decided_at
  chosen_option: a | b
  resolution_check_date
  satisfaction_score: -2 | -1 | 0 | 1 | 2 (nullable until check-in)
  reflection: text (nullable)

OutsideView
  id
  case_id
  generated_at
  base_rate_summary: text
  reference_class_used: text
  uncertainty_level: low | medium | high
  stratification_factors: jsonb
  llm_mode: connected | private | byok
  model_version: text

CommunityForecast
  id
  case_id
  forecaster_account_id (nullable for web link participants)
  forecaster_pseudonym (nullable)
  forecaster_type: human | ai_seed
  created_at
  lean: int 0-100
  rationale: text (nullable)
  is_anonymous: bool

ReferenceClassEntry (local SQLite, ships with app)
  id
  category
  subcategory
  base_rate_description
  stratification_variables: jsonb
  sources: jsonb
  common_criteria: jsonb
  common_regret_patterns: text
  last_updated
```

Calibration score is computed fresh from closed cases on query — not a stored field. Prevents stale scores and keeps the data model honest.

---

## 7. Reference Class Database

Ships as a bundled SQLite file (~5MB). Updates as a content update, not an app update. This is the product's research moat — a carefully stratified, source-cited base rate database for personal life decisions that nobody else has built.

### Decision Categories (launch: top 20, roadmap: 100)

**Career:** job offer evaluation, career change, starting a business, leaving a business, graduate school, taking on a partner, hiring someone, firing someone

**Relationship:** marriage, having a first child, having another child (timing), ending a relationship, moving in together, long distance continuation

**Location:** relocating for work, relocating for family, buying vs renting, international move

**Financial:** major purchase, taking on significant debt, investment decision, selling an asset, salary negotiation

**Health:** elective procedure, major lifestyle change, treatment decision

**Education:** degree choice, child's school, homeschool decision

**Housing:** buy vs rent, renovate vs move

**Social/Family:** cutting contact, reconciling, major community or church commitment

**Business/Product:** architecture choice, hire vs build, pivot, launch timing

Each entry contains:
- Base rate with source citation
- Key stratification variables that materially move the distribution (e.g., for marriage: religious practice, cohabitation history, age at marriage, SES — these four explain most of the variance)
- Common criteria people weight in this decision type
- Common regret patterns ("people who chose X for reason Y tend to report Z at 5-year check-in")
- Uncertainty level (how good is the underlying data)

**Critical design principle:** The app surfaces conditional base rates, not population base rates. "50% of marriages end in divorce" is the wrong reference class for a religious, non-cohabiting couple in their late 20s. The stratification variables exist precisely to give users a prior calibrated to their actual distribution, not the population mean.

---

## 8. The Five LLM System Prompts

These are the product's intellectual core. Get these right and everything else is UI.

### 8.1 Intake Interviewer

**Persona:** Calm, curious, unhurried. A thoughtful friend who happens to think clearly.

**Goal:** Extract options, core tension, stakes, deadline, and the key pull toward each option. Build a structured case JSON object. Stop at six questions maximum — do not interrogate.

**Hard rules:**
- Never suggest what the right answer might be
- Never ask two questions in one turn
- If the user is venting, let them — then gently surface the actual decision
- Output structured JSON only when intake is complete, not during

**Output schema:** case JSON matching the Case data model above

### 8.2 Outside View Synthesizer

**Input:** Case summary + user stratification profile (SES bracket, religiosity if volunteered, relationship status, similar past decisions from their record)

**Goal:** Synthesize a conditional base rate from the reference class database entry for this case category, adjusted for the user's stratification factors.

**Hard rules:**
- Lead with the reference class used, not the number
- State the uncertainty level explicitly
- Flag when stratification data is thin
- Never pretend to precision the data doesn't warrant
- Always include: "this is a population signal — your specific situation may differ for reasons worth examining"
- Never present population base rates without stratification adjustment

**Output format:** 3-4 sentences maximum. Reference class. Conditional rate with honest range. Uncertainty flag. One sentence on key stratification factors that moved the estimate.

### 8.3 Re-Poll Sentiment Detector

**Input:** Current poll lean + rationale text

**Goal:** Detect mismatches between the lean score and the rationale sentiment. Flag if the user scored 70% toward option A but wrote only reasons supporting option B.

**Output:** Simple JSON flag: {mismatch: bool, observation: text (one sentence, shown to user as a gentle callout)}

This runs on-device (Phi-3) in private mode — does not need cloud quality.

### 8.4 Reveal Observation

**Input:** Full time series — all poll leans, all rationales, stated criteria with weights, deadline, category

**Goal:** One to two sentences observing a genuine pattern in the data. Not a verdict. Not a recommendation. A mirror.

**Patterns worth surfacing:**
- Drift direction and magnitude
- Criteria stated at intake vs. criteria mentioned in rationales (mismatch is common and revealing)
- Confidence trajectory (growing more certain or more uncertain)
- Rationale convergence (same themes recurring) vs. divergence (new considerations each poll)
- Timing patterns (did movement happen after specific polls suggesting an external event)

**Hard rules:**
- Present tense observation only: "your rationales shifted from X to Y"
- Never "you should have" or "you were right to"
- Never more than two sentences — restraint is the discipline
- If no genuine pattern exists, say so simply: "your position held steady — your initial lean appears stable"

### 8.5 Community Seed Bot

**Input:** Anonymized case summary + category + reference class data

**Goal:** Generate a calibrated outside-view lean with a one-sentence rationale, as if from a thoughtful person who has faced similar decisions and knows the base rates.

**Hard rules:**
- Clearly labeled "AI baseline" in the UI — never presented as human
- Should not simply echo the reference class number — should reason briefly from it
- Moderate confidence — not 95%, not 50% unless genuinely uncertain
- One per case maximum unless community volume is very low

---

## 9. User Flows

### 9.1 Onboarding

**Screen 1:** "Make better decisions." Subhead: "Not by thinking harder. By thinking twice." CTA: Get started.

**Screen 2:** 15-second animated demo of a toy decision — four polls, the drift revealed. No narration. This is the product thesis shown not told.

**Screen 3:** Auth tier choice (Ghost / Token / Named) with honest plain-language descriptions.

**Screen 4:** "What's a decision you're sitting with right now?" — if yes, straight into intake. If no, option to browse example cases or set a reminder.

No feature tour. No permissions wall upfront. Notification permission requested in context when first case is created.

---

### 9.2 Opening a Case (Reckon)

User taps the single large button: **"I have a decision to make."**

Conversational intake, one question at a time, generous spacing. Voice input is first-class — mic button beside text field on every turn.

Typical question sequence (LLM-driven, not scripted):
1. "What's on your mind?"
2. "When do you need to decide?"
3. "On a gut level right now, where are you leaning?"  → slider appears inline
4. "What's the main thing pulling you toward [option A]?"
5. "And the main thing making you hesitate?"
6. "What would change your mind?" (optional, LLM judges if needed)

App surfaces structured case summary for confirmation. User taps "Looks right" or edits inline. Case is open.

App says one quiet thing: *"I've scheduled [N] check-ins before your deadline. First one in [X] days. Between now and then — just live with it."*

Done. 90 seconds. Nothing more to do today.

---

### 9.3 The Re-Poll

Push notification (Token/Named) or local notification (Ghost), warm copy:

> *"[Case name] · Time to check in."*

User opens. Sees decision summary — options, stakes, core tension. **Does not see prior answers or scores.** Clean slate enforced by the data model (revealed: false).

> *"Where are you leaning today?"*

Slider. One sentence or voice memo. Optional confidence level. Done in 30 seconds.

If sentiment detector flags a mismatch (lean vs. rationale): gentle inline callout appears after save. *"Your score leaned toward [A] but your reasoning mentioned [B] themes. Worth noticing."* Dismissible. Never blocking.

---

### 9.4 The Reveal

User taps "I've decided."

Time series appears for the first time. Clean line chart — lean over time, poll dates labeled, rationale accessible on tap of each point.

Below the chart: the Reveal Observation (1-2 sentences from system prompt 8.4).

Then: *"When should I check back in to ask how you feel about this?"* — user sets resolution date.

Case status: Decided → Resolving.

---

### 9.5 Resolution Check-In

Notification on user-set date:

> *"[X] ago you decided [choice]. How do you feel about it?"*

Single spectrum, no essay required:

**Clearly right ←————————→ Clearly wrong**

Optional one sentence. Done. Case closed. Data point added to calibration record.

---

### 9.6 The Outside View (Optional)

Available at any point during an open case. User taps "How do people like me fare?"

If first use: two to three quick stratification questions (SES bracket, religiosity, relationship status). Stored to profile, never repeated.

Result: conditional base rate, reference class named, uncertainty level, 3-4 sentences. Honest. Never more confident than the data warrants.

Below result: *"Techniques at work: Reference Class Forecasting"* — tappable link to glossary entry. Never mandatory.

---

### 9.7 Community Forecasting (Token/Named, Optional)

During an open case, user taps "Get outside perspectives."

Choice: anonymous post to community, or invite specific people by link.

**If community:** Case posted anonymously with core tension visible. AI seed bot generates a baseline lean immediately (labeled clearly). Community members see the case in their feed filtered by category, record their lean + one sentence rationale. No identity attached.

**If invite link:** Shareable URL. Recipient opens in browser — no app required. Sees anonymized case, records lean on slider, adds optional sentence. After submitting sees distribution of all leans with a few anonymized rationales surfaced. Then: "This is Reckon. Want to make better decisions yourself?" Single CTA.

User sees: histogram of all leans (human + AI seed, visually distinguished), a few surfaced rationales, whether distribution is clustered or bimodal. Bimodal is important signal — it means reasonable people genuinely disagree, which is itself information worth having.

---

### 9.8 ReckonParty Flow

User taps "Group decision" or arrives via ReckonParty link.

**Create:** Name the choice, add options (2-10), share link or invite contacts. 30 seconds.

**Participate:** Recipients open link in browser or app. See options, tap to approve (all acceptable options) or rank. Instant. No account required for web participants.

**Result:** Clean ranked result screen with approval percentages. Shareable as image. Option to "turn this into a Reckon case" if the group can't converge and someone needs to make a real decision.

ReckonParty sessions expire after 7 days if not manually closed.

---

### 9.9 The Record Screen

Visible from day one. Honest about being sparse:

*"Your record is still young. It gets more useful after a few closed cases."*

After 5+ closed cases:

**Clarity Score: [0-100]**

Tappable explanation: *"Your Clarity Score reflects how accurately your confidence predicts your satisfaction with your decisions. It gets more accurate over time."*

Three insight cards below. Not a wall of charts — three. Like a sleep app's morning summary:

Examples:
- *"Your gut leans tend to be right on relationship decisions and overconfident on career decisions."*
- *"Decisions where you moved more than 20 points during the case had better outcomes than ones where you barely moved. You're a good updater."*
- *"Your stated criteria and your actual reasoning align well — you decide the way you think you decide."*

Tap any insight → underlying cases. Tap any case → full journal. Depth is always available, never mandatory.

---

## 10. Technique Glossary

First-class tab in the app. Brilliant.org-style. Eight entries at launch, expanding based on what users actually ask about.

Each entry:
- One-paragraph plain explanation (no jargon)
- Concrete example using a relatable decision
- 60-second interactive demo — toy decision walking through the technique
- "This is running in your case right now" callout when relevant

**Launch entries:**

**The Inner Crowd** — Asking yourself twice, with enough time between that the second answer is genuinely independent from the first. The surprising finding: even your second guess at yourself is meaningfully different from your first, if you wait at least a few days. Averaging two independent estimates from the same brain beats either estimate alone.

**Reference Class** — Your situation isn't as unique as it feels. There are thousands of people who've faced the same fork in the road. Their outcomes, aggregated, are your starting prior. The key skill: finding the right reference class — people similar to you, not just people in your situation superficially.

**The Pre-Mortem** — It's two years from now and this decision was a disaster. Write the first paragraph of the story. Not "what could go wrong" — that stays abstract. "What actually happened" — that forces your brain to generate specific, vivid failure modes it would otherwise suppress.

**Dialectical Bootstrapping** — Argue with yourself on purpose. Make your best estimate. Then actively generate the case against it — "what would have to be true for me to be wrong?" Then re-estimate. Average the two. The second estimate draws on different memories and reasoning than the first, making the average better than either.

**Calibration** — The difference between being right and knowing when you're right. A well-calibrated person who says "I'm 70% confident" is right about 70% of the time. Most people are overconfident — their 70% confidence predictions come true only 55% of the time. Knowing your calibration curve helps you know how much to trust yourself.

**The Reveal Effect** — Why seeing your own drift matters. When you can't see your prior answer, your re-poll is genuinely independent. When you aggregate those independent samples across time, you get a more accurate picture of your actual preference than any single session would produce. The reveal shows you the signal underneath the noise of any given day.

**Criteria vs. Reasoning** — What you say matters versus what actually moves you. People often state criteria at the start of a decision ("career growth is most important") and then reason from completely different criteria in practice ("I keep coming back to my kids' school"). The gap between stated and revealed criteria is often where the real decision lives.

**Resulting** — Judging decision quality by outcome is a mistake. A good decision can have a bad outcome (bad luck). A bad decision can have a good outcome (good luck). Separating "was this a good decision given what I knew?" from "did it turn out well?" is the core discipline of anyone who makes decisions repeatedly and wants to improve.

---

## 11. Technical Architecture

### 11.1 Flutter Project Structure

```
reckon/
  lib/
    core/
      auth/           — three-tier auth, token generation, secure storage
      models/         — Case, Poll, Resolution, OutsideView, CommunityForecast
      providers/      — Riverpod providers, @riverpod generated
      services/
        llm/          — LLM service with three backends (connected/private/byok)
        supabase/     — database, realtime, storage clients
        notifications/ — push + local notification scheduling
        reference_class/ — SQLite reference class database queries
    features/
      onboarding/     — auth tier choice, first case prompt
      intake/         — conversational case creation
      case_detail/    — active case, re-poll, outside view
      reveal/         — time series chart, reveal observation
      record/         — clarity score, insight cards, case history
      community/      — community feed, forecasting, seed bot display
      party/          — ReckonParty creation, participation, results
      glossary/       — technique entries, interactive demos
      settings/       — LLM mode, BYOK key, privacy settings
    shared/
      widgets/        — design system components
      theme/          — typography, color, spacing
  assets/
    reference_class.db  — bundled SQLite, ~5MB
    models/             — Phi-3 Mini weights, downloaded on first use
```

### 11.2 Supabase Schema

Row Level Security enforced on all tables. Account can only read/write their own cases and polls. Community forecasts are readable by all authenticated accounts (including ghost tokens). Seed bot writes are service-role only.

### 11.3 Edge Functions

```
/intake          — streams LLM intake conversation turns
/outside-view    — synthesizes conditional base rate
/reveal          — generates reveal observation
/seed-bot        — scheduled, runs on community-visible open cases
/classify        — assigns case to reference class category
```

All functions enforce rate limits per account token before calling Anthropic API.

### 11.4 Notification Strategy

Re-poll schedule computed at case creation based on deadline:
- >14 days to deadline: poll every 5-7 days
- 7-14 days: poll every 3 days
- 3-7 days: poll every 2 days
- <3 days: daily

Notification copy is warm, never pushy. Never "You haven't checked in!" Always "[Case name] · Time to check in." User can snooze 24 hours from notification. User can edit schedule from case detail.

Resolution check-in notification: single reminder on user-set date, no follow-up nag.

### 11.5 Offline Behavior

All case data, polls, and rationales stored locally in Drift (Flutter SQLite). Supabase sync happens when connectivity is available. Re-polls work fully offline — sync queues. Outside view and reveal observation require connectivity in connected mode, degrade to local reference class in offline/private mode. Community features require connectivity.

---

## 12. Design Principles

**Calm intelligence.** The app respects that decisions are serious. No confetti, no celebration animations, no urgency theater.

**Generous spacing.** Large text fields, unhurried pacing, room to think. Not a form, a conversation.

**Dark mode with warm accents** as default. Cream/deep navy as light mode option. Typography: a serif for decision text (it's a journal), a clean sans-serif for UI chrome.

**One primary action per screen.** Never more than one thing to do right now.

**Depth is always one tap deeper.** The surface is clean. The information is there.

**The app never shows you everything at once.** Home screen: active cases, pending re-polls, Clarity Score. Nothing more.

---

## 13. Monetization

**Free tier:** Private mode LLM (on-device), unlimited cases, ReckonParty unlimited, community forecasting participation, basic outside view from local reference class, technique glossary, Clarity Score (populates after closed cases).

**Supporter tier (~$4/month or $35/year):** Connected mode LLM (cloud quality intake, outside view synthesis, reveal observation), advanced calibration insights, priority in community feed, export full decision history as markdown or JSON. Framed as supporting the foundation's mission, not unlocking a premium product.

**One-time unlock ($20):** For users who philosophically dislike subscriptions. Same as supporter tier, lifetime.

**BYOK:** Free, always, for technically inclined users with their own Anthropic key.

**No ads. No selling user data. No exceptions.**

Grant funding from family-focused foundations to cover infrastructure during early growth (token costs, Supabase, notification service). The 501(c)(3) structure makes this tractable.

---

## 14. Launch Criteria

Ship when these eight things are true:

1. Conversational intake creates a well-structured case in under two minutes, voice or text, Android and PWA
2. Re-poll is genuinely blinded, under 30 seconds, notification copy is warm, schedule respects deadline
3. Reveal produces the "oh" moment on real decisions — validated with 10 real users on actual decisions before launch
4. Community forecasting layer has seed bots running on every community-visible open case
5. Web link flow works for both ReckonParty polls and community forecasting invites, no account required, conversion prompt at end
6. Stratified reference class covers top 20 decision categories with honest uncertainty levels
7. Technique glossary has 8 complete entries with interactive demos
8. Clarity Score screen exists, is honest about sparseness, explains what it will show

---

## 15. V2 Roadmap (Not in Scope for Launch)

- iOS (App Store submission after Android/PWA proven)
- Shared decisions (invite someone to participate in your case with full rationale visibility)
- Team mode (organizational decisions, multiple stakeholders)
- Advanced calibration analytics (decision type breakdown, confidence curve, drift pattern analysis)
- Expanded reference class database (top 100 categories)
- SSO across foundation app family (optional, user-initiated)
- Curated literature citations in outside view (link to actual studies, not just LLM synthesis)
- Export and data portability (your full decision history as portable markdown)

---

## 16. Open Questions

1. Foundation name — determines Play Store developer account, privacy policy, and "supporter" tier framing
2. ReckonParty — same Play Store listing with mode switch, or separate listing sharing codebase? Recommendation: same listing, mode switch, ReckonParty prominently featured in screenshots
3. Community moderation policy — what constitutes a bannable offense in community forecasting? Need a brief written policy before community layer ships
4. Resolution honesty — self-reported outcomes are gameable. Design decision: we don't try to enforce honesty. The calibration graph becomes useless to the user if they cheat it. This is the right call and should be stated explicitly in onboarding

---

## Addendum — April 2026: Supabase Removed from Architecture

Supabase has been dropped from the OpenHearth architecture. All references to Supabase in this PRD (backend, Edge Functions, Realtime, Storage, schema, LLM proxy, funding line items) reflect a v1 design that is no longer the plan.

**What replaces it:**
- **Ghost mode (v1):** Unchanged. Local Drift database, a seed-phrase-based encrypted-backup auth module. No server.
- **Connected mode / LLM proxy:** Will use a Cloudflare Worker (or equivalent edge function) to hold the API key and proxy calls. Not Supabase Edge Functions.
- **Sync / community features:** Will use a vendor-agnostic encrypted blob relay (Cloudflare R2 + Workers is the default candidate). The server stores and returns ciphertext — it never interprets the payload.
- **Realtime (ReckonParty):** Architecture TBD when community layer is built. Cloudflare Durable Objects or a purpose-built WebSocket relay, not Supabase Realtime.

**What's still valid:** The tier model (Ghost/Connected/Community), the crypto architecture, the LLM integration design, the calibration engine, and all client-side architecture. Only the server-side implementation details change.

See `OpenHearth/CLAUDE.md` (April 2026) for the current architecture.
