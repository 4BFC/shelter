# 開発とメンテナンス

<div align="center">
<table align="center">
  <tr>
    <td align="center"><a href="../../CONTRIBUTING.md"><img src="https://img.shields.io/badge/English-555555?style=flat-square" alt="English"></a></td>
    <td align="center"><a href="../ko/CONTRIBUTING.md"><img src="https://img.shields.io/badge/%ED%95%9C%EA%B5%AD%EC%96%B4-555555?style=flat-square" alt="한국어"></a></td>
    <td align="center"><a href="CONTRIBUTING.md"><img src="https://img.shields.io/badge/%E6%97%A5%E6%9C%AC%E8%AA%9E-0969DA?style=flat-square" alt="日本語"></a></td>
  </tr>
</table>
</div>

Shelterのメンテナー向けに、開発、ドキュメント作成、検証、リリースの手順を説明します。
製品の目的、構成、技術方針は[日本語README](./README.md)を参照してください。

現在はmacOSとWindows向けShelter Lite、隔離されたテスト、スクリプトとダブルクリック用ZIPのパッケージング、リリースの自動ビルドを提供しています。正式版CLIはまだ準備前です。

## 目次

- [コントリビューション方針](#コントリビューション方針)
- [開発準備](#開発準備)
- [ライト版の実行](#ライト版の実行)
- [Windowsライト版](#windowsライト版)
- [ディレクトリの追加と変更](#ディレクトリの追加と変更)
- [作業手順](#作業手順)
- [ドキュメントの作成](#ドキュメントの作成)
- [実装と検証](#実装と検証)
- [コミットと公開](#コミットと公開)
- [配布](#配布)

## コントリビューション方針

現在、外部からのプルリクエストとIssueは受け付けておらず、両機能を無効にしています。開発方針の決定とリリースは、リポジトリへの書き込み権限を持つメンテナーが担当します。

ソフトウェアには引き続き[MITライセンス](../../LICENSE)が適用されます。この方針は、ライセンスで許可された利用、改変、再配布を制限するものではありません。

メンテナーは技術選定、対応OSの追加、大きな機能追加の範囲を実装前に決め、次の内容を記録します。

- どのようなユーザーが、どのような状況で困っているか
- 期待する動作と現在の動作の違い
- 関連する公表情報、再現手順、参考資料

セキュリティアドバイザリとShelter自体の不具合は区別してください。再現資料にトークン、認証情報、個人のパスが含まれる場合は、削除してから共有してください。

## 開発準備

### リポジトリの取得

Gitがある場合は、次のようにリポジトリを取得してルートディレクトリに移動します。取得済みの場合は、この手順を省略してください。

```bash
git clone https://github.com/4BFC/shelter.git
cd shelter
git status --short
```

macOSまたはWindowsにGitがない場合は、GitHubの**Code → Download ZIP**でソース全体を取得して展開し、ルートディレクトリへ移動します。ルートの`VERSION`、`scripts/`、対象OSの`installers/macos/`または`installers/windows/`を一緒に保持してください。

各単一インストーラーは必要な実行モジュールと製品バージョンを内部に含みます。パッケージングは[配布](#配布)、Windowsコマンドは[Windowsライト版](#windowsライト版)を参照してください。

### 実行環境

macOSインストーラーの対象は**macOS 15以降、Apple Silicon、zshまたはbash**です。Intel、Rosetta、Windowsではインストールせずに終了します。macOS標準の`/bin/bash`で実行し、Bash 3.2.57で検査しています。PythonやNode.jsを事前に準備する必要はありません。

インストールにはインターネット接続とHomebrewのインストール権限が必要です。公式のHomebrewインストーラーが、管理者認証とXcode Command Line Toolsのインストールを要求する場合があります。**スクリプト全体を`sudo`で実行しないでください。** [Homebrewのインストール要件](https://docs.brew.sh/Installation)を参照してください。

正式版CLIはまだ実装していません。今後、実行時の依存関係を追加する際は、バージョン、依存関係の宣言、ロックファイル、実行コマンドをまとめて記録します。

## ライト版の実行

以下のコマンドはすべてリポジトリのルートで実行します。まず、変更を加えずに計画を確認できます。

```bash
/bin/bash installers/macos/install.sh --dry-run
```

初期設定を開始するコマンドは次のとおりです。ツールの選択や除外は行わず、[ライト版の固定インストール仕様](../../docs/specification.jp.md#ライト版の固定インストール仕様)全体を準備します。

```bash
/bin/bash installers/macos/install.sh
```

インストールと`--dry-run`の開始時に、Shelter LiteのASCIIロゴを1回表示します。 通常の画面では、初期設定の開始と最終的な**インストール完了またはインストール失敗**を要約し、短い説明と次の操作を表示します。HomebrewがないMacでは、公式の初回インストーラーによる確認と管理者認証の案内をターミナルに直接表示します。

| メッセージ | 表示する内容 |
| --- | --- |
| `● note:` | 初期設定の開始、失敗後のログ確認と再実行の案内 |
| `● success:` | 開発ツールの準備が完了したことの説明 |
| `● error:` | インストールや設定を完了できなかった理由 |
| `● warning:` | 新しい実行パスの反映待ち、失敗後も実施済みのインストールや設定変更が残ることの案内 |

警告は該当する状況でのみ表示します。新しい実行パスがなければ反映待ちの警告を省略し、インストールやシェル設定を始める前に中断した場合は、変更が残るという警告も省略します。色を無効にしても、メッセージの分類と本文は表示されます。

最終結果は、区切り線を使わず見出しとメッセージで表示します。メッセージの先頭に`●`を付け、接頭辞は角括弧を使わず、英小文字とコロンで表示します。プレビュー、インストール手順のテスト、実際のインストーラーのメッセージ、結果見出し、ヘルプ、ログは英語で表示します。**通常のメッセージでは`●`にだけ状態の色を付け、接頭辞と本文はターミナルの既定色を使用します。** 成功は緑、失敗とエラーは赤、案内はシアン、警告は黄です。`Installation complete`（インストール完了）、`Installation failed`（インストール失敗）、`Check required`（確認が必要）などの結果見出しには、文字全体に状態の色を付けます。通常の見出しと詳細表の本文には色を指定せず、表も各行の先頭の`●`で状態の色を示します。

セクションの見出し、表のヘッダー、インストール予定の項目と設定パスは、従来のインデントを`PUAアイコン + 空白1文字`に置き換えます。アイコンは[Nerd Fonts v3.5.0](https://github.com/ryanoasis/nerd-fonts/blob/v3.5.0/glyphnames.json)のFont Awesomeマッピングを基準に、`messages.sh`の`shelter_icon`で管理します。表示には、該当のマッピングをサポートするターミナルフォントまたは代替フォントが必要です。状態メッセージとツール行の既存の`●`、色、間隔は維持します。

インストーラーとテストは、`--dry-run`と`--check`を含め、既定で色を使用します。色のオプションを追加する必要はなく、ターミナル自体の設定も変更しません。

```bash
/bin/bash installers/macos/install.sh
```

既定の`always`は、`NO_COLOR`、`TERM=dumb`、出力のリダイレクトに関係なく色を出力します。ターミナルの判定と`NO_COLOR`に従う場合は`--color auto`、色を無効にする場合は`--color never`を指定します。出力ビューアーがANSIカラーに対応していない場合、`always`を指定しても色が表示されないことがあります。

インストーラーとテストは、値のない`--color`も引き続きサポートし、現在の既定値である`--color always`と同じ動作になります。インストール計画も追加オプションなしで色付きで確認できます。

```bash
/bin/bash installers/macos/install.sh --dry-run
```

結果とインストール後の作業は[READMEの使い方](./README.md#使い方)、全オプションと終了コードは[コマンドリファレンス](../../docs/specification.jp.md#コマンドリファレンス)を参照してください。リポジトリから状態を確認する場合は`/bin/bash installers/macos/install.sh --check`を使用します。

インストールログは所有者だけが読み書きでき、カラーコードは含みません。

### 既存環境と再実行

- 正常に動作する既存ツールは、再インストールやバージョンを合わせるための直接のアップグレードを行いません。新しいNode.jsには`node@24`、新しいPythonにはuvの`3.14`系列を使用します。パッチバージョンとその他のツールのバージョンは、インストール時にパッケージマネージャーが提供するものに従います。
- Node.jsとnpmの片方だけがある場合や、既存コマンドの実行に失敗する場合は、変更前に中断します。Pythonとuvは、不足する構成要素だけをインストールできます。`/usr/bin/python3`はmacOS開発ツール用として保持し、別のユーザー用Pythonを準備します。
- uvによるPythonの検索は、ネットワークと既存のキャッシュを使用しません。検索エラーは`Check required`（確認が必要）として表示し、正常な検索でインストール済みPythonが見つからない場合にだけインストール対象と判断します。
- VS Codeは`/Applications`またはユーザーの`~/Applications`にあるアプリで確認します。[Homebrewの`--no-binaries`](https://docs.brew.sh/Manpage)でアプリをインストールし、既存の`code`コマンドがCursorなど別のエディターに接続されていれば保持します。その場合は、アプリケーションフォルダーからVS Codeを起動してください。
- Ghosttyは`PATH`に`ghostty`コマンドがなくても、`/Applications/Ghostty.app`または`~/Applications/Ghostty.app`で確認します。正常に動作するアプリは保持し、なければ`brew install --cask ghostty`でインストールします。アプリが破損している場合やバージョン確認に失敗した場合は中断します。Ghosttyの設定、フォント、既定のターミナルは変更しません。

ユーザー設定と再実行手順は[READMEの使い方](./README.md#使い方)を参照してください。エラーが発生すると後続の処理を止め、完了済みの変更は残ります。新しいパッケージに必要な依存関係の変更はHomebrewが処理します。

個々の`brew install`には、自動更新、インストール後のクリーンアップ、既存のインストール対象の自動アップグレードを無効にする環境変数を適用します。依存関係の互換性処理はHomebrewに任せます。関連する動作は[Homebrewのコマンドドキュメント](https://docs.brew.sh/Manpage)を基準とします。

### シェル設定とバックアップ

必要な実行パスを現在の`PATH`の末尾に追加し、nvm、mise、pyenvなどの既存設定の優先順位を保持します。追加したパスがある場合は次の場所に保存し、シェル設定に一度だけ読み込み処理を追加します。

| ファイル | 変更内容 |
| --- | --- |
| `${XDG_CONFIG_HOME:-$HOME/.config}/shelter/env.sh` | Shelterが追加した実行パス。既存のユーザー独自の設定ファイルは上書きしない |
| `${ZDOTDIR:-$HOME}/.zshrc` | zshユーザー向けの環境ファイル読み込み処理 |
| `$HOME/.bashrc`, `$HOME/.bash_profile` | bashユーザー向けの環境ファイル読み込み処理 |

既存ファイルを変更する前に、環境ファイルと同じディレクトリに`env.sh.backup.*`または`shell.backup.*`としてバックアップし、そのパスをインストールログに記録します。シェル設定は既存の内容を保持し、読み込み処理を追記します。エラーにより一部の設定しか反映されなかった場合も、完了済みの変更とバックアップは残ります。

新しいターミナルを開くとパス設定が反映されます。現在のターミナルにすぐ反映したい場合は、インストールログに記録された`source`コマンドを実行してください。実行中のエディターは、新しい環境を使うために再起動が必要です。新しいPythonは[uvのバージョン別実行ファイルの方針](https://docs.astral.sh/uv/guides/install-python/)に従って`python3.14`として提供し、システムの`python3`や`python`は置き換えません。

バックアップからの復元が必要な場合は、ログに記録された元のパスとバックアップを比較してから復元してください。他のシェル設定を保持したい場合は、`# Shelter Lite`が付いた読み込み処理だけを削除することもできます。この操作でインストール済みのプログラムが削除されることはありません。

## Windowsライト版

リポジトリのルートでPowerShellから次を実行します。Windows 11 x64、ネイティブ64ビットのWindows PowerShell 5.1が対象です。管理者として起動せず、個別パッケージのUAC認証に応答します。Node.jsやPythonの事前インストールは不要です。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/install.ps1 --dry-run
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/install.ps1 --check
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/install.ps1 --version
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/tests/test.ps1 -Color never
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/tests/test.ps1 -Preview warning
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/tests/test.ps1 -Install failure
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/build.ps1
```

オプションなしの`install.ps1`はWindowsの固定仕様全体をインストールします。`--dry-run`、`--check`、`--version`、`--mode lite`、`--color`と終了コードはmacOSと共通です。Ctrl+Cはホスト標準の中断動作に従います。`-Preview`は`notification`、`warning`、`failure`、`success`を、`-Install`は`success`、`failure`、`dry-run`を受け付けます。実行フローのテストは一時ファイルとモックのみを使い、ツールを実際にはインストールしません。

`messages.ps1`はインストール、ビルド、テストが共有するWindowsメッセージのSSOTです。macOSと同じ英語の接頭辞、状態ドットの色、結果の見出し、PUAアイコン、既定の`always`カラーポリシーを使い、Bashを必要としません。`scripts/version.ps1`は`version.sh`と同じSemVer規約でルートの`VERSION`を読みます。

WinGetがない場合はPowerShell Gallery経由の公式の現在のユーザー向け`Microsoft.WinGet.Client`修復手順を使います。パッケージIDとWindows固有の方針は技術仕様に記載します。ソースとパッケージの利用規約に同意し、正確なID、`winget`ソース、`--no-upgrade`を使用します。Node.jsは最新のメジャーをそのまま使わず、提供される24.xから選びます。動作する既存バージョンは保持し、Node/npmの部分インストールや実行エラーは事前検査で停止します。StoreのPythonエイリアスは除外します。Pythonとuvは不足分だけを補い、uvの探索はオフライン、新規Pythonは`3.14`を使います。

元のユーザーPATHをACLで保護したJSONにバックアップしてから、不足パスだけを末尾へ追加します。既存の変数参照とレジストリ値の型を保持します。システムPATHとPowerShellプロファイルは編集しません。`%LOCALAPPDATA%\Shelter\logs`のログとPATHバックアップは現在のユーザーとSYSTEMだけがアクセスできます。セットアップ後にターミナルとエディターを再起動し、Gitユーザー情報とGitHub認証は手動で設定します。

ビルドは`dist/`に`shelter-lite-windows.ps1`、`shelter-lite-windows.zip`、各`.sha256`、`VERSION`を生成します。ZIPには`Shelter Lite.cmd`、単一の`.ps1`、`VERSION`が入ります。実行ファイル2つを同じフォルダーに置いてください。`.ps1`には製品バージョンとMITライセンスを埋め込みます。同じツール環境で再現できるようZIPの時刻を固定します。出力先は`build.ps1 -OutputDirectory "C:\path with spaces"`で変更できます。

ランチャーはプロファイルを読み込まず標準64ビットWindows PowerShellを起動し、実行ポリシーを当該プロセスだけに指定します。終了コードを保持し、引数なしの場合だけ終了時に待機します。組織のポリシーは回避しません。スクリプトは未署名です。隔離テストはSmartScreen、App Installer修復、UAC、クリーンなWindows 11 PCでの全体のインストール検証に代わるものではありません。`v0.2.0`の公開前に実機検証項目を完了してください。

### MacでWindowsの動作をテスト

[Microsoftのインストールまたはバイナリアーカイブ手順](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-macos)に従い、macOS用PowerShell 7を準備します。リポジトリのルートで次を実行してください。`pwsh`がPATHに必要です。アーカイブを展開した場合は、`pwsh`を引用符で囲んだ実行ファイルの絶対パスに置き換えます。以前のセッションの一時パスは永続的な実行環境ではありません。

```bash
pwsh -NoProfile -File installers/windows/tests/test.ps1 -Color never
pwsh -NoProfile -File installers/windows/tests/test.ps1 -Preview warning
pwsh -NoProfile -File installers/windows/tests/test.ps1 -Install success
pwsh -NoProfile -File installers/windows/tests/test.ps1 -Install failure
pwsh -NoProfile -File installers/windows/tests/test.ps1 -Install dry-run
```

Windows環境、パッケージの導入、レジストリ操作、ログ権限はモック化し、一時ファイルのみを使うため、実際のツールやユーザー設定は変更しません。`-Install failure`は想定したインストール失敗を確認するとテスト終了コード`0`を返します。メッセージのプレビューは指定した状態の表示だけを確認します。

ここではMacのPowerShell 7でロジックを確認します。実際のWindowsインストーラーの対象はWindows PowerShell 5.1です。WinGetの準備、UAC、Windows権限、`.cmd`実行はWindowsでの検証が必要です。macOSで`install.ps1`を直接実行すると非対応環境として終了します。

## ディレクトリの追加と変更

全体の配置と各パスの役割は、[技術仕様のリポジトリ構成](../../docs/specification.jp.md#リポジトリ構成)を基準とします。
macOSの実行コードは`install.sh`、`messages.sh`、`scripts/version.sh`、`tools.sh`とルートの`VERSION`で構成し、`build.sh`でパッケージングします。`tests/test.sh`で元のソースと単一配布ファイルを検証します。`dist/`は生成結果を格納し、Git管理対象から除外します。以降のパスは、機能を実装する際に必要な分だけ追加します。

1. **ライト版のインストール処理を管理します。** `installers/macos/install.sh`に環境確認、固定仕様、インストール順序を置き、`tools.sh`にツールごとの状態確認、インストール、シェル設定の関数を置きます。`lib/`、`tools/`、`profiles/`などの別ディレクトリは、実際に分割が必要になったときに検討します。
2. **正式版のインストールを接続します。** 正式版CLIと配布物が用意できたら、同じ`install.sh`の`full`モードに処理を追加し、ツールのインストール関数を再利用します。現在は準備中の案内を表示して終了します。
3. **正式版CLI本体は別に実装します。** Pythonパッケージのひな形は`src/shelter/`、管理ツール別の照会処理は`src/shelter/providers/`、CLIテストはルートの`tests/`に置きます。開発環境と依存関係はuvで管理する方針です。現在はパッケージを示すファイルとテストディレクトリを保持するファイルのみで、ルートの`pyproject.toml`、`uv.lock`、実行環境と依存関係のバージョン、コマンド、CLIテストは未実装です。現時点でCLIのインストールや実行コマンドはありません。リポジトリのルートで作業し、実装と検証の順序は[CLIの検出と更新情報の計画](../../docs/plans/shelter-cli.md)に従ってください。Liteのインストール処理は既存のOS別インストーラーに残し、将来のCLIから呼び出します。継続的なセキュリティ通知と更新管理機能をインストーラーに重複実装しないでください。

シェルインストーラーのテストは`installers/macos/tests/`で管理します。バージョン別の動作を追加するときは、共通のインストール処理と各バージョンの動作を確認し、実際の実行場所とコマンドをこの文書に記録します。
Webサイトはこのリポジトリの外で管理します。情報収集サービスとデータ形式は、連携範囲を決めた後に構成を検討します。Windowsのスクリプト、ランチャー、テスト、パッケージングは`installers/windows/`で管理します。[Windowsの実装と実機検証項目](../../docs/plans/windows-lite.md)を参照してください。

構成を追加または変更するときは、次の内容を同じ変更に含めてください。

- 技術仕様の**現在の構成**に実際に追加したパスを反映し、**各構成要素の役割**に残っている範囲を記載する。
- CONTRIBUTINGに、その構成要素のインストール、実行、検証コマンドを作業ディレクトリとともに記録する。
- 詳細設計や別の計画書が必要になったら`docs/`に追加し、関連文書からリンクする。文書分類用のサブディレクトリを先に作らない。

ライト版と正式版のインストーラーは同じ場所で管理し、インストーラーと正式版CLI本体の責務を分けます。Homebrewで配布する場合は、FormulaとTapの管理場所を配布手順の中で別途定めます。

## 作業手順

1. READMEで使い方を、`docs/`の技術仕様で現在の実装範囲を確認します。
2. 変更内容を決め、作業ブランチを作成します。
3. 関連するドキュメントとコードを一緒に修正します。
4. 以下の検証基準に従って確認し、diffをレビューします。
5. 変更の目的と検証結果を記録し、メンテナーの承認に従ってコミットとpushを行います。

作業ブランチ名の例です。同じ名前がすでにある場合は、作業に合った別の名前を使用してください。

```bash
git switch -c docs/update-introduction
```

進行中の変更は保持し、依頼や提案に関係のない修正を同じ変更に混ぜないでください。

## ドキュメントの作成

**README**は製品紹介、仕様表、インストール、使い方を案内します。詳細仕様、技術選定、開発計画、リポジトリ構成は`docs/`で管理します。
**CONTRIBUTING**はメンテナー向けにソースの実行準備、開発、検査、コミット、配布の方法と、現在のコントリビューション方針を記載します。

英語のREADMEとCONTRIBUTINGはリポジトリのルート、韓国語版は`language/ko/`、日本語版は`language/jp/`で、同じ内容と構成を保って管理します。各文書の上部にある言語表は、同じ文書の別言語版にリンクします。この文書の実行コマンドはリポジトリのルートを基準とします。

- READMEは[Standard Readme仕様](https://github.com/RichardLitt/standard-readme/blob/main/spec.md)のセクション構成に従います。目次を維持し、ライセンスを最後に置きます。翻訳ファイルは、標準の`README.<言語>.md`という命名ではなく、このプロジェクトの`language/<言語>/README.md`という構成で管理します。
- 短い紹介文は、README、将来のパッケージメタデータ、GitHubリポジトリの説明で一致させます。
- 現在の動作と開発計画を区別します。まだ存在しないコマンド、ディレクトリ、配布URLを利用可能であるかのように記載しないでください。
- 開発者以外に向けた説明では、問題と次の操作を先に示し、専門用語は初出時に説明します。
- 技術仕様には、確認済みのバージョンと根拠となるファイルを記載します。バージョンが決まっていなければ`未定`と表示します。
- セキュリティ問題と更新情報の説明では、原文の情報源、確認日時、影響を受けるバージョン、修正済みのバージョンを区別します。未確認の内容は推測として明示します。

詳細設計が長くなったら、`docs/`の該当文書に分離し、READMEからリンクします。文書が増えたら主題ごとに整理し、同じ内容を複数のファイルに重複して記載しないでください。

## 実装と検証

### メッセージのプレビュー

共通の文言は[messages.sh](../../installers/macos/messages.sh)で変更します。`shelter_copy`にメッセージキーと固定テンプレートを追加し、`shelter_error install_failed "$name"`のように可変値を引数で渡します。`shelter_error`はstderrへの出力と失敗理由の保存を行い、`return`や`exit`で中断するタイミングは呼び出し元で決めます。通常の案内には`shelter_message <tone> <key> [arguments...]`、開始、警告、成功、失敗の共通表示には`shelter_notice`を使います。内部の状態値と表示文言は分離します。テストも共通メッセージを呼び出しますが、意図しない文言や形式の変更を検出するため、期待する出力は独立した文字列で保持します。

**各状態の表現と説明だけを確認したい場合**は、リポジトリのルートで`--preview`の後に状態を指定します。色は追加オプションなしで適用されます。

```bash
/bin/bash installers/macos/tests/test.sh --preview notification
/bin/bash installers/macos/tests/test.sh --preview warning
/bin/bash installers/macos/tests/test.sh --preview failure
/bin/bash installers/macos/tests/test.sh --preview success
```

| 状態 | `●`の色（結果見出しにも適用） | 確認するメッセージ |
| --- | --- | --- |
| `notification` | シアン | 初期設定を開始する案内 |
| `warning` | 黄 | 実行パスの反映待ちと、ターミナルやエディターを開き直す説明 |
| `failure` | 赤 | インストール失敗の見出しと理由の例 |
| `success` | 緑 | インストール完了の見出しと開発ツールの準備完了の説明 |

プレビューは、実際のインストーラーと共有するメッセージ関数だけを呼び出します。インストール状態の確認や一時ファイルの作成は行いません。`--preview`だけを指定すると`success`を表示します。色は既定で有効になります。ターミナルの設定に従う場合は`--color auto`、色なしの出力を確認する場合は`--color never`を使用します。

### インストール手順のテスト

**実際のインストーラーの全手順を一時環境で実行したい場合**は、`--install`を使用します。

```bash
/bin/bash installers/macos/tests/test.sh --install
```

ツールのないテスト環境で、Homebrewの準備から固定仕様のインストール、結果確認、シェル設定まで、実際のインストーラーのコードを実行します。ダウンロードとパッケージのインストールコマンドは模擬ツールに置き換え、実際のPCのプログラムやユーザーのシェル設定は変更しません。テスト用ファイルとログは終了後に自動削除します。

正式なオプション表記は`--install`ですが、`--intall`も同じ動作として扱います。以下のシナリオ名はテスト条件であり、実際にインストールするツールを選ぶオプションではありません。

```bash
# uvのインストール中に失敗し、後続のインストールを停止する流れ
/bin/bash installers/macos/tests/test.sh --install failure

# テスト環境のインストール計画を確認
/bin/bash installers/macos/tests/test.sh --install dry-run
```

`--install success`は既定のシナリオと同じです。失敗シナリオでは、内部のインストーラーが終了コード`1`を返すことが期待されます。テストコマンドは、期待した結果なら`0`、異なる結果なら`1`、不正なオプションなら`2`で終了します。期待と異なる場合にだけ、別途テストエラーを表示します。`--preview`と`--install`は同時に使用できません。

現在のMacの実際の状態を読み取ってインストール計画を確認するには、`install.sh --dry-run`を使用します。実際の初期設定は、[ライト版の実行](#ライト版の実行)にあるオプションなしのコマンドで行います。

### シェルの検証

リポジトリのルートで構文検査と一時環境でのテストを実行します。別途テスト用パッケージを用意する必要はありません。

```bash
for script in scripts/*.sh installers/macos/*.sh installers/macos/tests/test.sh; do
  /bin/bash -n "$script" || exit 1
done
/bin/bash installers/macos/tests/test.sh
```

テストはHomebrew、ダウンロード、インストールコマンド、環境判定を置き換え、一時ディレクトリにだけ結果を書き込みます。実際のプログラムやユーザーのシェル設定は変更しません。固定仕様のインストール、既存バージョンの保持、再実行、インストール失敗、不正なオプション、未対応の環境、設定バックアップ、別のエディターの`code`コマンドの保持を検査します。簡潔な画面と詳細ログの分離、ログの権限、`●`と結果見出しの色および本文の既定色、状態ごとのプレビュー、インストール手順テストの隔離と終了コードも検査します。 Ghosttyについては、`PATH`にない既存アプリの保持、破損したアプリの検出、インストール失敗と再試行、インストール後の実行確認も検査します。

パッケージングのテストでは、チェックサム、同じソースからの再現可能な出力、ファイルを別の場所に移動してからのヘルプ実行、インストールを開始しないソース読み込みも検査します。インストールと`--dry-run`の画面ではASCIIロゴが1回表示されることも検査します。 ZIPについてはmacOSで展開した後の実行権限、単独実行、終了コードの保持、同じソースからの再現可能なアーカイブも検査します。

対応するMacでは、次の読み取り専用コマンドも確認します。

```bash
/bin/bash installers/macos/install.sh --help
/bin/bash installers/macos/install.sh --dry-run
/bin/bash installers/macos/install.sh --check
```

新しいMacで実際のダウンロードとインストールが完了するか、Ghostty、新しいターミナル、VS Codeでツールを実行できるか、再実行時にインストールや設定が重複しないかを別途検証します。**実機での確認はmacOS 26.6.2の読み取り専用実行までです。CIの検証範囲は以下に記載します。クリーン環境での全体のインストールは未検証です。**

### 確認済みのCI検証範囲

`0.2.0`の実装は2026-11-04の[CI実行41794242682](https://github.com/4BFC/shelter/actions/runs/41794242682)を通過しました。各行はプラットフォームとテスト環境を示し、ソースと展開したZIPに対して同じスイートを個別に実行した結果です。

| プラットフォーム | ソーステスト | ZIPテスト | 実行環境 |
| --- | --- | --- | --- |
| macOS | 34件成功 | 34件成功 | macOS 15 runner、標準Bash |
| Windows | 35件成功 | 35件成功 | Windows 2025 runner、Windows PowerShell 5.1 |

チェックサム、埋め込みバージョン、Windowsの`.cmd`ランチャーのバージョン表示と失敗終了コードも確認しました。パッケージ導入とユーザー設定変更はモック化しています。Windows Server runnerの利用はWindows Serverへのインストール対応を意味しません。クリーンなWindows 11での導入、WinGet修復、UAC、ダウンロードファイルの警告は[実機検証一覧](../../docs/plans/windows-lite.md#clean-device-acceptance-before-publishing-v020)に残っています。

### ドキュメントとdiffの検証

リポジトリのルートで実行します。

```bash
git diff --check
git diff -- .gitignore README.md CONTRIBUTING.md language/ installers/macos/
git status --short
```

`git diff`には、追跡対象ファイルの変更だけが表示されます。新しいファイルは、エディターで内容全体を別途確認してください。

Markdownプレビューで見出し、表、コードブロック、バッジを確認し、目次と相対リンクを点検します。
ライセンス表記の所有者と年は[LICENSE](../../LICENSE)と一致させてください。

### 機能別の検証基準

リリースworkflowでBashの構文検査と隔離されたインストーラーテストを実行します。以下の機能を追加するときに、必要な静的検査も追加します。

| 変更する領域 | 確認する動作 |
| --- | --- |
| 情報収集 | 原文の情報源と確認日時の保持、重複する告知の処理、収集失敗と古い情報の表示 |
| 影響の判断 | 影響を受けるバージョンと受けないバージョン、修正済みバージョンの区別。不明な状態を安全と表示しないこと |
| PCの状態確認 | インストール済みバージョンと実際の実行パス、管理ツール間の競合、未対応環境の区別 |
| インストールと更新 | 変更対象と結果の表示、ダウンロードや適用の失敗処理、設定バックアップと復元できる範囲の確認 |
| 通知と案内 | 問題、必要な操作、結果をわかりやすく表示し、再起動が必要な場合は別途案内すること |

PCの設定を変更するテストは、一時ディレクトリまたは隔離環境で実行します。更新方針が決まる前に、自動適用を既定の動作と仮定しないでください。
新しいバージョンのインストールと、実行中のプログラムのバージョン切り替えを区別し、再起動が必要な状態を完了と表示しないでください。

## コミットと公開

コミット前に変更ファイルとdiffを確認し、必要なファイルだけを選んで含めます。
コミットメッセージは変更内容を短く具体的に説明します。例: `docs: Shelterのメンテナンス方針を明記`。

AIツールと作業する場合は、先に変更差分を確認します。ユーザーの明示的な指示なしにステージングやコミットを行わず、コミットに`Co-Authored-By`を追加しないでください。

個人用のClaude/Codexディレクトリ（`.claude/`、`.codex/`、`.agents/`）、Claudeの状態ファイル（`.claude.json*`）、ローカル指示ファイル（`CLAUDE.local.md`、`AGENTS.local.md`、`AGENTS.override.md`）、`.mcp.local.json`は`.gitignore`で除外します。個人のパスや認証情報はこれらのローカルファイルに保存します。共有のプロジェクト指示である`CLAUDE.md`と`AGENTS.md`はGitで管理できます。

公開前に変更の要約へ次の内容を記録します。

- 解決する問題と変更後の動作
- 確認したコマンドと結果、実施できなかった検証
- ユーザーが知っておくべき制約や今後の作業

ドキュメント変更にはリンクとプレビューの確認結果を、機能変更には再現可能な検証結果を含めます。
メンテナーが承認した変更だけを公開します。外部からのプルリクエストとIssueは、この作業手順では使用しません。

## 配布

### ダブルクリックでインストール

ユーザー向けのインストール手順とmacOSのセキュリティ確認は[READMEのインストール](./README.md#インストール)を参照してください。

`.command`ファイルにインストーラー全体を含みます。ZIPに実行権限を保持するため、ユーザーが`chmod`を入力する必要はありません。引数なしでターミナルから実行した場合は、インストールに失敗してもReturnを押すまで結果を表示します。`--dry-run`などのコマンドラインオプションも利用できます。

### 配布ファイルの生成と検証

リポジトリのルートからShelter Liteの単一配布ファイルを生成します。パッケージングにはmacOS標準のBashとコマンドラインツールを使用し、プログラムのダウンロードやインストールは行いません。

```bash
/bin/bash installers/macos/build.sh
```

生成されるファイルは次のとおりです。

```text
dist/
├── shelter-lite-macos.sh        # 単一インストールファイル
├── shelter-lite-macos.sh.sha256 # SHA-256チェックサム
├── shelter-lite-macos.zip       # ダブルクリック用インストーラーZIP
├── shelter-lite-macos.zip.sha256 # SHA-256チェックサム
└── VERSION                     # 製品バージョンの単一管理元
```

`.sh`ファイルに`install.sh`、`messages.sh`、`scripts/version.sh`、製品バージョンとMITライセンスを含むため、このファイルだけを別のフォルダーに移動して実行できます。`dist/`はGit管理対象外です。生成ファイルを直接編集せず、元のソースを編集して再生成してください。同じソースからは同じファイルが生成されます。別の出力先が必要な場合は、`--output-dir "/path/with spaces"`を使用します。

チェックサムを確認し、単一配布ファイルのコードで隔離されたテストを実行します。

```bash
(cd dist && shasum -a 256 -c shelter-lite-macos.sh.sha256)
(cd dist && shasum -a 256 -c shelter-lite-macos.zip.sha256)
/bin/bash dist/shelter-lite-macos.sh --help
SHELTER_TEST_INSTALLER="$PWD/dist/shelter-lite-macos.sh" /bin/bash installers/macos/tests/test.sh
```

ユーザー向けのインストール手順とmacOSのセキュリティ確認は[READMEのインストール](./README.md#インストール)を参照してください。

対応条件は従来と同じmacOS 15以降、ネイティブApple Silicon環境、zsh/bashで、実際のインストールにはインターネット接続が必要です。インストールと`--dry-run`の開始時にShelter LiteのASCIIロゴを表示します。パッケージングと隔離テストは新しいMacでの全体のインストールを検証せず、その検証はまだ行っていません。Homebrewでの配布とリモートから1つのコマンドでインストールする方法は今後の作業です。

### バージョン管理

各環境の共通関数[scripts/version.sh](../../scripts/version.sh)と[scripts/version.ps1](../../scripts/version.ps1)はインストーラーに依存せず、同じ製品バージョンを読み込んで検証します。エラーの表示方法は呼び出し側で決めます。

`VERSION`の変更、ファイルのビルド、ソースのpushだけではリリース公開やタグ作成は行われません。まずソースとファイルを準備して検証します。タグの選択とGitHubリリース公開はメンテナーが別途行います。準備段階でローカルタグ作成コマンドは不要です。

ルートの[VERSION](../../VERSION)をShelter Liteの製品バージョンの単一管理元とします。[Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html)の形式で、先頭の`v`を付けずに記録します。例は`0.1.0`と`0.2.0-rc.1`です。プレリリース識別子と任意の`+build.metadata`もSemVer構文に従います。

`0.x`の開発段階では、互換性を保つ修正でPATCHを、機能追加や互換性の変更でMINORを上げます。コマンドとインストール動作の安定した規約を初めて提供するときに`1.0.0`へ移行します。その後は非互換の変更でMAJOR、互換性のある機能追加でMINOR、互換性のある修正でPATCHを上げます。MAJORまたはMINORを上げると下位の数値を0に戻します。リリース候補は`0.2.0-rc.1`のように表記します。

1. 次のリリース用に`VERSION`を編集します。バージョンと実装を一緒にコミットし、公開済みバージョンのタグを変更後のコードへ移動しないでください。
2. プラットフォームに応じて`build.sh`または`build.ps1`で再生成します。`.sh`、`.command`、`.ps1`内にバージョンを固定し、各ZIPと`dist/VERSION`にも同じ値を記録します。元の`VERSION`を編集しても生成済みの配布ファイルは変わりません。
3. `VERSION`の前に`v`を付けたタグでGitHubリリースを公開します。`0.2.0`なら`v0.2.0`です。リリース候補はGitHubでプレリリースに設定します。タグが異なる場合はビルドとアップロードの前にworkflowを停止します。workflowは指定したバージョンを検証してパッケージングし、バージョン番号は自動で上げません。

```bash
/bin/bash installers/macos/install.sh --version
/bin/bash installers/macos/build.sh
/bin/bash dist/shelter-lite-macos.sh --version
cat dist/VERSION
```

`--version`は環境の検査、ダウンロード、設定変更を行わず、`Shelter Lite <version>`を表示します。製品バージョンには`SHELTER_RELEASE_VERSION`を使用し、`SHELTER_VERSION`は検査中のツールの実際のバージョンを保持します。ZIP内の`VERSION`は確認用で、`.command`の実行には不要です。`dist/VERSION`はリリースにも別途添付します。

### リリースファイルの自動添付

[release.yml](../../.github/workflows/release.yml)はプレリリースを含むGitHubリリースの公開時に実行します。[validate.yml](../../.github/workflows/validate.yml)を呼び出し、タグと`VERSION`の一致、ソースとZIPのテスト、両プラットフォームのビルド、チェックサム、埋め込みバージョンを確認します。macOSはmacOS 15 runner、WindowsはWindows 2025 runnerの標準PowerShell 5.1でモックテストを実行します。両ジョブの成功後に、各プラットフォームのインストーラー2つとチェックサム2つ、共通の`VERSION`を合わせた9ファイルを公開ジョブがアップロードします。

検証workflowは`main`への実装変更のpush時と手動でも実行できます。この場合はリリースファイルを公開しません。

1. workflowとインストーラーのソースをコミットしてGitHubにpushします。このworkflowと配布するソースを含むコミットをリリースタグの対象にします。
2. GitHubの**Releases**で対象のタグからリリースを作成し、**Publish release**をクリックします。下書きの保存やタグのpushだけではworkflowは実行しません。
3. Actionsの**Release Shelter Lite**が成功した後、**Assets**からOSに合ったZIPをダウンロードします。単一の`.sh`と`.ps1`、チェックサム4つ、共通の`VERSION`も添付されます。

リポジトリの標準`GITHUB_TOKEN`に`contents: write`権限を使用するため、別のリリース用トークンは不要です。テストやビルドが失敗した場合はアップロードを中断します。問題を解決した後、Actionsでジョブを再実行できます。同名の添付ファイルは置き換えます。既存のリリースにファイルを添付し、隔離されたテストを実行する方式のため、新しいMacやWindows PCでの全体のインストール検証に代わるものではありません。

Shelter自体を更新する手順と、ShelterがユーザーのPCのソフトウェアを更新する動作を区別します。
### リリースノート

リリースノートはGitHubリリースの本文にのみ記載し、リポジトリには別のノートファイルを置きません。インストーラーのメッセージと同じく英語で記載します。冒頭には中央揃えの見出しと1文の紹介を置きます。**New**の下には追加された機能のみをプラットフォーム別に記載し、そのリリースで変更したプラットフォームに合わせて**macOS**と**Windows**のセクションを設けます。最後に、インストールファイルごとにプラットフォーム、要件、チェックサムへのリンクを記載した**Download**表を置きます。ファイルへのリンクはworkflowのアップロード完了後に有効になります。

```markdown
<div align="center">

# `shelter-lite@v<version>` is here!

<one sentence about this release>

</div>

## New

### macOS

- <added feature>

### Windows

- <added feature>

## Download Shelter Lite v<version>

| File | Platform | Requirements | Checksum |
| --- | --- | --- | --- |
| [shelter-lite-macos.zip](https://github.com/4BFC/shelter/releases/download/v<version>/shelter-lite-macos.zip) | macOS, double-click | macOS 15 or later, Apple Silicon | [sha256](https://github.com/4BFC/shelter/releases/download/v<version>/shelter-lite-macos.zip.sha256) |
| [shelter-lite-macos.sh](https://github.com/4BFC/shelter/releases/download/v<version>/shelter-lite-macos.sh) | macOS, Terminal | macOS 15 or later, Apple Silicon | [sha256](https://github.com/4BFC/shelter/releases/download/v<version>/shelter-lite-macos.sh.sha256) |
| [shelter-lite-windows.zip](https://github.com/4BFC/shelter/releases/download/v<version>/shelter-lite-windows.zip) | Windows, double-click | Windows 11 x64 | [sha256](https://github.com/4BFC/shelter/releases/download/v<version>/shelter-lite-windows.zip.sha256) |
| [shelter-lite-windows.ps1](https://github.com/4BFC/shelter/releases/download/v<version>/shelter-lite-windows.ps1) | Windows, PowerShell | Windows 11 x64, Windows PowerShell 5.1 | [sha256](https://github.com/4BFC/shelter/releases/download/v<version>/shelter-lite-windows.ps1.sha256) |

Installation steps: [README](https://github.com/4BFC/shelter#install)
```
