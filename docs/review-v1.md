# /autoplan Review — habit_companion v1

> NOTE: framing changed after this review. The product is a **personal 8-week
> 4-routine habit-building tool** (아주 작은 습관의 힘), NOT a falsifiable
> experiment. The CEO "User Challenge" (ABA / demand / falsifiability) is
> SUPERSEDED — those critiques applied to a startup/proof goal, not a personal
> tool. **All the Eng + Design bug fixes below were applied and remain valid**
> (they improve the app regardless of framing). See `spec.md` / `roadmap.md`.

Post-implementation review of `docs/spec.md` + `lib/` @ commit `6cc5cb1`.
Voices: **codex unavailable** → 1 independent Claude subagent per phase (CEO / Design / Eng) + primary review. UI scope = yes (Design ran); DX scope = no (consumer app, DX skipped).

## Cross-phase theme (highest-confidence signal)
All three voices + the prior office-hours converge: **the experiment as built is unlikely to produce a trustworthy answer.** Not because the code is sloppy — because (a) the design can't *falsify* its hypothesis [CEO], (b) the motivator the hypothesis depends on is under-built [Design], (c) the core loop silently drops the working parent's approval [Eng]. (a) is a protocol decision (yours); (b)/(c) are fixable code.

---

## CEO — strategy (→ User Challenge, NOT auto-decided)
- **C1 (critical):** the test habit is chosen to be "impossible to fail" → a "success" is indistinguishable from "kid would've done it anyway." Engineered out the ability to detect the companion's effect.
- **C2 (critical):** no companion-OFF / withdrawal phase → you measure engagement-while-new, not a habit. A habit is what persists when the prop is removed.
- **C3 (critical):** 5 confounded variables fire at once (novelty, parent attention, parent's own engagement, demand characteristics, rigged habit) → a positive result is uninterpretable; can't attribute it to the companion-care loop (the literal hypothesis).
- **C4 (critical):** "parent feels environment-not-willpower" is the mission outcome, scored by the single most biased observer (the believer/developer parent) → effectively unfalsifiable.
- **H1:** building the app to run the experiment is procrastination as method; the full loop is testable on paper in ~1 day.
- **H2:** you're building the mode with zero founder-problem-fit (dual/kid) first; the single/adult mode is on-mission, has an instant subject (you), needs no recruiting.
- **H3:** 3 weeks is inside the novelty window (~2 months to consolidate, Lally) → even a clean success ≠ habit.
- **H4/M1-M3:** demand characteristics + home contamination; optimistic effort; subject age 10 sits one eye-roll from collapse; week-1 baseline is contaminated.
- **Single most important change:** add a withdrawal phase + a habit with real room to fail, piloted on paper first → turns a demo into a falsifiable experiment.

## Design — UX
- **CRIT-1:** companion never visibly evolves — static `🐲` at Lv.1 and Lv.10 (`companion.dart`), only a `Lv.N` text changes. The spec's core 10yo motivator ("성장 가시화") is undelivered; XP data (`petXp` vs `petLevel*3`) is never surfaced.
- **CRIT-2:** weekly card hero number is *chain count* (`weekly_card.dart`) → reads "1→1" for most of a 3-week run (no change); the metric that actually moves (self-initiation) is buried as subtext.
- **HIGH-3:** mission-critical weekly story is a bottom-of-list link, below rest-day/reward.
- **HIGH-4:** PIN gate doesn't re-lock — `_unlocked` lives in state + `IndexedStack` keeps it alive → checked once per launch; kid can tab back and self-approve.
- **HIGH-5:** "승인할 항목이 없어요" is ambiguous (kid did nothing vs already approved) — parent's #1 question unanswered.
- **HIGH-6:** companion has no name/identity (cheapest bonding lever, absent).
- **MED 7-12:** lowEnergy at 0.45 opacity reads as guilt; check payoff too subtle; "고리" metaphor never shown; no approve-feedback toast; no first-run onboarding/PIN nudge; "자발" overclaims (data can't tell self-start from nagged tap).
- **Highest-impact:** make the companion visibly evolve + chargeable (CRIT-1 + payoff + XP ring).

## Eng — correctness
- **CRIT-1:** **prior-day checks are unapprovable.** `pendingApproval` (`app_state.dart:43`) + `settleHabit` (`:54`) key strictly to `today`. Parent who approves next morning → `today`=D+1, pending empty, day-D check unreachable → no point/growth ever, and `_rollover` sees D as checked so pet isn't even lowEnergy → loss is invisible. Hits the exact target user (busy parent, evening/next-day settle). **= the spec's own failure signature.** Fix: `pendingApproval`/`settleHabit` span last ~2 habit-days and settle into the correct day's log.
- **HIGH-2:** rollover + day-boundary fire only on cold `boot()`; no lifecycle/resume hook → on a resident Android app, lowEnergy/lastSeenDay go stale. Fix: `WidgetsBindingObserver` re-runs rollover on resume.
- **HIGH-3:** any decode error → `storage.load` returns null → `boot` reseeds → **silently wipes 3-week history + baseline.** Hard non-null casts (`lastSeenDay as String`) make a schema change mid-run catastrophic. Fix: backup raw blob on failure, tolerant `fromJson` defaults, surface error.
- **HIGH-4:** `parentPin` defaults null → gate off + undiscoverable → kid self-approves by default. Fix: first-run PIN prompt.
- **MED-5:** `petLowEnergy` reflects only last ended day; a rest day in the gap leaks stale state (neither branch hit). Fix: compute from most recent non-rest ended day.
- **MED-6:** `_persist()` fire-and-forget save, errors swallowed → lost write on kill. Fix: `unawaited(save().catchError(log))`, await on lifecycle pause.
- **MED-7:** `addNextHabit` only guards `length>=3`, not `progressionReady` — 5/7 gate enforced by UI only. Fix: re-assert in model.
- **MED-8:** DST-unsafe day math — **latent only** (KST has no DST; correctly de-prioritized).
- **LOW:** id scheme removal-fragile; `dayLog()` mutate-on-read confirmed mitigated (only write paths call it); baseline hardcoded; no uncheck (mis-tap = false completion).
- **Top bug:** Eng-CRIT-1.

## Architecture (clean, no cycles)
```
main → state/app_state(ChangeNotifier) → {models/app_data, services/day_clock, pet_state, storage}
       screens/{child→widgets/companion, parent→weekly_card}
```

## Test diagram — gaps
Covered: check/settle/rollover-happy/rest/progression/day_clock. **Gaps:** prior-day settle (the critical bug — untested), rollover-on-resume, rest-day-in-gap, corrupt-load reseed, save failure, weekly_card render, addNextHabit gate.

---

## Decision Audit Trail (auto-decided via 6 principles)
| # | Phase | Finding | Decision | Principle |
|---|---|---|---|---|
| 1 | Eng | Prior-day check unapprovable | **FIX** | P1 correctness / core loop |
| 2 | Eng | Corrupt/changed blob → silent wipe | **FIX** | P1 data integrity |
| 3 | Eng | Rollover only on cold boot | **FIX** | P1 |
| 4 | Eng+Design | PIN off-by-default + no re-lock + buried | **FIX** | P1 core gate |
| 5 | Design | Companion never visibly evolves | **FIX** | P1 spec-promised motivator |
| 6 | Design | Weekly hero = flat chain count | **FIX** | P5 small |
| 7 | Eng | addNextHabit bypasses 5/7 gate | **FIX** | P5 explicit |
| 8 | Eng | lowEnergy rest-day passthrough | **FIX** | P5 |
| 9 | Eng | Fire-and-forget save swallows errors | **FIX** | P3 |
| 10 | Design | Weekly story buried → promote | FIX (taste-lean) | P1 |
| — | Design | naming, battery-reframe, chain visual, toast, onboarding | DEFER → post-pilot | P3 |
| — | Eng | DST-safe math; uncheck; id robustness | DEFER (low / KST) | P3 |

## User Challenge (NEVER auto-decided)
**CEO methodology cluster (C1–C4, H1–H3).** Both the independent voice and the prior office-hours say: as designed, the experiment can't falsify its hypothesis. Restructure toward a falsifiable protocol (baseline → companion-ON → companion-OFF withdrawal, on a habit with real room to fail, behavioral outcome not "felt", paper-piloted first). The user's original direction ("build the app, run 3wk on 이불 정리, success = 5/7 + parent feels it") is the default and stands unless the user changes it.
