# Shelter 技術仕様

[English](./specification.md) · [한국어](./specification.ko.md) · [日本語](./specification.jp.md)

[README](../language/jp/README.md)

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
インストールスクリプトはOS別に`installers/macos/`と`installers/windows/`で管理します。正式版CLI本体はインストーラーと分け、Pythonを採用した場合は`src/shelter/`に実装する予定です。

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

実行できるかどうかの確認は、脆弱性検査や最新バージョンの判定ではありません。インストールと再実行の詳細な方針は[CONTRIBUTING](../language/jp/CONTRIBUTING.md#ライト版の実行)に記載しています。

## Windowsの固定ツール構成

パッケージIDは[Microsoft WinGetのmanifestリポジトリ](https://github.com/microsoft/winget-pkgs/tree/master/manifests)を基準とし、パッチバージョンはインストール時のソースに従います。

| 順番 | ツール | 役割 | 新規インストール方針 |
| --- | --- | --- | --- |
| 1 | WinGet | パッケージ管理 | 未導入時は現在のユーザー向けMicrosoft.WinGet.Clientで修復 |
| 2 | Git | バージョン管理 | WinGet Git.Git |
| 3 | VS Code | エディター | WinGet Microsoft.VisualStudioCode、ユーザースコープ |
| 4 | Windows Terminal | ターミナル | WinGet Microsoft.WindowsTerminal |
| 5 | Node.js + npm | JavaScript実行 | OpenJS.NodeJS.LTSの24.xから最新を選び正確なバージョンで導入 |
| 6 | Python + uv | Python実行と環境管理 | WinGet astral-sh.uv、その後uv python install 3.14 |
| 7 | GitHub CLI | GitHub連携 | WinGet GitHub.cli、ログインは手動 |

動作する既存バージョンは保持します。LTSパッケージの最新メジャーが上がっても新規Node.jsは24.xに限定します。StoreのPythonエイリアスはインストール済みと判定しません。Node/npmの部分インストールや実行エラーでは停止し、Python/uvは不足分のみ補います。ユーザーPATHをバックアップして不足する実行パスだけを末尾に追加します。システムPATH、プロファイル、ターミナル設定、Gitユーザー情報、認証は保持します。両OSとも英語メッセージと共通のオプション名を使います。Windowsの処理は[install.ps1](../installers/windows/install.ps1)と[tools.ps1](../installers/windows/tools.ps1)に実装しています。

## 技術方針

**Shelter Lite 0.2.0はmacOSとWindowsのインストーラーを個別に提供します。** macOSはmacOS 15以降とネイティブApple Silicon、WindowsはWindows 11 x64と標準64ビットWindows PowerShell 5.1が対象です。[Windowsの実装と実機検証項目](plans/windows-lite.md)を参照してください。Windows 10、Windows Server、ARM64、32ビットプロセスは今回のWindows版の対象外です。
ライト版はmacOS標準のBashまたはWindows標準のPowerShellを使い、Node.jsやPythonの事前インストールは不要です。正式版CLIとWebサイトの技術は引き続き検討中です。

| 領域 | 検討している技術 | 役割 | 状態 |
| --- | --- | --- | --- |
| macOS | ![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?style=flat-square&logo=apple&logoColor=white) | ライト版のインストールとシェル設定 | Apple Silicon、zsh/bash。Intel、Rosettaは対象外 |
| Windows | ![Windows 11 x64](https://img.shields.io/badge/Windows-11_x64-0078D4?style=flat-square) | 固定ライト版の設定、WinGet、ユーザーPATH | x64とWindows PowerShell 5.1を実装、クリーンPCでの実機検証は未完了 |
| Webサイトと情報収集 | 未定 | セキュリティ情報の収集、参照、ユーザー画面 | 技術選定前 |
| CLI本体 | ![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white) | 状態確認、通知、更新処理 | 優先候補。バージョンは未定 |
| CLI開発ツール | ![Typer](https://img.shields.io/badge/Typer-009688?style=flat-square&logo=typer&logoColor=white) ![uv](https://img.shields.io/badge/uv-DE5FE9?style=flat-square&logo=uv&logoColor=white) | コマンド構成、Python環境と依存関係の管理 | 候補。バージョンは未定 |
| Shelter Lite | ![Bash 3.2.57](https://img.shields.io/badge/Bash-3.2.57-4EAA25?style=flat-square&logo=gnubash&logoColor=white) | 固定仕様の初回インストールと実行環境の準備 | 実装済み。Bash 3.2.57で検査 |
| macOSでの配布 | ![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?style=flat-square&logo=homebrew&logoColor=black) | CLIのインストールとCLI自体の更新 | 配布方法の候補 |

サポート条件とインストール方針の実装は[install.sh](../installers/macos/install.sh)と[tools.sh](../installers/macos/tools.sh)にあります。OSの最低要件は[Homebrewのインストール要件](https://docs.brew.sh/Installation)に基づいて制限しています。現在の実機確認はmacOS 26.6.2でのプレビューまでで、サポート範囲全体での実際のインストールを検証したものではありません。

## 開発計画

1. **Shelter Liteの検証:** 環境確認、固定仕様のインストール、結果確認は実装済みです。新しいMacでのインストール、ターミナルの再起動、再実行を検証してから配布します。
2. **CLIの連携:** PCのインストール状態と別のWebサイトのセキュリティ情報を結び付け、その環境に関係する更新を通知します。
3. **更新と拡張:** 適用結果の確認と失敗時の対応を実装し、ツールの統合インストールを拡張します。

ライト版は初期設定から始め、正式版CLIはその後に拡張します。詳細な機能範囲と自動更新方針は未定です。
両バージョンはこのリポジトリで管理します。Webサイトのコードは含みません。

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

## リポジトリ構成

### 現在の構成

現在作成されているディレクトリ、実行コード、ドキュメントは次のとおりです。

```text
shelter/
├── .github/
│   └── workflows/
│       ├── validate.yml # macOS / Windows
│       └── release.yml # リリースの検査、パッケージング、ファイル添付
├── docs/
│   ├── specification.md
│   ├── specification.ko.md
│   ├── specification.jp.md
│   └── plans/
│       ├── readme-usage.md # README使い方中心の整理計画
│       └── windows-lite.md # Windowsの実装と実機検証項目
├── dist/             # 生成結果、Git管理対象外
│   ├── shelter-lite-macos.sh
│   ├── shelter-lite-macos.sh.sha256
│   ├── shelter-lite-macos.zip
│   ├── shelter-lite-macos.zip.sha256
│   ├── shelter-lite-windows.ps1
│   ├── shelter-lite-windows.ps1.sha256
│   ├── shelter-lite-windows.zip
│   ├── shelter-lite-windows.zip.sha256
│   └── VERSION
├── installers/
│   ├── macos/        # ライト版と将来の正式版のmacOSインストーラー
│   │   ├── build.sh   # シェルファイルとダブルクリック用ZIPを生成
│   │   ├── install.sh # エントリーポイント、固定仕様、インストール順序
│   │   ├── messages.sh # 英語メッセージ、エラー文言、色と出力形式
│   │   ├── tools.sh   # ツールの確認、インストール、シェル設定
│   │   └── tests/
│   │       └── test.sh # 一時環境で実行するインストーラーテスト
│   └── windows/
│       ├── build.ps1
│       ├── install.ps1
│       ├── launch.cmd
│       ├── messages.ps1
│       ├── tools.ps1
│       └── tests/
│           └── test.ps1
├── scripts/
│   ├── version.ps1
│   └── version.sh    # 製品バージョンの形式検証とファイル読み込み
├── language/
│   ├── ko/
│   │   ├── README.md       # 韓国語のインストールと使い方
│   │   └── CONTRIBUTING.md # 韓国語のメンテナー向け開発、リリースガイド
│   └── jp/
│       ├── README.md       # 日本語のインストールと使い方
│       └── CONTRIBUTING.md # 日本語のメンテナー向け開発、リリースガイド
├── README.md         # 英語のインストールと使い方
├── CONTRIBUTING.md   # 英語のメンテナー向け開発、リリースガイド
├── VERSION           # 製品バージョンの単一管理元
└── LICENSE           # MITライセンス
```

### 各構成要素の役割

Windowsは[messages.ps1](../installers/windows/messages.ps1)をインストーラー、ビルド、テスト共通のメッセージSSOTにします。[build.ps1](../installers/windows/build.ps1)は実行ソース、MITライセンス、ルートの`VERSION`を単一の`.ps1`に含め、ZIPには`.cmd`ランチャーと`VERSION`を追加します。[version.ps1](../scripts/version.ps1)と`version.sh`はインストーラーから独立して同じ製品バージョン規約を実装します。

Windowsのロジックとパッケージングは隔離テストで確認します。実際のWindows 11へのインストール、WinGet修復、UAC、ダウンロードしたファイルの実行はクリーンな実機での追加検証が必要です。CIはWindows標準のPowerShell 5.1で検査します。Windows Server runnerはモックテスト用であり、インストール対象ではありません。

[messages.sh](../installers/macos/messages.sh)は、macOSのインストーラーとテストが共有する英語の案内、警告、エラー、ヘルプとターミナルの出力形式を一元管理するファイル（SSOT）です。失敗の判定、インストールの中断と終了コードは`install.sh`と`tools.sh`で管理します。

[build.sh](../installers/macos/build.sh)は、実行用ソースとMITライセンスを`dist/shelter-lite-macos.sh`にまとめます。生成ファイルにも同じメッセージとインストール処理を含めます。変更は元のソースに加え、再生成してください。 同じ実行ファイルを`Shelter Lite.command`という名前で`dist/shelter-lite-macos.zip`に格納し、Terminalで開ける形式でも提供します。

ライト版は`install.sh`で固定仕様全体のインストールを開始し、`tools.sh`の関数を呼び出します。正式版を提供する際も、同じエントリーポイントに正式版CLIのインストール処理を接続する予定です。現在の`--mode full`は準備中の案内を表示して終了します。バージョン別やツール別のインストールディレクトリは事前に分割しません。

正式版CLI本体の予定位置である`src/shelter/`は、Pythonでの実装を始める際に追加します。Webサイト、情報収集サービス、共通データ形式の構成は連携範囲が決まってから検討し、現在のインストーラー構成には含めません。
共通コードやツール固有の処理が実際に増えたときにファイルを分割します。リリースworkflowで対象バージョンを検証してパッケージングし、追加の検査と詳細ドキュメントは機能に応じて拡張します。
ディレクトリを作成するタイミングと文書の更新手順は、[CONTRIBUTINGのディレクトリの追加と変更](../language/jp/CONTRIBUTING.md#ディレクトリの追加と変更)に従ってください。

## コマンドリファレンス

| オプション | 動作 |
| --- | --- |
| オプションなし | ライト版全体の初期設定 |
| `--dry-run` | インストール計画の確認のみ。ダウンロードと設定変更は行わない |
| `--check` | 全ツールの実行状態の確認。ダウンロードと設定変更は行わない |
| `--version`, `-V` | 環境を変更せずにShelter Liteの製品バージョンを表示 |
| `--mode lite` | 既定の動作と同じ |
| `--mode full` | 準備中の案内を表示して終了。インストールは行わない |
| `--color auto\|always\|never` | 自動カラー、常にカラー（既定）、または色なしの出力 |
| `--color` | 今回の実行で色を強制する。`--color always`と同じ |
| `--help` | ヘルプを表示 |

終了コードは成功が`0`、未インストールまたは実行・インストールエラーが`1`、不正なオプションや未対応環境が`2`、Ctrl+Cによる中断が`130`です。`--check`と`--dry-run`は同時に使えません。正常に計画を作成できれば、不足するツールがあってもプレビューは`0`で終了します。

Ctrl+Cの`130`はmacOSに適用され、Windowsの中断はPowerShell/CMDホストに従います。`0`、`1`、`2`は両OSで共通です。
