# Shelter _(shelter)_

[![README style: standard](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)
[![Status: prototype](https://img.shields.io/badge/status-prototype-D99A4E?style=flat-square)](#개발-계획)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](../../LICENSE)

나의 환경을 지키는 피난처. 보안 위협 추적부터 알림, 업데이트까지.

| English | 한국어 | 日本語 |
| --- | --- | --- |
| [English](../../README.md) | **현재 문서** | [日本語](../jp/README.md) |

Shelter는 사용자가 보안 소식을 일일이 찾아보지 않아도, 자신의 환경에 필요한 업데이트를 알고 적용할 수 있도록 돕는 프로젝트입니다.
보안 이슈와 업데이트 정보는 별도 웹사이트에서 제공하고, CLI로 사용자 PC의 상태 확인과 알림, 업데이트를 연결하는 것을 목표로 합니다.

**현재는 라이트 설치기의 첫 구현 단계입니다.** macOS에서 정해진 개발 도구를 한 번에 준비하는 Shell 설치기를 제공합니다. 임시 환경 테스트와 실제 Mac의 설치 미리보기를 검증했으며, 새 Mac에서의 실제 설치 검증과 정식 CLI 구현은 남아 있습니다.

## 목차

- [배경](#배경)
- [설치](#설치)
- [사용법](#사용법)
- [제품 구성](#제품-구성)
- [라이트 고정 설치 스펙](#라이트-고정-설치-스펙)
- [기술 방향](#기술-방향)
- [개발 계획](#개발-계획)
- [저장소 구조](#저장소-구조)
- [관리자](#관리자)
- [기여](#기여)
- [라이선스](#라이선스)

## 배경

새로운 보안 문제가 발표되어도 사용자가 직접 공지를 찾아 읽고, 설치된 버전이 영향을 받는지 판단하고, 업데이트 방법까지 알아내기는 어렵습니다.
도구마다 설치 경로와 업데이트 방식이 다르면 관리 부담도 커집니다.

Shelter는 이 과정을 **추적 → 내 환경과 대조 → 알림 → 업데이트 → 결과 확인**으로 연결하려고 합니다.
주요 대상은 보안 공지나 개발 도구에 익숙하지 않은 일반 사용자입니다. 무엇이 문제인지, 나에게 해당하는지, 다음에 무엇을 하면 되는지를 이해하기 쉽게 전달합니다.

## 설치

라이트 설치기는 저장소의 Shell 파일로 실행합니다. 대상은 **macOS 15 이상, Apple Silicon의 기본 터미널 환경**이며, zsh와 bash 설정을 지원합니다.
별도 Shelter 패키지와 Homebrew Tap은 아직 배포하지 않았습니다.

저장소 받기와 실행 절차는 [CONTRIBUTING의 개발 준비](./CONTRIBUTING.md#개발-준비), 설치 시 변경되는 설정은 [라이트 실행](./CONTRIBUTING.md#라이트-실행)을 참고하세요.

## 사용법

라이트는 실행하면 **Homebrew → Git → VS Code → Node.js/npm → Python/uv → GitHub CLI** 순서로 초기 환경을 준비합니다. 도구 선택 메뉴는 없으며, 정상 실행되는 기존 도구는 유지하고 없는 구성 요소를 설치합니다. 기본 화면은 **설치 완료 또는 설치 실패**와 짧은 안내로 마무리하고, 필요한 경우에만 경고를 덧붙입니다. 색상이 꺼져 있어도 문구로 구분할 수 있습니다. 상세 내용은 설치 로그에 기록하고, 현재 버전과 실행 경로는 `--check`로 확인합니다.

상태별 문구와 색상은 [안내 메시지 미리보기](./CONTRIBUTING.md#안내-메시지-미리보기)에서, 실제 설치 절차의 모의 실행은 [설치 흐름 테스트](./CONTRIBUTING.md#설치-흐름-테스트)에서 확인할 수 있습니다.

아래 보안 정보 연동은 정식 CLI의 개발 계획입니다. 아직 실행 가능한 기능은 아닙니다.

```text
웹사이트에서 보안 이슈와 업데이트 정보 확인
  → CLI로 내 PC의 소프트웨어와 버전 확인
  → 내 환경에 해당하는 업데이트 알림
  → 필요한 업데이트 적용
  → 적용 결과와 재시작 필요 여부 확인
```

업데이트의 자동 적용 여부, 사용자 확인 방식과 알림 채널은 설계 단계에서 결정합니다.
정식 CLI 명령어는 구현된 동작을 검증한 뒤 안내합니다.

## 제품 구성

**웹사이트**는 보안 정보와 대응 방법을 제공하는 사용자 접점입니다.
**정보 수집 기능**은 공식 보안 공지와 릴리스 정보를 추적하는 기반입니다.
**CLI**는 그 정보를 사용자 PC의 상태와 연결하는 도구입니다.

| 구성           | 계획한 역할                                     | 사용자에게 제공할 정보                       |
| -------------- | ----------------------------------------------- | -------------------------------------------- |
| 웹사이트       | 보안 이슈와 업데이트 정보를 모아 쉽게 설명      | 문제의 내용, 영향받는 버전, 대응 방법과 출처 |
| 정보 수집 기능 | 보안 공지와 업데이트 변경 사항 추적             | 원문 링크, 게시 시점, 마지막 확인 시점       |
| CLI            | 설치 상태 확인, 관련 알림, 업데이트와 결과 검증 | 현재 상태, 필요한 변경, 적용 결과            |

보안 이슈를 빠르게 파악할 수 있도록 지속적인 추적을 목표로 합니다. 수집 주기와 알림 지연은 아직 정하지 않았습니다.
Codex, Claude Code 같은 도구의 통합 설치와 관리는 이후 확장 대상으로 검토합니다.

**라이트 버전**은 정해진 스펙 전체를 Shell 설치기로 준비하고 결과를 확인하는 초심자용 초기 설정입니다. 개별 도구를 선택하거나 제외하는 기능은 제공하지 않습니다.
**정식 버전**은 설치 후에도 상태 확인, 보안 알림과 업데이트를 지속적으로 제공할 CLI입니다.
두 버전의 설치 스크립트는 `installers/macos/`에서 함께 관리합니다. 정식 CLI 본체는 설치기와 구분하며, Python을 채택하면 `src/shelter/`에 구현할 예정입니다.

## 라이트 고정 설치 스펙

아래 항목은 모두 라이트에 포함됩니다. Homebrew는 설치 관리자, Git은 버전 관리 도구, VS Code는 편집기입니다. Node.js와 Python은 실행 환경이며 npm과 uv는 해당 환경의 관리 도구입니다. GitHub CLI는 GitHub 연동 도구입니다.

| 순서 | 설치 대상 | 역할 | 새로 설치할 때의 정책 |
| --- | --- | --- | --- |
| 1 | [Homebrew](https://docs.brew.sh/Installation) | 프로그램 설치 기반 | 공식 설치기로 준비 |
| 2 | [Git](https://formulae.brew.sh/formula/git) | 파일 변경 이력 관리 | Homebrew의 `git`, 정상 실행되는 Apple Git도 유지 |
| 3 | [VS Code](https://formulae.brew.sh/cask/visual-studio-code) | 파일과 코드 편집 | Homebrew의 `visual-studio-code`, 기존 `code` 명령 보존 |
| 4 | [Node.js + npm](https://formulae.brew.sh/formula/node@24) | JavaScript 실행과 패키지 관리 | `node@24`로 Node.js 24.x와 함께 제공되는 npm 설치 |
| 5 | [Python + uv](https://docs.astral.sh/uv/guides/install-python/) | Python 실행, 패키지와 가상환경 관리 | Homebrew의 `uv`, uv로 Python 3.14.x 설치 |
| 6 | [GitHub CLI (`gh`)](https://formulae.brew.sh/formula/gh) | GitHub 저장소와 Pull Request 작업 | Homebrew의 `gh`, 로그인은 별도 진행 |

고정 스펙은 **설치할 도구 묶음**을 뜻합니다. 정상 실행되는 기존 버전은 유지하며, 새 Node.js와 Python에만 위 버전 계열을 적용합니다. 패치 버전까지 고정하지 않으며 실제 버전과 경로는 `--check` 결과로 확인합니다. GitHub Desktop은 포함하지 않습니다.

macOS 개발 도구의 `/usr/bin/python3`는 사용자용 Python과 구분합니다. 새 Python은 uv가 관리하는 `python3.14`로 제공하고 시스템 Python이나 기존 버전 관리자의 기본 명령을 바꾸지 않습니다. VS Code는 앱 경로로 확인하므로 Cursor의 `code` 명령을 VS Code로 판단하지 않습니다.

실행 여부 확인은 보안 취약점 검사나 최신 버전 판정이 아닙니다. 세부 설치와 재실행 정책은 [CONTRIBUTING](./CONTRIBUTING.md#라이트-실행)에 정리합니다.

## 기술 방향

**초기 Shell 설치기와 CLI의 대상 운영체제는 macOS입니다.** Windows용 설치, 셸 설정, 업데이트와 검증은 현재 범위에 포함하지 않습니다.
라이트는 macOS 기본 Bash로 실행하며, 실행 전에 Node.js나 Python을 따로 설치할 필요가 없습니다. 정식 CLI와 웹사이트의 기술은 아직 검토 단계입니다.

| 영역                 | 검토 기술                                                                                                                                                                                | 역할                                        | 상태                                   |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | -------------------------------------- |
| 초기 대상 운영체제   | ![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?style=flat-square&logo=apple&logoColor=white) | 라이트 설치와 셸 설정 | Apple Silicon, zsh/bash. Intel, Rosetta, Windows 제외 |
| 웹사이트와 정보 수집 | 미정                                                                                                                                                                                     | 보안 정보 수집, 조회와 사용자 화면          | 기술 선정 전                           |
| CLI 본체             | ![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white)                                                                                      | 상태 확인, 알림, 업데이트 처리              | 우선 검토, 버전 미정                   |
| CLI 개발 도구        | ![Typer](https://img.shields.io/badge/Typer-009688?style=flat-square&logo=typer&logoColor=white) ![uv](https://img.shields.io/badge/uv-DE5FE9?style=flat-square&logo=uv&logoColor=white) | 명령 구성, Python 환경과 의존성 관리        | 후보, 버전 미정                        |
| 초심자용 설치기      | ![Bash 3.2.57](https://img.shields.io/badge/Bash-3.2.57-4EAA25?style=flat-square&logo=gnubash&logoColor=white) | 고정 스펙의 최초 설치와 실행 환경 준비 | 구현됨, Bash 3.2.57로 검사 |
| macOS 배포           | ![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?style=flat-square&logo=homebrew&logoColor=black)                                                                                | CLI 설치와 CLI 자체 업데이트                | 배포 후보                              |

지원 조건과 설치 정책의 근거 파일은 [install.sh](../../installers/macos/install.sh), [tools.sh](../../installers/macos/tools.sh)입니다. 최소 운영체제는 [Homebrew 설치 요구사항](https://docs.brew.sh/Installation)을 기준으로 제한합니다. 현재 실기기 확인은 macOS 26.6.2의 미리보기까지이며, 지원 범위 전체의 실제 설치를 검증한 것은 아닙니다.

## 개발 계획

1. **초심자용 설치기 검증:** 환경 확인, 고정 스펙 설치와 결과 확인을 구현했습니다. 새 Mac에서 실제 설치, 터미널 재시작과 재실행을 검증한 뒤 배포합니다.
2. **CLI 연결:** PC의 설치 상태와 별도 웹사이트의 보안 정보를 연결하고, 해당 환경에 필요한 업데이트를 알립니다.
3. **업데이트와 확장:** 적용 결과 확인과 실패 대응을 구현하고, 도구 통합 설치를 확장합니다.

라이트는 최초 설치부터 시작하고, 정식 CLI는 이후 확장합니다. 세부 기능 범위와 자동 업데이트 정책은 미정입니다.
두 버전은 이 저장소에서 관리합니다. 웹사이트 코드는 이 저장소에 포함하지 않습니다.

## 저장소 구조

### 현재 구조

현재 생성한 디렉터리, 실행 코드와 문서입니다.

```text
shelter/
├── installers/
│   └── macos/        # 라이트와 향후 정식 버전의 macOS 설치기
│       ├── install.sh # 진입점, 고정 스펙과 설치 순서
│       ├── tools.sh   # 도구 확인, 설치, 셸 설정
│       └── tests/
│           └── test.sh # 임시 환경에서 실행하는 설치기 테스트
├── language/
│   ├── ko/
│   │   ├── README.md       # 한국어 제품 소개, 구성과 개발 방향
│   │   └── CONTRIBUTING.md # 한국어 개발 준비, 검증과 기여 절차
│   └── jp/
│       ├── README.md       # 일본어 제품 소개, 구성과 개발 방향
│       └── CONTRIBUTING.md # 일본어 개발 준비, 검증과 기여 절차
├── README.md         # 영문 제품 소개, 구성과 개발 방향
├── CONTRIBUTING.md   # 영문 개발 준비, 검증과 기여 절차
└── LICENSE           # MIT 라이선스
```

### 구성 요소의 역할

라이트는 `install.sh`에서 고정 스펙 전체의 설치를 시작하고 `tools.sh`의 함수를 호출합니다. 정식 버전을 제공할 때도 같은 진입점에 정식 CLI 설치 흐름을 연결할 계획입니다. 현재 `--mode full`은 준비 중 안내와 함께 종료합니다. 버전별 설치 디렉터리나 도구별 하위 폴더는 미리 나누지 않습니다.

정식 CLI 본체의 예정 위치인 `src/shelter/`는 Python 구현을 시작할 때 추가합니다. 웹사이트와 수집 서비스, 공통 데이터 규격의 구조는 연동 범위가 정해지면 검토하며, 현재 설치기 구조에 포함하지 않습니다.
공통 코드나 도구별 처리가 실제로 커질 때 파일을 분리하고, CI와 상세 문서도 필요해지는 시점에 추가합니다.
디렉터리를 만드는 시점과 문서 갱신 절차는 [CONTRIBUTING의 디렉터리 추가와 변경](./CONTRIBUTING.md#디렉터리-추가와-변경)을 따릅니다.

## 관리자

[@4BFC](https://github.com/4BFC)

## 기여

문서 개선, 기능 제안과 Pull Request를 환영합니다.
질문과 제안은 [Issues](https://github.com/4BFC/shelter/issues)에 남겨 주세요. 큰 기능이나 기술 선택은 구현 전에 논의해 주세요.

작업 준비, 검증과 변경 제출 기준은 [CONTRIBUTING](./CONTRIBUTING.md)을 참고하세요.

## 라이선스

[MIT](../../LICENSE) © 2026 poby
