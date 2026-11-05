```text
  ____  _          _ _
 / ___|| |__   ___| | |_ ___ _ __
 \___ \| '_ \ / _ \ | __/ _ \ '__|
  ___) | | | |  __/ | ||  __/ |
 |____/|_| |_|\___|_|\__\___|_|       Hello, AI World
```

# Shelter

ShelterはmacOSとWindowsに開発ツールをインストールし、実行状態を確認します。正常に動作するツールは保持し、不足する構成要素を準備します。

[![Release](https://img.shields.io/github/v/release/4BFC/shelter?include_prereleases&style=flat-square)](https://github.com/4BFC/shelter/releases)
![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?style=flat-square&logo=apple&logoColor=white)
![Windows 11 x64](https://img.shields.io/badge/Windows-11_x64-0078D4?style=flat-square)
![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-M_series-000000?style=flat-square&logo=apple&logoColor=white)
![Bash 3.2.57](https://img.shields.io/badge/Bash-3.2.57-4EAA25?style=flat-square&logo=gnubash&logoColor=white)
![Status: prototype](https://img.shields.io/badge/status-prototype-D99A4E?style=flat-square)

<div align="center">
<table align="center">
  <tr>
    <td align="center"><a href="../../README.md"><img src="https://img.shields.io/badge/English-555555?style=flat-square" alt="English"></a></td>
    <td align="center"><a href="../ko/README.md"><img src="https://img.shields.io/badge/%ED%95%9C%EA%B5%AD%EC%96%B4-555555?style=flat-square" alt="한국어"></a></td>
    <td align="center"><a href="README.md"><img src="https://img.shields.io/badge/%E6%97%A5%E6%9C%AC%E8%AA%9E-0969DA?style=flat-square" alt="日本語"></a></td>
  </tr>
</table>
</div>

<!-- 検証済みのターミナル画面を準備したら、ここに追加します。 -->

## 目次

- [仕様](#仕様)
- [インストール](#インストール)
- [使い方](#使い方)
- [コントリビューション方針](#コントリビューション方針)
- [ライセンス](#ライセンス)

## 仕様

### 対応ツール

ライト版はツールを選択せず、次の固定構成全体を準備します。記載のバージョンは新規インストールの対象で、動作する既存バージョンは保持します。

| 構成 | macOS | Windows |
| --- | --- | --- |
| パッケージ管理 | ![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?style=flat-square&logo=homebrew&logoColor=black) | ![WinGet](https://img.shields.io/badge/WinGet-0078D4?style=flat-square) |
| バージョン管理 | ![Git](https://img.shields.io/badge/Git-F05032?style=flat-square&logo=git&logoColor=white) | ![Git](https://img.shields.io/badge/Git-F05032?style=flat-square&logo=git&logoColor=white) |
| エディター | ![VS Code](https://img.shields.io/badge/VS_Code-007ACC?style=flat-square) | ![VS Code](https://img.shields.io/badge/VS_Code-007ACC?style=flat-square) |
| ターミナル | ![Ghostty](https://img.shields.io/badge/Ghostty-3551F3?style=flat-square&logo=ghostty&logoColor=white) | ![Windows Terminal](https://img.shields.io/badge/Windows_Terminal-4D4D4D?style=flat-square) |
| JavaScript | ![Node.js 24.x](https://img.shields.io/badge/Node.js-24.x-5FA04E?style=flat-square&logo=nodedotjs&logoColor=white) ![npm](https://img.shields.io/badge/npm-CB3837?style=flat-square&logo=npm&logoColor=white) | ![Node.js 24.x](https://img.shields.io/badge/Node.js-24.x-5FA04E?style=flat-square&logo=nodedotjs&logoColor=white) ![npm](https://img.shields.io/badge/npm-CB3837?style=flat-square&logo=npm&logoColor=white) |
| Python | ![Python 3.14.x](https://img.shields.io/badge/Python-3.14.x-3776AB?style=flat-square&logo=python&logoColor=white) ![uv](https://img.shields.io/badge/uv-DE5FE9?style=flat-square&logo=uv&logoColor=white) | ![Python 3.14.x](https://img.shields.io/badge/Python-3.14.x-3776AB?style=flat-square&logo=python&logoColor=white) ![uv](https://img.shields.io/badge/uv-DE5FE9?style=flat-square&logo=uv&logoColor=white) |
| GitHub連携 | ![GitHub CLI (gh)](https://img.shields.io/badge/GitHub_CLI-gh-181717?style=flat-square&logo=github&logoColor=white) | ![GitHub CLI (gh)](https://img.shields.io/badge/GitHub_CLI-gh-181717?style=flat-square&logo=github&logoColor=white) |

### システム要件

インストーラーは、以下のOSに標準搭載されたシェルで実行します。

| 構成 | 技術 | 説明 |
| --- | --- | --- |
| macOS | ![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?style=flat-square&logo=apple&logoColor=white) | Apple Silicon、zsh/bash |
| macOSインストーラー | ![Bash 3.2.57](https://img.shields.io/badge/Bash-3.2.57-4EAA25?style=flat-square&logo=gnubash&logoColor=white) | macOS標準のBashで実行 |
| Windows | ![Windows 11 x64](https://img.shields.io/badge/Windows-11_x64-0078D4?style=flat-square) | ネイティブx64 |
| Windowsインストーラー | ![Windows PowerShell 5.1](https://img.shields.io/badge/Windows_PowerShell-5.1-5391FE?style=flat-square) | Windows標準のDesktopエディションで実行 |

インストール方針と技術の詳細は[技術仕様](../../docs/specification.jp.md)を参照してください。

## インストール

### macOSの動作条件

- macOS 15以降、Apple Silicon（Mシリーズチップ）のネイティブなターミナル環境。macOS用インストーラーはIntel Mac、Rosetta、Windowsに対応していません。
- インターネット接続と、Homebrewの認証要求に使用するmacOS管理者アカウント。
- シェル設定はzshとbashに対応します。Homebrew、Node.js、Pythonの事前インストールは不要です。Shelter自体は`sudo`なしで通常のユーザーとして実行してください。

### macOSでのダウンロードと実行

[GitHub Releases](https://github.com/4BFC/shelter/releases)からインストーラーをダウンロードします。以下は**Assets**に`shelter-lite-macos.zip`が公開されている場合の手順です。まだファイルがない場合は[ソースのビルド手順](./CONTRIBUTING.md#配布)を参照してください。

1. リリースの**Assets**から`shelter-lite-macos.zip`をダウンロードします。GitHubのソースコードZIPとは別のファイルです。
2. ZIPをダブルクリックして展開し、`Shelter Lite.command`をダブルクリックします。ターミナルが開き、インストールが始まります。
3. Homebrewの確認や管理者パスワードの要求が表示されたら応答します。入力中の文字が表示されないことがあります。Macのログインパスワードを入力してReturnを押してください。
4. 最後の結果を読み、Returnを押して終了します。[使い方](#使い方)に従って新しい環境を反映し、確認してください。

インストーラーは署名されていないスクリプトです。macOSにブロックされたら、ダウンロード元を確認し、[Appleのセキュリティ案内](https://support.apple.com/en-us/102445)を参照してください。開発元を確認できないという警告の場合、Appleは信頼できるファイルについて、起動を試した後に**システム設定 → プライバシーとセキュリティ → このまま開く**を選ぶ手順を案内しています。

<details>
<summary>任意: ダウンロードしたファイルの確認</summary>

チェックサムは、ダウンロードしたファイルが公開されたファイルと一致するかを確認する値です。`shelter-lite-macos.zip.sha256`もZIPと同じフォルダーにダウンロードします。両方がダウンロードフォルダーにある場合、ターミナルで実行します。

```bash
cd ~/Downloads
shasum -a 256 -c shelter-lite-macos.zip.sha256
```

`shelter-lite-macos.zip: OK`と表示された場合のみ進んでください。一致しなければ、実行前に両方のファイルを再ダウンロードしてください。

</details>

### Windowsでのダウンロードと実行

Windows対応はソースバージョン`0.2.0`に実装しています。リポジトリの変更とCIビルドはリリース公開より先になる場合があります。**Assets**に`shelter-lite-windows.zip`があるリリースからダウンロードしてください。配布ファイルはリリース公開とworkflowの成功後に利用できます。

- Windows 11 x64、ネイティブ64ビットのWindows PowerShell 5.1を使用します。Windows 10、Windows Server、ARM64、32ビットプロセスは対象外です。
- **管理者として実行**せず、通常のアカウントで起動します。インターネット接続が必要です。個別パッケージのUAC認証要求に応答してください。組織のポリシーでインストールが制限される場合があります。
- 固定構成はWinGet、Git、VS Code、Windows Terminal、Node.js 24/npm、Python 3.14/uv、GitHub CLIです。動作する既存バージョンは保持します。WinGetがない場合はMicrosoftの現在のユーザー向け修復モジュールで準備します。

ランチャーは標準のWindows PowerShell 5.1を使います。PowerShell 7はインストール対象ではありません。

1. `shelter-lite-windows.zip`の**全ファイル**を同じフォルダーに展開します。
2. `Shelter Lite.cmd`をダブルクリックします。`shelter-lite-windows.ps1`を同じフォルダーに置いてください。セットアップは固定ツールのWinGetソースとパッケージの利用規約に同意します。
3. 結果を読み、何かキーを押して閉じます。その後、ターミナルとエディターを開き直してください。

署名のないスクリプトです。ランチャーは当該プロセスだけの実行ポリシーを指定し、保存された設定や組織のポリシーを変更しません。Windowsのセキュリティ警告が表示される場合があります。クリーンなWindows 11 PCでの全体のインストールは未検証です。

ZIPを確認するには、`.sha256`も同じフォルダーへダウンロードし、その場所のPowerShellで次を実行します。結果が`True`の場合のみ進んでください。

```powershell
$expected = ((Get-Content .\shelter-lite-windows.zip.sha256 -Raw) -split ' ')[0]
(Get-FileHash .\shelter-lite-windows.zip -Algorithm SHA256).Hash.ToLowerInvariant() -ceq $expected
```

## 使い方

### 結果を読む

メッセージとログは英語で表示します。

- `Installation complete`（インストール完了）: ツールの準備ができました。新しいターミナルを開き、実行中のエディターを再起動して、追加された実行パスを反映してください。
- `Installation failed`（インストール失敗）: 処理が中断されました。ターミナルに表示されたエラーを確認してください。
- `warning`（警告）: 再起動の必要性や、失敗後に残った変更についての案内を確認してください。

<details>
<summary>インストール後の作業</summary>

macOSではアプリケーションフォルダーからGhosttyを開くか、ターミナルで`open -a Ghostty`を実行します。WindowsではスタートメニューからWindows Terminalを開きます。ターミナルの設定、フォント、既定のターミナルは変更しません。

Gitを使う場合は、コミットに記録するユーザー情報を自分で設定してください。例の名前とメールアドレスを自分の情報に置き換えます。このグローバル設定は現在のユーザーアカウントに適用されます。すでに正しく設定済みなら保持してください。

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

GitHub CLIをGitHubアカウントに接続するには、次を実行して案内に従います。

```bash
gh auth login
```

</details>

### macOSのプレビューと状態確認

展開した`Shelter Lite.command`を保管してください。新しいターミナルで、そのファイルのあるフォルダーへ移動します。以下はダウンロードフォルダーの直下にある場合の例です。別の場所に展開した場合はパスを変更してください。各コマンドは独立しており、ツールのインストールや設定変更は行いません。

```bash
cd ~/Downloads
/bin/bash "Shelter Lite.command" --dry-run
/bin/bash "Shelter Lite.command" --check
echo $?
/bin/bash "Shelter Lite.command" --version
/bin/bash "Shelter Lite.command" --help
```

`--dry-run`は不足するツールと変更予定を表示します。`--check`の全項目が`Installed`（インストール済み）で、直後の`echo $?`が`0`なら、全ツールを実行できる状態です。脆弱性や最新バージョンの検査ではありません。

全オプションは`--help`で確認できます。

単一ファイルをダウンロードした場合は、そのフォルダーで`/bin/bash shelter-lite-macos.sh`に同じオプションを付けて実行します。どちらのファイルもオプションなしで実行するとインストールを開始します。

### Windowsでのプレビューと確認

ZIPを展開したフォルダーでPowerShellを開いてください。次のコマンドはインストールや設定変更を行いません。

```powershell
& '.\Shelter Lite.cmd' --dry-run
& '.\Shelter Lite.cmd' --check
$LASTEXITCODE
& '.\Shelter Lite.cmd' --version
& '.\Shelter Lite.cmd' --help
```

`--check`の直後に`$LASTEXITCODE`を確認します。`0`は全ツールの準備完了、`1`は確認が必要な状態です。セットアップはユーザーPATHをバックアップし、不足する実行パスだけを末尾に追加します。PowerShellプロファイル、システムPATH、Gitユーザー情報、GitHubログインは保持します。ログとPATHバックアップは`%LOCALAPPDATA%\Shelter\logs`に保存します。新規Pythonは`python3.14`で実行し、既存の`python`コマンドとStoreエイリアスの優先順位は保持します。

## コントリビューション方針

現在、外部からのプルリクエストとIssueは受け付けておらず、両機能を無効にしています。開発とリリースはメンテナーが担当します。ソフトウェアの利用、改変、再配布には[MITライセンス](../../LICENSE)が適用されます。

## ライセンス

[MIT](../../LICENSE) © 2026 poby · [@4BFC](https://github.com/4BFC)
