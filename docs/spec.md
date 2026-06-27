# 습관-컴패니언 앱 — 실험-등급 v1 (Flutter)

> 실행 가능 기술 스펙. 설계 전문: `ideas/family-status-reward-app.md`. 산출: /spec.
> 빌드 전제: `git init` + `flutter create` (현재 그린필드, 코드 0).

## Context
맞벌이 부모-자녀 습관 형성 가설("환경이 의지를 이긴다 / 컴패니언 돌봄이 습관을 만든다")을 **N=1로 3주 안에 측정**하기 위한 실험 도구. 제품이 아님. 솔로 개발자 1명이 빌드, 실제 10살 아이 1명 + 부모 1명이 부모 폰 1대에서 사용.

## Current State
그린필드. 코드 0, Flutter 프로젝트 없음, git 저장소 아님.

## 코어 루프
`아이가 '했어!' 탭 → 컴패니언 즉시 활기(게이트 없음) → 부모가 승인(정산) → 컴패니언 성장+포인트 → 밤 롤오버`

## 펫 = 2층 상태기계 (10살용 성장형 컴패니언으로 리스킨)
- **층1 — 기분 ← 아이 행동:** 체크 순간 `energized`(활기). 평소 `idle`. 미수행 시 *하루 경계에서만* `lowEnergy`(에너지 낮음/잠듦 — '슬픔' 아님, 노골적 죄책감 없음). 인스턴트 순간엔 절대 lowEnergy 안 됨. 경미+즉시 회복+누적/악화 없음. 굶김·죽음 없음.
- **층2 — 성장·포인트 ← 부모 정산:** 승인 시 컴패니언 레벨/XP↑ + 포인트 +1. 미승인 시 파생 상태 `awaitingApproval`("성장 준비 완료 · 승인 대기" — 아이는 활기, 보상만 대기).
- **성장 가시화:** 확정 완료마다 레벨/진화 단계가 눈에 보이게 (10살 = 유능감·진행 동기).
- **휴식일 토글(부모):** 그날 컴패니언 `resting`(잠/여행, 긍정), lowEnergy 평가 정지 + 진행 스트릭 일시정지(끊김 없음).

## 화면 (3)
1. **아이 뷰(실행자):** 오늘 고리(들) 큰 탭 카드 + 컴패니언. 탭 → 즉시 활기 반응 → 이후 "승인 대기" 표시.
2. **부모 뷰(관리자):** 오늘 체크된 고리 승인(정산), 휴식일 토글, 다음 고리 승인, 실물 보상 약속 메모(자유 텍스트). 소프트 게이트(별도 탭 + 4자리 PIN)로 아이 자기승인 방지.
3. **주간 성장 스토리 카드(부모, 미션 핵심 C1):** 서사(변화 = 잔소리/의지 아니라 *환경* 귀인) + '그때 vs 지금' 시각(1주차 = "여기서 출발" 베이스라인 → 현재 고리/완료율). 매주 갱신.

## Implementation Details
- **스택:** Flutter. 상태관리 `provider`(단일 `ChangeNotifier` AppState). 영속화 `shared_preferences`(상태 전체를 JSON 1키 직렬화). 백엔드·계정 0.
- **하루 경계:** `day_clock` — 리셋 시각 기본 새벽 4시(늦은 저녁 부모 승인도 그날로 집계). 현재 '습관일' = `now - resetOffset`.
- **진행 트리거:** 활성 고리가 최근 7일 중 5일 완료 → 부모에게 "다음 고리 추가?" 제안 → 부모 승인 시 다음 링크 활성. "5분 독서" 1개 하드코딩 시작, 최대 3개 스택.
- **포인트 경제(사소):** 확정 완료 1 = +1포인트 + 컴패니언 1성장. 실물 보상은 부모 수동 약속 메모만(자동화 없음).
- **저녁 리마인더(유일한 '선택' 조각):** 미승인 체크가 있으면 저녁(기본 20시) 로컬 알림 1회 — "OO의 컴패니언이 성장 준비됐어, 승인 대기 중"(`flutter_local_notifications`). 빼도 코어는 돔.

## 데이터 모델 (shared_preferences에 JSON 1키)
```
AppState {
  habits: [{ id, name, order, status: active|locked }]      // v0: ["5분 독서"]
  dailyLog: { "YYYY-MM-DD": { checked: [habitId], settled: [habitId], restDay: bool } }
  pet: { level, xp, mood: energized|idle|lowEnergy|awaitingApproval|resting, lastFedDate }
  points: int
  rewardPromise: string                 // 부모 수동 메모
  baseline: { weekStartDate, snapshot } // 주간 카드 then-vs-now용
  settings: { resetHour: 4, parentPin, reminderHour: 20 }
}
```

