# chat_toolkit 성능 개선 전후 비교

메시지가 많은 채팅방에서 초기 로드와 메시지 수신이 느린 문제를 개선하고, 같은 조건에서 개선 전후를 측정해 비교한 문서입니다.

- 대상 버전: 1.6.2 (개선 전 기준 커밋 `0921355`)
- 측정일: 2026-11-16

## 요약

| 항목 | 개선 전 | 개선 후 | 변화 |
|---|---|---|---|
| 초기 로드 `setMessages` 1만 건 (앱, profile) | 753 ms | 39 ms | 약 19배 빨라짐 |
| 메시지 1건 수신 시 프레임 build (앱, profile, 1만 건) | 53 ms, 30프레임 중 30 jank | 0.8 ms, jank 0 | 약 65배 빨라짐 |
| 이전 페이지 붙인 뒤 프레임 build (앱, profile, 1만 건) | 55 ms, 5프레임 중 5 jank | 1.5 ms, 50프레임 중 1 jank | 약 37배 빨라짐 |

- 개선 전에는 1만 건 채팅방에서 메시지가 하나 올 때마다 프레임 예산(16.7 ms)을 3배 넘게 써서 매번 버벅였습니다. 개선 후에는 메시지 건수와 상관없이 1 ms 안팎입니다.
- 초기 로드는 O(N²) 에서 O(N log N) 으로 바뀌었습니다.

## 측정 환경

| 항목 | 값 |
|---|---|
| 기기 | Apple M3, macOS 26.5.2 |
| Flutter | 3.44.4 (stable) |
| 앱 측정 | `example` 앱, macOS 데스크톱, `--profile` 모드 |
| 단위 측정 | `flutter test` (debug/JIT 모드) |

`flutter test` 는 debug/JIT 모드라 절대 수치가 실제 앱과 다릅니다. 같은 기기에서 개선 전후를 비교하는 용도로만 봐야 합니다.

### 테스트 데이터

- 메시지 간격 90초. 1만 건이면 약 10일치라 날짜 구분선이 생깁니다.
- 5건마다 보내는 쪽이 바뀝니다.
- 메시지마다 분(minute)이 달라서 메시지 1건이 그룹 1개가 됩니다. 그룹 수가 메시지 수와 같은, 가장 불리한 조건입니다.
- `setMessages` 입력은 순서를 섞어서 넣습니다.

## 측정 결과

### 1. 앱 profile 측정 (macOS, 1만 건)

시나리오는 초기 로드, 300 ms 간격으로 1건 수신 30회, 50건짜리 이전 페이지 붙이기 5회입니다.

| 시나리오 | 지표 | 개선 전 | 개선 후 |
|---|---|---|---|
| 초기 로드 | `setMessages` 소요 시간 | 753 ms | 39 ms |
| 1건 수신 x30 | 프레임 build 중앙값 / 최대 | 53.0 / 55.5 ms | 0.8 / 3.8 ms |
| 1건 수신 x30 | jank 프레임 (>16.7 ms) | 30 / 30 | 0 / 54 |
| 이전 페이지 x5 | `appendMessages` 1회 | 1.1 ~ 6.1 ms | 1.5 ~ 4.6 ms |
| 이전 페이지 x5 | 프레임 build 중앙값 / 최대 | 55.4 / 56.1 ms | 1.5 / 8.5 ms |
| 이전 페이지 x5 | jank 프레임 | 5 / 5 | 1 / 50 |

- 수집된 프레임 수가 개선 전후로 다른 것은, 개선 전에는 한 프레임이 길어서 여러 변경이 한 프레임에 묶였기 때문입니다.
- 초기 로드 직후 첫 프레임에는 셰이더 컴파일 같은 앱 시작 비용이 섞여 있어서 비교 지표에서 뺐습니다.

### 2. 벤치마크 테스트 (`flutter test`, 중앙값)

| 시나리오 | 개선 전 | 개선 후 |
|---|---|---|
| `setMessages` 1천 건 | 27.5 ms | 3.5 ms |
| `setMessages` 1만 건 | 830 ms | 27 ms |
| 1건 수신 + pump (위젯 빌드 포함), 1천 건 | 4.9 ms | 3.6 ms |
| 1건 수신 + pump (위젯 빌드 포함), 1만 건 | 19.8 ms | 3.1 ms |
| `addMessage` 1건 (컨트롤러만), 1만 건 | 0.12 ms | 0.10 ms |
| `containsMessageId` (없는 id), 1만 건 | 0.11 ms | 0.09 ms |
| `appendMessages` 50건 (1만 건 로드 상태) | 1.18 ms | 1.31 ms |

- 개선 전 `setMessages` 는 메시지가 10배 늘 때 약 30배 느려졌습니다(O(N²)). 개선 후에는 약 8배로, 건수에 거의 비례합니다.
- 개선 전 1건 수신 비용은 건수에 비례해 늘었습니다. 개선 후에는 1천 건과 1만 건의 차이가 없습니다.
- `addMessage`, `containsMessageId`, `appendMessages` 는 손대지 않은 경로라 차이는 측정 오차 수준입니다.

## 원인과 개선 내용

