# README 사용법 중심 정리

상태: 계획. 2026-11-02 검토. 목표 시점: `v0.1.0` 릴리스 게시 전.

현재 README는 제품의 배경, 구성과 설계를 설명하지만, 처음 방문한 사용자가 README만 읽고 Shelter Lite를 내려받아 실행하고 결과를 확인할 수는 없습니다. 실제 사용 절차는 기여자용 문서인 CONTRIBUTING에 있습니다. 이 문서는 README를 사용법 중심으로 고치기 위해 확인한 문제, 수정 범위와 결정할 사항을 기록합니다. README와 CONTRIBUTING의 본문은 아직 수정하지 않았습니다.

아래 줄 번호는 `f39f91f` 기준입니다. 영어(루트), 한국어(`language/ko/`), 일본어(`language/jp/`) 파일의 줄 번호가 같습니다.

## 확인한 문제

| # | 문제 | 근거 |
| --- | --- | --- |
| 1 | README에 실행할 수 있는 명령이 없습니다. | `bash` 코드 블록이 0개입니다. 유일한 코드 블록은 정식 CLI의 계획 흐름입니다 (`README.md:57-63`). |
| 2 | 「설치」에 설치 단계와 내려받을 위치가 없습니다. | 설치 방법은 한 문장(`README.md:42`)이고, 이어서 로컬 패키징, 릴리스 workflow, `VERSION`과 `scripts/version.sh` 설명이 나옵니다 (`README.md:43-45`). README와 CONTRIBUTING 모두 Releases 링크가 없습니다. |
| 3 | 사용자용 설치 단계가 CONTRIBUTING에 있습니다. | 「더블클릭으로 설치」 (`CONTRIBUTING.md:338-346`) |
| 4 | 「사용법」이 명령 대신 동작 설명, 개발자용 링크와 계획으로 구성됩니다. | 동작 설명(`README.md:51`), 메시지 미리보기와 설치 흐름 테스트 링크(`README.md:53`), 정식 CLI 계획(`README.md:55-66`). 옵션 표는 CONTRIBUTING에만 있습니다 (`CONTRIBUTING.md:121-131`). |
| 5 | 설치 후 할 일과 실패 시 대응이 README에 없습니다. | 로그 위치(`CONTRIBUTING.md:110`), 결과 확인(`CONTRIBUTING.md:112-119`), 재실행과 Git 사용자 정보, `gh auth login`(`CONTRIBUTING.md:143`), 새 터미널에서 경로 적용(`CONTRIBUTING.md:159`) |
| 6 | 처음 실행할 때 나올 수 있는 macOS 보안 확인을 README에서 안내하지 않습니다. | 서명되지 않은 스크립트 안내는 `CONTRIBUTING.md:346`에만 있습니다. |
| 7 | 도입부가 지금 사용할 수 있는 기능보다 장기 비전을 먼저 설명합니다. | `README.md:13-16`. 현재 사용할 수 있는 것은 Shelter Lite뿐입니다. |
| 8 | 문장 오류가 있습니다. | `README.md:83` 한국어 「Shelter Lite**은**」은 「Shelter Lite**는**」, 영어 「The **Shelter Lite** is」는 관사 없이 「**Shelter Lite** is」로 고칩니다. |

## 독자 시나리오

README의 주 독자는 개발 도구에 익숙하지 않은 macOS 사용자입니다. README는 아래 순서대로 읽으면 설치와 확인을 마칠 수 있어야 합니다.

```text
1. 무엇을 해 주나     지금 Shelter Lite가 설치하는 것과 바꾸지 않는 것
2. 내 Mac이 되나      macOS 15 이상, Apple Silicon, 인터넷, 관리자 계정
3. 내려받기           Releases에서 shelter-lite-macos.zip (체크섬 확인은 선택)
4. 실행               ZIP 풀기 → Shelter Lite.command 더블클릭
                      → macOS 보안 확인, Homebrew 확인과 비밀번호 입력에 응답
5. 결과 읽기          Installation complete / Installation failed의 뜻
6. 설치 후 할 일      터미널과 편집기 다시 열기, Ghostty 열기,
                      Git 사용자 정보와 gh auth login 직접 설정
7. 상태 확인          --dry-run, --check, --version
8. 문제가 생기면      로그 위치, 원인 해결 후 같은 명령으로 다시 실행,
                      되돌리지 않는 범위
```

## 수정 방향

### README 구성