## Acceptance Criteria
1. 아이가 고리 탭 → 컴패니언이 *그 즉시* `energized`(부모 없이). 이후 `awaitingApproval` 표시.
2. 부모가 PIN으로 부모뷰 진입 → 승인 → 컴패니언 성장 + 포인트 +1, `awaitingApproval` 해제.
3. 롤오버 시: (체크 O + 승인 X) → 컴패니언 긍정 유지(보상만 대기), lowEnergy 아님. (체크 X + 승인 X) → `lowEnergy`(경미, 다음 성공에 즉시 회복).
4. 휴식일 ON → 그날 `resting`, lowEnergy 없음, 스트릭 일시정지(리셋 아님).
5. 주간 카드: 부모에게 서사 + 그때vs지금 렌더(1주차 = 베이스라인).
6. 활성 고리 7일 중 5일 완료 → 부모에게 다음 고리 제안 → 승인 시 활성.
7. 앱 재시작해도 전 상태 영속.
8. 컴패니언 절대 죽음/굶음 없음; lowEnergy는 경미·즉시회복·비누적.

## Testing Plan
| Layer | What | Count |
|---|---|---|
| Unit | day_clock 롤오버 · 2층 상태 해석(기분/성장) · 진행 트리거(5/7) · 휴식일 일시정지 | +6 |
| Widget | 아이 탭→즉시 활기 · 부모 승인 플로우 · awaitingApproval 표시 | +3 |
| Manual | 폰에서 하루 전체 루프 (8주 4-루틴 프로그램, 실사용) | — |

## Out of Scope (CUT)
앱스토어 배포 · 회원가입/계정/클라우드 · 템플릿 시스템·라이브러리 · 실물보상 자동화 · 멀티자녀/멀티펫 · 정교한 펫 아트(상태 3종+레벨 표시면 충분) · 백엔드.

## Effort (per-component, human / CC)
- 프로젝트 스캐폴드 + 데이터모델/영속화: 0.5d / ~20min
- day_clock + 2층 상태기계 + 진행 트리거: 1d / ~40min
- 아이 뷰 + 컴패니언 위젯(상태 3종+레벨): 1d / ~40min
- 부모 뷰(승인·PIN·휴식일·보상메모): 0.5d / ~30min
- 주간 스토리 카드(A+B): 0.5d / ~30min
- 저녁 리마인더(선택): 0.5d / ~20min
- 테스트(unit+widget): 0.5d / ~30min
- **합계: ~5 human-day / ~3.5 CC-hour**

## Files Reference (그린필드)
| File | Change |
|---|---|
| `pubspec.yaml` | deps: provider, shared_preferences, flutter_local_notifications |
| `lib/main.dart` | 앱 진입, provider 셋업, 아이/부모 탭 |
| `lib/models/app_state.dart` | AppState 모델 + JSON 직렬화 |
| `lib/services/storage.dart` | shared_preferences 영속화 |
| `lib/services/day_clock.dart` | 하루 경계/롤오버 |
| `lib/services/pet_state.dart` | 2층 상태기계 해석 |
| `lib/screens/child_screen.dart` | 실행자 뷰 |
| `lib/screens/parent_screen.dart` | 관리자 뷰(PIN 게이트) |
| `lib/screens/weekly_card.dart` | 주간 성장 스토리 카드 |
| `lib/widgets/companion.dart` | 컴패니언(상태3+레벨) |
| `test/*` | unit + widget |

## 목표 — 8주 4-루틴 프로그램 (아주 작은 습관의 힘)
실험이 아니라 **내 아이한테 습관을 만들어주는 도구.** 8주에 걸쳐 아주 작은 습관 1개부터 시작해 **habit stacking** 으로 4개 루틴을 자리잡게 한다.

- **메커니즘 (앱에 내장):** 활성 습관이 5/7일 익으면 관리자가 *이어서* 다음 작은 습관 추가 → 최대 **4개 체인.** 『아주 작은 습관의 힘』의 "After [현재 습관], I will [새 습관]" = 앱의 '고리 잇기'.
- **동력:** 컴패니언(즉시 보상) + 관리자 승인. 잔소리 대신 환경.
- **cadence(대략):** 습관 하나 ~2주 → 8주 ≈ 4습관.

  | 주 | 체인 |
  |---|---|
  | 1–2 | ① 5분 독서 (시드, 아주 작게) |
  | 3–4 | + ② (①이 5/7 익으면 스택) |
  | 5–6 | + ③ |
  | 7–8 | + ④ → 4-체인 완성 |

- **'성공':** 8주 후 4개 루틴이 스스로 돌고 잔소리가 줄어듦. (개인 도구 — 반증·대조군·회수 같은 실험 장치 불필요.)
- **관리자 역할:** 받아보고·승인하고·반응. 컴패니언이 운전, 관리자는 잔소리 대신 환경을 깐다.
- **습관 상한 = 4** (코드: `pet_state.progressionReady`, `app_state.addNextHabit`).
