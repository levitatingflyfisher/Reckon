# Personas

Agents drive the real Reckon build as these people, per the fleet testing
rule. Each scenario gives a start state, plain steps, what success looks like,
and what to check. "Standard checks" means: text scale 1.3 at 360 dp width,
dark mode, airplane mode, and every error in plain words with a way forward.
Run on the APK unless a scenario says web. Scenarios aim at the weak spots
found by the September 2026 lens audit.

## Primary: Leila, weighing a move for the family

Leila is 42, an accountant with a partner and two teenagers, deciding whether
to take a job that means moving cities. They want to see their own thinking
clearly over several weeks, not be told what to do.

- **Goal:** open a case, re-poll honestly over time, and later see how their
  lean drifted.
- **Context:** quiet evenings at the kitchen table; text scale 1.3; not a
  technical person; wary of anything that feels like an AI deciding for them.
- **Would quit if:** first run asks questions they cannot answer, or they
  cannot finish setup.

**L1. First run at large text.** Start: fresh install, text scale 1.3, 360 dp.
Steps: go through the privacy-tier screen and the model screen. Success: every
button is reachable by scrolling; onboarding can be finished; dead tiers look
different before their text is read. Check: tab labels do not wrap to
"Technique / s".

**L2. Choosing a model without jargon.** Start: model screen in onboarding.
Steps: read the options; pick one; note what it costs in space. Success: the
choices say size and speed in household words; a free-space warning appears if
needed. Check: afterwards in Settings, no card shows ACTIVE and Download at
once.

**L3. Open the first case.** Start: model downloaded, Home empty. Steps:
follow the empty-state instruction to open a case. Success: the instruction
names the same button the screen shows ("New case"); the intake conversation
shows a reply bubble as soon as a turn is sent. Check: airplane mode works end
to end.

**L4. Resolution check-in.** Start: a case past its check-in date. Steps: open
the resolution check-in; tap Done without choosing. Success: Done waits for a
choice; nothing is silently recorded as Neutral. Check: plain wording.

**L5. Recovery words.** Start: Settings, no backup. Steps: set up encrypted
backup; read the twelve words; then look for a way to see them again.
Success: words sit in fixed numbered positions; there is a way to re-check
them other than Reset identity. Check: text scale 1.3.

## Secondary: Marcus, the curious partner on the web build

Marcus is 45, Leila's partner, tries Reckon from a laptop browser to see what
the fuss is about.

- **Goal:** open a case without installing anything.
- **Context:** desktop PWA, fast connection, limited patience.
- **Would quit if:** they download 1.6 GB for nothing.

**M1. Web download trap.** Start: web build, fresh. Steps: follow onboarding;
if offered a model download, note it; then tap New case. Success: the web
build either never offers a download it cannot use, or intake works. Check:
the refusal text, if any, is left-aligned and says what to do next.

**M2. Record with few cases.** Start: two closed cases. Steps: open Record and
Forecasters. Success: progress reads "2 of 5 closed cases" and shows data
already held; not only headings of deferral. Check: section labels readable
in both themes.

**M3. What the score means.** Start: six closed cases, some regretted.
Steps: read the Clarity Score and the calibration chart on Record. Success:
the score states its scale and what it measures; a regretted bucket does not
draw a positive bar. Check: dark mode.
