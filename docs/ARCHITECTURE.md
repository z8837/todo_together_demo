# Architecture Notes

## 목표

`todo_together`의 핵심 설계 포인트를 공개 가능한 범위로 축소하면서도, 실제 앱처럼 상태관리와 라우팅, 로컬 저장, 동기화 흐름이 모두 살아 있는 데모를 만드는 것이 목적입니다.

## 설계 원칙

### 1. 원본 구조를 최대한 유지한다
- `app / core / features` 기준으로 나눕니다.
- 각 feature는 `application / domain / data / presentation` 경계를 유지합니다.
- Isar 엔티티는 원본처럼 `core/data/local/entities` 아래에 둡니다.

### 2. 포트폴리오에서 설명할 수 있는 흐름만 남긴다
- 로그인은 mock 처리로 인증 상태 전환만 보여줍니다.
- 서버는 `DemoHttpClientAdapter`가 더미 응답을 돌려주는 방식으로 대체합니다.
- 핵심 화면은 `project_list_fragment`와 `schedule_fragment` 중심으로만 구성합니다.

### 3. local-first를 실제로 동작하게 만든다
- 원격 동기화 결과를 먼저 Isar에 반영합니다.
- 화면은 Riverpod provider가 Isar 스트림을 구독해서 갱신합니다.
- 일정 완료 토글은 로컬 갱신 후 원격 업데이트를 반영하는 예시를 포함합니다.

## 구조 요약

### app
- `bootstrap.dart`: `ProviderScope`로 앱을 시작합니다.
- `router.dart`: 로그인과 2개 탭을 `StatefulShellRoute`로 구성합니다.
- `state/sync_coordinator.dart`: 로그인 이후 초기 동기화와 수동 동기화를 묶습니다.
- `state/tab_item.dart`: 하단 탭과 NavigationRail 구성을 공통화합니다.

### core
- `data/local/local_db.dart`: Isar 초기화와 테스트 환경 분기를 담당합니다.
- `data/local/entities/*`: 프로젝트와 할 일 로컬 엔티티를 둡니다.
- `network/demo_http_client_adapter.dart`: Retrofit이 호출할 더미 API 응답을 제공합니다.
- `widgets/schedule_home_widget_service.dart`: 선택 날짜 일정 정보를 HomeWidget으로 내보냅니다.

### features/auth
- `application/state/auth_controller.dart`: mock 로그인과 인증 상태를 관리합니다.
- `data/datasources/auth_api.dart`: Retrofit 인터페이스입니다.
- `data/repositories/auth_repository.dart`: mock 로그인 응답을 도메인 모델로 변환합니다.

### features/project
- `data/local/*`: Isar 저장과 조회를 담당합니다.
- `data/datasources/project_api.dart`: 프로젝트/할 일 동기화 API를 정의합니다.
- `data/repositories/project_repository.dart`: 로컬 저장소와 원격 API를 조합합니다.
- `presentation/pages/project_list_fragment.dart`: 프로젝트 목록 화면입니다.

### features/schedule
- `domain/usecases/schedule_use_cases.dart`: 일정 완료 상태 변경을 제공합니다.
- `application/schedule_providers.dart`: 일정 관련 provider를 모읍니다.
- `presentation/pages/schedule_fragment.dart`: 월간 캘린더와 날짜별 일정 패널을 보여줍니다.

## 핵심 흐름

### 로그인 후 초기 동기화
1. 사용자가 mock 로그인 버튼을 누릅니다.
2. `AuthController`가 인증 상태를 `authenticated`로 바꿉니다.
3. `SyncCoordinator`가 프로젝트와 할 일을 순서대로 동기화합니다.
4. 동기화 결과가 Isar에 저장되고, 화면은 Riverpod 스트림 구독으로 갱신됩니다.

### 프로젝트 목록 화면
1. `projectsProvider`가 Isar 프로젝트 스트림을 구독합니다.
2. 즐겨찾기 토글은 로컬 저장소를 바로 수정합니다.
3. 수동 동기화 버튼은 더미 API를 다시 호출해 최신 데이터를 반영합니다.

### 일정 화면
1. `scheduleTodosProvider`가 Isar 할 일 스트림을 구독합니다.
2. 선택 날짜 기준으로 ViewModel이 월간 캘린더와 상세 목록을 계산합니다.
3. 완료 토글은 로컬 상태와 원격 상태를 함께 갱신합니다.
4. 선택 날짜 일정은 `ScheduleHomeWidgetService`를 통해 위젯 예시 데이터로 보냅니다.

## 포트폴리오 포인트

- Flutter 앱을 `feature-first`와 계층 분리 기준으로 구성한 점
- Riverpod, GoRouter, Isar, Dio/Retrofit을 한 흐름으로 연결한 점
- 운영 서버 없이도 동기화 아키텍처를 설명 가능한 형태로 만든 점
- 원본 앱의 `project_list_fragment`, `schedule_fragment` 감각을 공개 데모로 재구성한 점
