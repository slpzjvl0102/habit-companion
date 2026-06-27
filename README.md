# Habit Companion (experiment-grade v1)

10살 아이의 아침 습관(이불 정리)을, 키우는 '성장형 컴패니언'을 통해
잔소리 없이 형성하는지 3주간 측정하는 N=1 실험 앱.

- Stack: Flutter (로컬 전용, 백엔드/계정 없음)
- Spec: `docs/spec.md`
- 설계 전문: `docs/design.md`

## 가설
아이가 컴패니언을 키우려는 동기 때문에 잔소리 없이 이불 정리를 스스로 한다.
성공 = 3주 후 주 5일+ 자발 & 부모가 "환경이 했다" 체감.
실패 = 여전히 매일 시켜야 함 / 컴패니언 흥미 상실.

## 스캐폴드 (Flutter 설치 후)
    flutter create .
    # pubspec.yaml deps: provider, shared_preferences, flutter_local_notifications
    flutter pub get
    flutter run
