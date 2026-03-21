# Todo Together Demo

Todo Together의 핵심 UX와 앱 아키텍처를 공개용으로 정리한 Flutter 포트폴리오 데모

![Flutter](https://img.shields.io/badge/Flutter-3.35+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10-0175C2?logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/State-Riverpod-6A5AE0)
![Isar](https://img.shields.io/badge/Local_DB-Isar-00A3FF)
![Dio](https://img.shields.io/badge/Network-Dio%20%2B%20Retrofit-2E7D32)

## 소개

`todo_together_demo`는 실제 스토어 배포 앱 `todo_together`에서 공개 가능한 범위만 분리해 만든 데모 프로젝트입니다.

단순히 화면만 복제한 포트폴리오가 아니라, 아래 흐름이 실제로 작동하도록 구성했습니다.

- Flutter feature-first 폴더 구조
- Riverpod 기반 상태 관리
- Isar 로컬 저장
- Dio/Retrofit 네트워크 계층
- local-first sync 흐름
- HomeWidget 연동 예시

로그인은 mock으로 처리했고, 소셜 로그인과 실제 운영 서버 연동은 제외했습니다. 대신 더미 API 응답과 로컬 데이터 동기화 흐름을 남겨서 앱 구조와 설계 의도를 바로 보여줄 수 있게 했습니다.

## 주요 기능

### 프로젝트 목록

- 프로젝트 목록 조회
- 프로젝트 생성 / 수정 / 삭제
- 즐겨찾기 기반 필터링
- 프로젝트 상세 진입 흐름 연결

### 일정 화면

- 월간 캘린더와 선택 날짜 일정 목록 표시
- 일정 완료 상태 변경
- 일정 숨김 처리
- 일정 추가 / 수정 흐름 연결

### 프로젝트 생성 / 할 일 추가

- 일정 화면에서 `todo` 추가 시 프로젝트 선택 화면 연결
- 프로젝트별 `todo` 생성 / 편집 / 삭제 가능
- 생성 및 편집 결과가 로컬 DB와 목록 화면에 즉시 반영

### 로컬 우선 동기화

- 더미 API 응답을 받아 Isar에 먼저 저장
- Riverpod provider가 Isar 변화를 구독하며 UI 자동 갱신
- 사용자의 생성 / 수정 / 상태 변경 후 관련 provider invalidation 및 재동기화 수행


## 기술 스택

| 카테고리 | 기술 |
| --- | --- |
| Language | Dart 3.10.7 |
| UI | Flutter |
| State Management | flutter_riverpod 2.6.1 |
| Navigation | go_router 16.2.1 |
| Local Database | isar_community 3.3.0 |
| Network | dio 5.9.0 + retrofit 4.6.0 |
| Code Generation | build_runner, json_serializable, retrofit_generator, isar_community_generator |
| Widget Integration | home_widget 0.9.0 |

## 프로젝트 구조

```text
lib/
├── app/                            # 앱 부트스트랩, 라우터, 전역 sync 상태
│   ├── bootstrap.dart
│   ├── router.dart
│   └── state/
├── core/                           # 공통 네트워크, 로컬 DB, UI 토큰, 위젯 서비스
│   ├── data/
│   │   └── local/
│   │       ├── entities/
│   │       └── local_db.dart
│   ├── network/
│   └── widgets/
└── features/
    ├── auth/                       # mock 로그인
    ├── project/                    # 프로젝트 목록, 생성, 할 일 생성/편집
    │   ├── application/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── schedule/                   # 캘린더, 날짜별 일정, 일정 액션
    ├── holiday/                    # 공휴일 조회/동기화
    └── home/                       # 메인 탭 화면
```

## 아키텍처 포인트

### 1. feature-first + 계층 분리

- `features/project`, `features/schedule` 단위로 관심사를 나눴습니다.
- 각 feature는 `application / data / domain / presentation` 구조를 유지합니다.

### 2. Isar 기반 로컬 저장

- 프로젝트, 할 일, 사용자 엔티티를 Isar에 저장합니다.
- 로컬 스토어가 entity와 도메인 모델 사이 매핑 및 upsert를 담당합니다.

### 3. Dio / Retrofit 네트워크 계층

- API 선언은 Retrofit 인터페이스로 분리했습니다.
- 실제 데모 환경에서는 `DemoHttpClientAdapter`가 더미 응답을 반환합니다.

### 4. local-first sync

- 서버 응답을 받은 뒤 Isar에 반영하고, 화면은 Isar watch 스트림을 통해 갱신됩니다.
- 프로젝트 생성, 일정 생성/편집, 완료 처리 이후 관련 목록이 즉시 반영됩니다.

### 5. 라우팅과 상태 흐름 유지

- `GoRouter`의 `StatefulShellRoute`로 프로젝트 / 일정 2개 탭을 구성했습니다.
- 일정 화면에서 `todo` 추가 시 프로젝트 선택, 새 프로젝트 생성, 다시 일정 생성으로 이어지는 흐름을 유지했습니다.

