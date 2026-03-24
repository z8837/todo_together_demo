# Todo Together Demo

![Flutter](https://img.shields.io/badge/Flutter-3.35+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10-0175C2?logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/State-Riverpod-6A5AE0)
![Isar](https://img.shields.io/badge/Local_DB-Isar-00A3FF)
![Dio](https://img.shields.io/badge/Network-Dio%20%2B%20Retrofit-2E7D32)

## 소개

`Todo Together Demo`는 Flutter 기반의 feature-first 구조, Riverpod 상태 관리, Isar 로컬 DB, Dio/Retrofit 네트워크 계층, local-first 동기화 흐름을 보여주기 위한 데모 프로젝트입니다.

로그인은 mock 방식으로 처리하고, 화면은 로컬 DB를 중심으로 갱신됩니다. 네트워크 계층은 `DemoHttpClientAdapter`를 통해 데모 응답을 반환하도록 구성되어 있습니다.

## 주요 기능

- 프로젝트 목록 조회
- 프로젝트 생성 / 수정 / 삭제
- 즐겨찾기 필터
- 캘린더 기반 일정 화면
- 일정 생성 / 수정 / 완료 / 숨김
- local-first sync
- Home Widget 연동 예시

## 기술 스택

| 카테고리 | 기술 |
| --- | --- |
| Language | Dart 3.10.7 |
| UI | Flutter |
| State Management | flutter_riverpod 2.6.1 |
| Navigation | go_router |
| Local Database | isar_community 3.3.0 |
| Network | dio + retrofit |
| Code Generation | build_runner, json_serializable, retrofit_generator, isar_community_generator |
| Widget Integration | home_widget |
| Test | flutter_test, integration_test |

## 프로젝트 구조

```text
.
├─ .github/
│  └─ workflows/
│     └─ flutter-tests.yml        # analyze / test / integration_test CI
├─ integration_test/
│  └─ app_flow_test.dart          # 통합 테스트
├─ lib/
│  ├─ main.dart
│  ├─ app/
│  │  ├─ bootstrap.dart
│  │  ├─ router.dart
│  │  └─ state/                   # 앱 전역 sync, 앱 상태 조정
│  ├─ core/
│  │  ├─ data/
│  │  │  ├─ local/
│  │  │  │  └─ entities/          # Isar 엔티티
│  │  │  └─ models/               # 공용 DTO / 모델
│  │  ├─ localization/            # tr() 확장 등
│  │  ├─ network/
│  │  │  └─ result/               # ApiError, Result 타입
│  │  ├─ preferences/             # UI preference 저장
│  │  ├─ theme/
│  │  ├─ ui/                      # 토큰, spacing, system UI
│  │  ├─ utils/
│  │  └─ widgets/                 # 공용 위젯, dialog, home widget service
│  └─ features/
│     ├─ auth/
│     │  ├─ application/
│     │  ├─ data/
│     │  ├─ di/
│     │  ├─ domain/
│     │  └─ presentation/
│     ├─ holiday/
│     │  ├─ application/
│     │  ├─ data/
│     │  ├─ di/
│     │  ├─ domain/
│     │  └─ presentation/
│     ├─ home/
│     │  └─ presentation/         # 메인 shell 진입 화면
│     ├─ project/
│     │  ├─ application/
│     │  │  └─ state/
│     │  ├─ data/
│     │  │  ├─ datasources/       # Retrofit API, adapter 연동
│     │  │  ├─ local/             # project/todo 로컬 스토어
│     │  │  │  └─ entities/
│     │  │  ├─ models/
│     │  │  └─ repositories/
│     │  ├─ di/
│     │  ├─ domain/
│     │  │  ├─ entities/
│     │  │  ├─ repositories/
│     │  │  └─ usecases/
│     │  └─ presentation/
│     │     ├─ pages/
│     │     │  ├─ add_todo/
│     │     │  └─ project_detail/
│     │     ├─ state/
│     │     ├─ viewmodels/
│     │     │  └─ add_todo/
│     │     └─ widgets/
│     ├─ schedule/
│     │  ├─ application/
│     │  │  └─ home_widget/       # 위젯 연동용 상태/브리지
│     │  ├─ di/
│     │  ├─ domain/
│     │  │  └─ usecases/
│     │  └─ presentation/
│     │     ├─ pages/
│     │     └─ viewmodels/
│     └─ workspace/
│        ├─ application/
│        ├─ data/
│        │  ├─ datasources/
│        │  ├─ models/
│        │  └─ repositories/
│        ├─ domain/
│        │  ├─ entities/
│        │  ├─ repositories/
│        │  └─ usecases/
│        └─ presentation/
│           ├─ pages/
│           └─ widgets/
├─ test/
│  ├─ test_helpers/               # fixture, fake repository
│  ├─ unit/                       # viewmodel / pure logic 테스트
│  ├─ widget/                     # 위젯 테스트
│  └─ widget_test.dart            # 로그인 화면 스모크 테스트
├─ pubspec.yaml
└─ pubspec.lock
```

## 구조 설명

### app

- 앱 전역 bootstrap, router, sync coordinator를 둡니다.
- feature 바깥에서 공통으로 쓰는 앱 레벨 흐름을 담당합니다.

### core

- 공통 인프라 레이어입니다.
- 로컬 DB, 네트워크 공통 타입, UI 토큰, preference, 공용 위젯이 들어 있습니다.

### features

- 기능 기준으로 분리된 feature-first 구조입니다.
- 주요 feature는 `auth`, `project`, `schedule`, `holiday`, `workspace`, `home` 입니다.
- 각 feature는 필요에 따라 `application / data / di / domain / presentation` 구조를 가집니다.

### test / integration_test

- `test/unit`: 순수 로직 테스트
- `test/widget`: 위젯 단위 테스트
- `integration_test`: 사용자 흐름 기반 통합 테스트
- 공통 fixture와 fake repository는 `test/test_helpers`에 둡니다.

## 테스트 / CI

- CI 워크플로: `.github/workflows/flutter-tests.yml`
- 자동 실행:
  - `flutter analyze`
  - `flutter test`
  - `flutter test integration_test -d windows`