[Standard Readme](https://github.com/RichardLitt/standard-readme/blob/main/spec.md)의 섹션 순서는 유지하고, 각 섹션의 내용을 위 시나리오에 맞춥니다.

| 섹션 | 담을 내용 | 현재에서 바뀌는 점 |
| --- | --- | --- |
| 도입부 | Shelter Lite가 지금 해 주는 일을 먼저 2~3줄로 쓰고, 장기 비전은 뒤에 짧게 | 비전 중심 → 현재 기능 중심 |
| 배경 | 현재 내용을 짧게 유지 | 분량 축소 |
| 설치 | 지원 조건, Releases에서 내려받기, 더블클릭 단계, macOS 보안 확인과 Homebrew 인증 안내 | 개발자용 패키징·버전 설명을 CONTRIBUTING 링크로 대체 |
| 사용법 | 실행 결과 읽는 법, 설치 후 할 일, 명령 표(`--dry-run`, `--check`, `--version`, `--help`), 문제 해결 | 동작 설명 위주 → 명령과 다음 행동 위주. 정식 CLI 계획은 「개발 계획」으로 이동 |
| 라이트 고정 설치 스펙 | 현재 표 유지 | 변경 없음 |
| 제품 구성, 기술 방향, 개발 계획, 저장소 구조 | 현재 내용 유지 | 사용법 뒤에 두는 현재 순서 유지 |

### README와 CONTRIBUTING의 경계

같은 내용을 두 파일에 복제하지 않습니다 (`CONTRIBUTING.md:213`). 사용자가 하는 일은 README, 저장소를 바꾸는 사람이 하는 일은 CONTRIBUTING을 원본으로 둡니다.

| 내용 | 원본 위치 | 처리 |
| --- | --- | --- |
| 더블클릭 설치 단계, macOS 보안 확인 | README 「설치」 | CONTRIBUTING 「더블클릭으로 설치」에서 이동, CONTRIBUTING은 README로 연결 |
| 사용자용 옵션, 결과와 종료 코드 요약 | README 「사용법」 | CONTRIBUTING 「라이트 실행」의 옵션 표를 기준으로 사용자 명령만 옮김 |
| 설치 후 할 일, 로그 위치, 재실행 | README 「사용법」 | CONTRIBUTING에는 세부 정책만 남기고 README로 연결 |
| 저장소에서 실행, 빌드, 테스트, 미리보기 | CONTRIBUTING | 유지. README의 미리보기·테스트 링크(`README.md:53`)는 정리 |
| 버전 규칙, 릴리스 절차, 셸 설정과 백업 세부 | CONTRIBUTING | 유지. README의 `scripts/version.sh` 설명(`README.md:45`)은 링크로 축소 |

## 지켜야 할 조건

- 영어, 한국어와 일본어 README와 CONTRIBUTING을 같은 내용과 구조로 함께 고칩니다 (`CONTRIBUTING.md:204`).
- `v0.1.0` 태그는 README 수정을 포함한 커밋에 지정합니다. 공개한 태그는 다른 커밋으로 옮기지 않습니다 (`CONTRIBUTING.md:401`).
- 아직 없는 배포 주소를 사용 가능한 것처럼 쓰지 않습니다. Releases 링크는 `v0.1.0` 게시와 함께 유효해집니다.
- 검증하지 않은 내용은 그대로 표시합니다. 새 Mac의 전체 설치(`CONTRIBUTING.md:391`)와 브라우저 다운로드, Gatekeeper, Finder 실행 동작(`CONTRIBUTING.md:346`)이 남아 있습니다.
- 비개발자가 읽는 설명은 문제와 다음 행동을 먼저 쓰고, 전문 용어는 처음 나올 때 설명합니다.

## 결정할 사항

1. **다운로드 링크 형태:** 최신 릴리스 페이지(`/releases/latest`)로 연결할지, `v0.1.0` 페이지로 고정할지 정합니다.
2. **정식 CLI 계획 흐름의 위치:** 「사용법」에서 「개발 계획」으로 옮길지, 「사용법」 끝에 계획으로 표시해 남길지 정합니다.
3. **상태 배지:** `v0.1.0` 게시 후에도 `prototype`을 유지할지 정합니다.
4. **저장소에서 실행하는 방법의 위치:** `install.sh`를 저장소에서 직접 실행하는 방법을 README에 둘지, CONTRIBUTING에만 둘지 정합니다.
5. **체크섬 확인:** 비개발자용 기본 단계에 넣을지, 선택 단계로 둘지 정합니다.