### 1. 초기 로드 O(N²) — `lib/chat/chat_controller.dart` `setMessages`

**원인**

- 정렬 비교 함수 안에서 `DateTime.tryParse` 를 비교할 때마다 두 번씩 호출했습니다(약 N log N 회 파싱).
- 정렬 후 메시지마다 `addMessage` 를 호출했습니다. `addMessage` 는 중복 id 를 찾으려고 매번 전체 그룹과 메시지를 훑어서(`_groupOf`) 전체가 O(N²) 였습니다.
- 메시지마다 변경 알림을 보냈습니다.

**개선**

- 메시지별 타임스탬프를 한 번만 파싱해 `(message, date)` 레코드로 만든 뒤 정렬합니다. 결과는 넘겨받은 리스트에 다시 써서 "리스트를 제자리 정렬한다"는 기존 동작을 유지합니다.
- 정렬된 목록을 한 번 순회하며 그룹핑합니다. 중복 id 는 그 자리의 메시지를 교체하는 기존 동작을 지역 Map 으로 O(1) 에 처리합니다.
- 안읽음 처리(`isRead`)는 기존과 같습니다.
- 변경 알림은 끝에 한 번만 보냅니다.
- 실패 메시지(`_failedMessageEntries`)가 등록돼 있으면 `addMessage` 를 부를 때마다 실패 메시지를 끝으로 옮기는 기존 동작이 있습니다. 이 경우에만 기존 경로(`addMessage` 반복)를 그대로 씁니다.

### 2. 날짜 구분선 전체 재계산 — `lib/chat/chat.dart` `_buildMessageSliverList`

**원인**

메시지 목록이 바뀔 때마다(1건 수신 포함) 전체 그룹에 대해 다음 작업을 했습니다.

- `isDateChangedComparedTo` 호출로 그룹마다 `DateTime.tryParse` 2회
- 전체 그룹의 identity Map 생성

1만 건(그룹 1만 개) 기준으로 이 준비 단계만 약 17 ms(debug)가 걸렸고, 1건 수신 비용의 대부분이었습니다.

**개선**

- 날짜 구분선 여부는 `SliverChildBuilderDelegate` 가 화면에 들어오는 항목을 빌드할 때 그 항목에 대해서만 계산합니다.
- 그룹 → 인덱스 조회는 identity Map 을 미리 만들지 않습니다. `findChildIndexCallback` 이 불릴 때 목록 끝에서부터 찾습니다. 이 콜백은 현재 빌드된(화면에 보이는, 보통 최신 쪽) 항목에만 불리므로 끝에서 찾는 쪽이 저렴합니다.
- 그룹 리스트 스냅샷 복사는 포인터 복사라 비용이 작아서 유지했습니다.

## 하지 않은 것

| 항목 | 이유 |
|---|---|
| id → 그룹 영구 인덱스 (`_groupOf`, `containsMessageId` O(1)) | 1만 건에서도 0.1 ms 수준이라 이득이 작습니다. `messageGroups` 가 수정 가능한 리스트로 외부에 노출돼 있어서, 외부에서 직접 고치면 인덱스와 실제 내용이 어긋날 위험이 있습니다. |
| 앱 프로젝트 `base_chat_load.dart` 이전 메시지 로드 | 이 저장소 밖의 코드입니다. 기존 id 를 `Set` 으로 중복 검사, 정렬 전 DateTime 한 번만 파싱, 전체 복사 제거를 그쪽에 따로 적용해야 합니다. |

## 동작 검증

`test/chat_controller_set_messages_test.dart` 를 추가했습니다.

- 새 `setMessages` 결과가, 변경하지 않은 `addMessage` 로 하나씩 넣은 결과와 같은지 비교합니다. 중복 id, 빈 id, 안읽음, 같은 시각 메시지의 `customSortCallback`, `additionalGroupCondition` 경우를 포함하고 입력 순서를 섞어 20회 반복합니다.
- 넘겨받은 리스트를 제자리 정렬하는지 확인합니다.
- 변경 알림이 한 번만 가는지 확인합니다.
- 날짜 구분선이 첫 그룹과 날짜가 바뀌는 그룹에만 나오는지, 새 날짜의 메시지가 추가되면 구분선이 생기는지 확인합니다.

기존 테스트와 함께 전체 테스트가 통과합니다.

## 재현 방법

벤치마크 테스트:

```bash
flutter test test/perf/chat_perf_benchmark_test.dart --reporter expanded | grep PERF
```

앱 profile 측정 (`PERF_SEED` 를 주지 않으면 기존 데모로 동작합니다):

```bash
cd example
flutter run --profile -d macos --dart-define=PERF_SEED=10000
```

로그의 `[PERF]` 줄에 단계별 소요 시간과 프레임 build/raster 시간이 출력됩니다. DevTools Performance 탭에서는 `perf:setMessages`, `perf:addMessage`, `perf:appendMessages` 구간으로 보입니다.

개선 전 수치를 다시 재려면 `lib/` 만 기준 커밋으로 되돌린 뒤 같은 명령을 실행합니다.

```bash
git stash push lib/
# 측정
git stash pop
```
