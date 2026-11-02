# Shelter _(shelter)_

[![README style: standard](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)
[![Status: prototype](https://img.shields.io/badge/status-prototype-D99A4E?style=flat-square)](#開発計画)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](../../LICENSE)

あなたの環境を守るシェルター。セキュリティ脅威の追跡から通知、更新まで。

| English | 한국어 | 日本語 |
| --- | --- | --- |
| [English](../../README.md) | [한국어](../ko/README.md) | **現在の文書** |

Shelterは、ユーザーがセキュリティ情報を一つずつ調べなくても、自分の環境に必要な更新を把握して適用できるようにするプロジェクトです。
セキュリティ問題と更新情報は別のWebサイトで提供し、CLIを通じてユーザーのPCの状態確認、通知、更新につなげることを目指しています。

**現在はShelter Liteインストーラーの初期実装段階です。** macOS上で決められた開発ツールをまとめて準備するシェルインストーラーを提供しています。一時環境でのテストと実際のMacでのインストールプレビューは検証済みです。新しいMacでの実際のインストール検証と正式版CLIの実装は今後の作業です。

## 目次

- [背景](#背景)
- [インストール](#インストール)
- [使い方](#使い方)
- [製品構成](#製品構成)
- [ライト版の固定インストール仕様](#ライト版の固定インストール仕様)
- [技術方針](#技術方針)
- [開発計画](#開発計画)
- [リポジトリ構成](#リポジトリ構成)
- [メンテナー](#メンテナー)
- [コントリビュート](#コントリビュート)
- [ライセンス](#ライセンス)

## 背景

新しいセキュリティ問題が公表されても、ユーザー自身が情報を探し、インストール済みのバージョンが影響を受けるかを判断し、更新方法まで調べるのは簡単ではありません。
ツールごとにインストール先や更新方法が異なると、管理の負担も大きくなります。

Shelterは、この流れを**追跡 → 自分の環境との照合 → 通知 → 更新 → 結果確認**としてつなげることを目指しています。
主な対象は、セキュリティアドバイザリや開発ツールに詳しくない一般ユーザーです。何が問題なのか、自分に関係があるのか、次に何をすればよいのかをわかりやすく伝えます。

## インストール

Shelter Liteは、`shelter-lite-macos.zip`を展開して`Shelter Lite.command`をダブルクリックするか、単一の`.sh`ファイルから実行できます。対象は**macOS 15以降、Apple Siliconのネイティブなターミナル環境**で、zshとbashの設定に対応しています。
ローカルでシェルファイルとダブルクリック用ZIPを生成できます。生成、検証、実行の方法は[CONTRIBUTINGの配布](./CONTRIBUTING.md#配布)を参照してください。公開リリースの自動化とHomebrew Tapはまだ構成していません。

リポジトリの取得と実行手順は[CONTRIBUTINGの開発準備](./CONTRIBUTING.md#開発準備)、インストール時に変更される設定は[ライト版の実行](./CONTRIBUTING.md#ライト版の実行)を参照してください。

## 使い方

ライト版を実行すると、**Homebrew → Git → VS Code → Ghostty → Node.js/npm → Python/uv → GitHub CLI**の順に初期環境を準備します。ツールを選択するメニューはありません。正常に実行できる既存のツールは保持し、不足する構成要素をインストールします。通常の画面は**インストール完了またはインストール失敗**と短い案内で終わり、必要な場合にだけ警告を追加します。色が無効でも文言で状態を区別できます。詳細はインストールログに記録し、現在のバージョンと実行ファイルのパスは`--check`で確認できます。

状態ごとの文言と色は[メッセージのプレビュー](./CONTRIBUTING.md#メッセージのプレビュー)、実際のインストール処理の模擬実行は[インストール手順のテスト](./CONTRIBUTING.md#インストール手順のテスト)で確認できます。

以下のセキュリティ情報との連携は、正式版CLIの開発計画です。現時点で実行できる機能ではありません。

```text
Webサイトでセキュリティ問題と更新情報を確認
  → CLIでPC上のソフトウェアとバージョンを確認
  → 自分の環境に関係する更新を通知
  → 必要な更新を適用
  → 適用結果と再起動の必要性を確認
```

更新の自動適用の有無、ユーザーへの確認方法、通知手段は設計段階で決定します。
正式版CLIのコマンドは、実装した動作を検証してから案内します。

## 製品構成

**Webサイト**は、セキュリティ情報と対処方法をユーザーに提供する窓口です。
**情報収集機能**は、公式のセキュリティアドバイザリとリリース情報を追跡する基盤です。
**CLI**は、その情報をユーザーのPCの状態と結び付けるツールです。

| 構成要素 | 計画している役割 | ユーザーに提供する情報 |
| --- | --- | --- |
| Webサイト | セキュリティ問題と更新情報を集め、わかりやすく説明 | 問題の内容、影響を受けるバージョン、対処方法、情報源 |
| 情報収集機能 | セキュリティアドバイザリと更新内容の変更を追跡 | 原文へのリンク、公表日時、最終確認日時 |
| CLI | インストール状態の確認、関連する通知、更新と結果の検証 | 現在の状態、必要な変更、適用結果 |

セキュリティ問題をすばやく把握できるよう、継続的な追跡を目指します。収集間隔と通知までの時間はまだ決めていません。
CodexやClaude Codeなどのツールをまとめてインストール、管理する機能は、今後の拡張として検討します。

**Shelter Lite**は、決められた仕様全体をシェルインストーラーで準備し、結果を確認する初期設定です。個別のツールを選択または除外する機能は提供しません。
**正式版**は、インストール後も状態確認、セキュリティ通知、更新を継続して提供するCLIです。
両バージョンのインストールスクリプトは`installers/macos/`でまとめて管理します。正式版CLI本体はインストーラーと分け、Pythonを採用した場合は`src/shelter/`に実装する予定です。

## ライト版の固定インストール仕様

以下の項目はすべてライト版に含まれます。Homebrewはパッケージマネージャー、Gitはバージョン管理ツール、VS Codeはエディター、Ghosttyはコマンドを入力して実行するターミナルアプリです。Node.jsとPythonは実行環境で、npmとuvはそれぞれの環境を管理するツールです。GitHub CLIはGitHubと連携するためのツールです。

| 順序 | インストール対象 | 役割 | 新規インストール時の方針 |
| --- | --- | --- | --- |
| 1 | [Homebrew](https://docs.brew.sh/Installation) | ソフトウェアをインストールするための基盤 | 公式インストーラーで準備 |
| 2 | [Git](https://formulae.brew.sh/formula/git) | ファイルの変更履歴を管理 | Homebrewの`git`を使用。正常に動作するApple Gitも保持 |
| 3 | [VS Code](https://formulae.brew.sh/cask/visual-studio-code) | ファイルとコードを編集 | Homebrewの`visual-studio-code`を使用。既存の`code`コマンドは保持 |
| 4 | [Ghostty](https://ghostty.org/docs/install/binary) | シェルコマンドを入力して実行するターミナル | Homebrewの`ghostty` caskが提供するバージョンをインストール |
| 5 | [Node.js + npm](https://formulae.brew.sh/formula/node@24) | JavaScriptの実行とパッケージ管理 | `node@24`でNode.js 24.xと同梱のnpmをインストール |
| 6 | [Python + uv](https://docs.astral.sh/uv/guides/install-python/) | Pythonの実行、パッケージと仮想環境の管理 | Homebrewの`uv`を導入し、uvでPython 3.14.xをインストール |
| 7 | [GitHub CLI (`gh`)](https://formulae.brew.sh/formula/gh) | GitHubリポジトリとプルリクエストの操作 | Homebrewの`gh`を使用。ログインは別途実施 |

固定仕様とは、**インストールするツールの組み合わせが決まっていること**を意味します。正常に動作する既存のバージョンは保持し、新規のNode.jsとPythonにだけ上記のバージョン系列を適用します。パッチバージョンまでは固定せず、実際のバージョンとパスは`--check`の結果で確認します。GitHub Desktopは含みません。

macOS開発ツールの`/usr/bin/python3`は、ユーザー用Pythonと区別します。新しいPythonはuvが管理する`python3.14`として提供し、システムのPythonや既存のバージョン管理ツールの既定コマンドは変更しません。VS Codeはアプリのパスから確認するため、Cursorの`code`コマンドをVS Codeと判定することはありません。

実行できるかどうかの確認は、脆弱性検査や最新バージョンの判定ではありません。インストールと再実行の詳細な方針は[CONTRIBUTING](./CONTRIBUTING.md#ライト版の実行)に記載しています。

## 技術方針

**初期のシェルインストーラーとCLIの対象OSはmacOSです。** Windows向けのインストール、シェル設定、更新、検証は現在の対象に含みません。
ライト版はmacOS標準のBashで実行し、Node.jsやPythonを事前にインストールする必要はありません。正式版CLIとWebサイトの技術はまだ検討段階です。

| 領域 | 検討している技術 | 役割 | 状態 |
| --- | --- | --- | --- |
| 初期の対象OS | ![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?style=flat-square&logo=apple&logoColor=white) | ライト版のインストールとシェル設定 | Apple Silicon、zsh/bash。Intel、Rosetta、Windowsは対象外 |
| Webサイトと情報収集 | 未定 | セキュリティ情報の収集、参照、ユーザー画面 | 技術選定前 |
| CLI本体 | ![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white) | 状態確認、通知、更新処理 | 優先候補。バージョンは未定 |
| CLI開発ツール | ![Typer](https://img.shields.io/badge/Typer-009688?style=flat-square&logo=typer&logoColor=white) ![uv](https://img.shields.io/badge/uv-DE5FE9?style=flat-square&logo=uv&logoColor=white) | コマンド構成、Python環境と依存関係の管理 | 候補。バージョンは未定 |
| Shelter Lite | ![Bash 3.2.57](https://img.shields.io/badge/Bash-3.2.57-4EAA25?style=flat-square&logo=gnubash&logoColor=white) | 固定仕様の初回インストールと実行環境の準備 | 実装済み。Bash 3.2.57で検査 |
| macOSでの配布 | ![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?style=flat-square&logo=homebrew&logoColor=black) | CLIのインストールとCLI自体の更新 | 配布方法の候補 |

サポート条件とインストール方針の実装は[install.sh](../../installers/macos/install.sh)と[tools.sh](../../installers/macos/tools.sh)にあります。OSの最低要件は[Homebrewのインストール要件](https://docs.brew.sh/Installation)に基づいて制限しています。現在の実機確認はmacOS 26.6.2でのプレビューまでで、サポート範囲全体での実際のインストールを検証したものではありません。

## 開発計画

1. **Shelter Liteの検証:** 環境確認、固定仕様のインストール、結果確認は実装済みです。新しいMacでのインストール、ターミナルの再起動、再実行を検証してから配布します。
2. **CLIの連携:** PCのインストール状態と別のWebサイトのセキュリティ情報を結び付け、その環境に関係する更新を通知します。
3. **更新と拡張:** 適用結果の確認と失敗時の対応を実装し、ツールの統合インストールを拡張します。

ライト版は初期設定から始め、正式版CLIはその後に拡張します。詳細な機能範囲と自動更新方針は未定です。
両バージョンはこのリポジトリで管理します。Webサイトのコードは含みません。

## リポジトリ構成

### 現在の構成

現在作成されているディレクトリ、実行コード、ドキュメントは次のとおりです。

```text
shelter/
├── dist/             # 生成結果、Git管理対象外
│   ├── shelter-lite-macos.sh
│   ├── shelter-lite-macos.sh.sha256
│   ├── shelter-lite-macos.zip
│   └── shelter-lite-macos.zip.sha256
├── installers/
│   └── macos/        # ライト版と将来の正式版のmacOSインストーラー
│       ├── build.sh   # シェルファイルとダブルクリック用ZIPを生成
│       ├── install.sh # エントリーポイント、固定仕様、インストール順序
│       ├── messages.sh # 英語メッセージ、エラー文言、色と出力形式
│       ├── tools.sh   # ツールの確認、インストール、シェル設定
│       └── tests/
│           └── test.sh # 一時環境で実行するインストーラーテスト
├── language/
│   ├── ko/
│   │   ├── README.md       # 韓国語の製品紹介、構成、開発方針
│   │   └── CONTRIBUTING.md # 韓国語の開発準備、検証、貢献手順
│   └── jp/
│       ├── README.md       # 日本語の製品紹介、構成、開発方針
│       └── CONTRIBUTING.md # 日本語の開発準備、検証、貢献手順
├── README.md         # 英語の製品紹介、構成、開発方針
├── CONTRIBUTING.md   # 英語の開発準備、検証、貢献手順
└── LICENSE           # MITライセンス
```

### 各構成要素の役割

[messages.sh](../../installers/macos/messages.sh)は、インストーラーとテストが共有する英語の案内、警告、エラー、ヘルプとターミナルの出力形式を一元管理するファイル（SSOT）です。失敗の判定、インストールの中断と終了コードは`install.sh`と`tools.sh`で管理します。

[build.sh](../../installers/macos/build.sh)は、実行用ソースとMITライセンスを`dist/shelter-lite-macos.sh`にまとめます。生成ファイルにも同じメッセージとインストール処理を含めます。変更は元のソースに加え、再生成してください。 同じ実行ファイルを`Shelter Lite.command`という名前で`dist/shelter-lite-macos.zip`に格納し、Terminalで開ける形式でも提供します。

ライト版は`install.sh`で固定仕様全体のインストールを開始し、`tools.sh`の関数を呼び出します。正式版を提供する際も、同じエントリーポイントに正式版CLIのインストール処理を接続する予定です。現在の`--mode full`は準備中の案内を表示して終了します。バージョン別やツール別のインストールディレクトリは事前に分割しません。

正式版CLI本体の予定位置である`src/shelter/`は、Pythonでの実装を始める際に追加します。Webサイト、情報収集サービス、共通データ形式の構成は連携範囲が決まってから検討し、現在のインストーラー構成には含めません。
共通コードやツール固有の処理が実際に増えたときにファイルを分割し、CIと詳細ドキュメントも必要になった時点で追加します。
ディレクトリを作成するタイミングと文書の更新手順は、[CONTRIBUTINGのディレクトリの追加と変更](./CONTRIBUTING.md#ディレクトリの追加と変更)に従ってください。

## メンテナー

[@4BFC](https://github.com/4BFC)

## コントリビュート

ドキュメントの改善、機能提案、プルリクエストを歓迎します。
質問や提案は[Issues](https://github.com/4BFC/shelter/issues)に投稿してください。大きな機能や技術の選定については、実装前に相談してください。

作業の準備、検証、変更の提出基準は[CONTRIBUTING](./CONTRIBUTING.md)を参照してください。

## ライセンス

[MIT](../../LICENSE) © 2026 poby
