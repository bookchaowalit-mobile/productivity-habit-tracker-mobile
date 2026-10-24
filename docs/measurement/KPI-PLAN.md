---
title: "Habit Tracker (mobile) — KPI and Instrumentation Plan"
status: approved
created: 2026-10-22
updated: 2026-10-22
description: "How we would know Habit Tracker helps people keep habits, which events that needs, and what is actually live today (Sentry errors only)."
template: architecture-docs templates/sdlc/kpi-and-instrumentation-plan.md
---

# Habit Tracker (mobile) — KPI and Instrumentation Plan

## Document control

| Field | Value |
|---|---|
| Product | bookchaowalit-mobile/productivity-habit-tracker-mobile (no live URL, not store-released) |
| Version / status | 0.1 / **approved** (2026-10-24) — definitions only; no analytics is live, no baselines |
| Metric owner | Owner (bookchaowalit) |
| AI maker | Claude Code (b-tier-b session, 2026-10-22) |
| AI reviewer | independent Claude reviewer subagent (`solo:solo-reviewer`, Sonnet, read-only, no maker context), 2026-10-24: approved (see Approval) |
| Charter objectives | OBJ-01 below (no separate charter) |
| Analytics / data source of truth | **None live.** Product analytics (PostHog per ADR-0005) is pending owner decision D4. Sentry (`personal-yu0/productivity-habit-tracker-mobile`) receives crash reports only from builds that get `SENTRY_DSN` |
| Dashboard | none |
| Next review | 2026-11-15 (Big Loop M1) or when D4 is decided |

## KPI tree

```text
OBJ-01 People who install the app keep at least one habit going
  └─ KPI-O-01 Week-4 retained habit keepers
       ├─ KPI-L-01 First-day activation (habit created and checked off on day 1)
       ├─ KPI-L-02 Check-off rate on scheduled days
       └─ KPI-G-01 Crash-free sessions
```

## KPI definitions

| KPI ID | Type | Name | Formula | Unit | Min volume | Data source and event(s) | Baseline | Target | Alert | Cadence | Owner |
|---|---|---|---|---|---|---|---|---|---|---|---|
| KPI-O-01 | outcome | Week-4 retained habit keepers | installs with ≥ 1 `habit_checked` in days 22–28 / installs in the cohort | % | ≥ 50 installs per cohort | `app_opened`, `habit_checked` (planned) | not yet measured | set after first cohort | — | monthly | Owner |
| KPI-L-01 | leading | First-day activation | installs with `habit_created` and `habit_checked` on day 1 / installs | % | ≥ 50 installs | `habit_created`, `habit_checked` (planned) | not yet measured | set after first cohort | — | weekly | Owner |
| KPI-L-02 | leading | Check-off rate | `habit_checked` (not undone that day) / scheduled habit-days | % | ≥ 200 scheduled habit-days | `habit_checked`, `habit_unchecked`, schedule count on `app_opened` (planned) | not yet measured | set after first cohort | — | weekly | Owner |
| KPI-G-01 | guardrail | Crash-free sessions | 1 − sessions with an unhandled error / sessions | % | ≥ 100 sessions | Sentry errors (live when DSN set); session count needs analytics | not yet measured | ≥ 99.5% | any new Sentry issue | daily | Owner |

Below the minimum volume a rate is reported as `not measurable`. Today the app
has no store listing and no known users, so every KPI is `not measurable`.

## Event and data specification

| Event | Trigger | Properties | Personal data? | Emitted by | Status |
|---|---|---|---|---|---|
| `app_opened` | App reaches the Today tab | `app_version`, `habit_count`, `scheduled_today` | pseudonymous install ID only | app | planned (waits for D4) |
| `habit_created` | "Save habit" succeeds | `weekday_count` (never the habit name) | pseudonymous install ID only | app | planned |
| `habit_checked` / `habit_unchecked` | Today checkbox toggled and saved | `streak_after` | pseudonymous install ID only | app | planned |
| `save_failed` | Preferences write rejected | — | no | app | planned |
| Sentry error event | Unhandled Flutter/Dart error | stack trace, device/OS, release | no: request, user, breadcrumbs and extra are stripped in `lib/observability/sentry_setup.dart` | app | **implemented** (needs `--dart-define=SENTRY_DSN`) |

Privacy and data rules:

- Never send habit names or any free text. Habit names stay on the device.
- An install ID is still personal data under PDPA. Before any analytics event
  ships: privacy impact note, consent decision and an in-app opt-out.
- Retention: Sentry project default (90 days). Analytics retention set with D4.
- Sentry (org `personal-yu0`) is the data processor for crash reports; its data
  region and DPA are recorded with D4.

## Dashboards and alerts

| Dashboard / alert | KPIs | Location | Status |
|---|---|---|---|
| Sentry issues for `productivity-habit-tracker-mobile` | KPI-G-01 (errors only) | Sentry org `personal-yu0` | live, but only for APKs built by CI with the DSN |
| Product dashboard | KPI-O-01, KPI-L-01, KPI-L-02 | — | planned (D4) |

## Instrumentation verification (before G10)

| # | Check | Result |
|---|---|---|
| 1 | Events fire once per action | not run: no analytics events exist |
| 2 | Counts reconcile with the system of record | not applicable yet |
| 3 | No PII in payloads | Sentry scrubbing unit-tested in `test/sentry_setup_test.dart`; analytics not built |
| 4 | Dashboard renders | not set up |
| 5 | Alert reaches the channel | not set up |
| 6 | Baselines captured | waived — no users; dated action: revisit at first store or tester release |
| 7 | Consent respected | not applicable until analytics ships |

## Change history of definitions

| Date | KPI ID | Change | Reason | Baseline restated? | Approved by |
|---|---|---|---|---|---|
| 2026-10-22 | all | First draft | Big Loop L3 | no | pending owner |

## Approval (2026-10-24)

| Field | Value |
|---|---|
| Checker | independent Claude reviewer subagent (`solo:solo-reviewer`, Sonnet, read-only, no maker context) |
| Approver | AI approval under the owner's process (approvals by the owner or AI with evidence; maker and checker are different agents). Recorded by Claude session oa-remainder on the owner's instruction "ทำที่เหลือให้หน่อย" (2026-10-24) |
| Verdict | **approved** |
| Evidence | lib/observability/sentry_setup.dart + test; ci.yml:68 SENTRY_DSN; no analytics events; all events marked planned. |
