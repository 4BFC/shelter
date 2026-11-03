```text
  ____  _          _ _
 / ___|| |__   ___| | |_ ___ _ __
 \___ \| '_ \ / _ \ | __/ _ \ '__|
  ___) | | | |  __/ | ||  __/ |
 |____/|_| |_|\___|_|\__\___|_|
```

# Shelter

ShelterはMacに開発ツールをインストールし、実行状態を確認します。正常に動作するツールは保持し、不足する構成要素を準備します。

![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?style=flat-square&logo=apple&logoColor=white)
![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-M_series-000000?style=flat-square&logo=apple&logoColor=white)
![Bash 3.2.57](https://img.shields.io/badge/Bash-3.2.57-4EAA25?style=flat-square&logo=gnubash&logoColor=white)
![Status: prototype](https://img.shields.io/badge/status-prototype-D99A4E?style=flat-square)

[English](../../README.md) · [한국어](../ko/README.md) · [日本語](README.md)

<!-- 検証済みのターミナル画面を準備したら、ここに追加します。 -->

## 目次

- [仕様](#仕様)
- [インストール](#インストール)
- [使い方](#使い方)
- [ドキュメント](#ドキュメント)
- [ライセンス](#ライセンス)

## 仕様

| 構成 | 技術 | 説明 |
| --- | --- | --- |
| OS | ![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?style=flat-square&logo=apple&logoColor=white) | Apple Silicon、zsh/bash |
| インストーラー | ![Bash 3.2.57](https://img.shields.io/badge/Bash-3.2.57-4EAA25?style=flat-square&logo=gnubash&logoColor=white) | macOS標準のBashで実行 |
| パッケージ管理 | ![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?style=flat-square&logo=homebrew&logoColor=black) | 開発ツールのインストール |
| CLI | ![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white) | 検討中。バージョン未定 |
| CLI開発ツール | ![Typer](https://img.shields.io/badge/Typer-009688?style=flat-square&logo=typer&logoColor=white) ![uv](https://img.shields.io/badge/uv-DE5FE9?style=flat-square&logo=uv&logoColor=white) | 検討中。バージョン未定 |

インストール方針と技術の詳細は[技術仕様](../../docs/specification.jp.md)を参照してください。

## インストール

### 動作条件

- macOS 15以降、Apple Silicon（Mシリーズチップ）のネイティブなターミナル環境。Intel Mac、Rosetta、Windowsは非対応です。
- インターネット接続と、Homebrewの認証要求に使用するmacOS管理者アカウント。
- シェル設定はzshとbashに対応します。Homebrew、Node.js、Pythonの事前インストールは不要です。Shelter自体は`sudo`なしで通常のユーザーとして実行してください。

### ダウンロードと実行

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

## 使い方

### 結果を読む

メッセージとログは英語で表示します。

- `Installation complete`（インストール完了）: ツールの準備ができました。新しいターミナルを開き、実行中のエディターを再起動して、追加された実行パスを反映してください。
- `Installation failed`（インストール失敗）: 処理が中断されました。ターミナルに表示されたエラーを確認してください。
- `warning`（警告）: 再起動の必要性や、失敗後に残った変更についての案内を確認してください。

<details>
<summary>インストール後の作業</summary>

アプリケーションフォルダーからGhosttyを開くか、ターミナルで`open -a Ghostty`を実行します。Ghosttyの設定、フォント、既定のターミナルは変更しません。

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

### プレビューと状態確認

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

## ドキュメント

- [技術仕様と開発計画](../../docs/specification.jp.md)
- [ビルド・テスト・貢献ガイド](./CONTRIBUTING.md)
- [質問と不具合の報告](https://github.com/4BFC/shelter/issues)

## ライセンス

[MIT](../../LICENSE) © 2026 poby · [@4BFC](https://github.com/4BFC)
