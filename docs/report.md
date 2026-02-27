# claude-dotfiles 実装報告書

**作成日**: 2026-02-27
**リポジトリ**: https://github.com/kinokooya/claude-dotfiles

---

## 1. 背景

vox プロジェクト開発中に、Claude Code セッションでトークンを大量消費する問題が発生。
対策として Windows の `~/.claude/` に PreToolUse Hook・グローバル CLAUDE.md・GitHub MCP を導入済みだったが、以下の課題があった:

- Hook の Python パスが Windows 固定 (`/c/Users/above/.../python.exe`) でハードコードされている
- WSL や他のマシンでは動作しない
- 新しいマシンで環境を再現する手段がない

## 2. 実装内容

### 2.1 リポジトリ構成

```
claude-dotfiles/
├── .gitignore
├── README.md
├── setup.sh               # 冪等セットアップスクリプト
├── hooks/
│   ├── optimize-bash.sh   # クロスプラットフォーム版エントリポイント
│   └── optimize-bash.py   # Hook 本体 (変更なし)
├── settings-hooks.json    # Hook 登録テンプレート
└── CLAUDE.md              # グローバル開発ルール
```

### 2.2 Hook のクロスプラットフォーム化 (`optimize-bash.sh`)

**変更前** (Windows 固定):
```bash
/c/Users/above/AppData/Local/Programs/Python/Python312/python.exe "$SCRIPT_DIR/optimize-bash.py"
```

**変更後** (3段階フォールバック):
```bash
# 1. python3 (Linux/Mac/WSL)
# 2. python  (一部環境)
# 3. Windows インストールパス検索 (/c/Users/*/AppData/Local/Programs/Python/Python3*/python.exe)
```

**Windows Store スタブ問題への対処**:
Windows では `python3` / `python` コマンドが Microsoft Store のスタブにリダイレクトされ、exit code 49 で失敗する。
`--version` の終了コードで実際に動作するかを判定し、失敗時は Windows の一般的なインストールパスをグロブ検索する。

### 2.3 セットアップスクリプト (`setup.sh`)

4ステップで `~/.claude/` を構成:

| ステップ | 処理 | 冪等性 |
|---|---|---|
| 1. Hook インストール | `hooks/` を `~/.claude/hooks/` にコピー | 上書きコピーで安全 |
| 2. settings.json マージ | Python で JSON 読み→`hooks` キーだけ差し替え→書き戻し | 既存設定を保持 |
| 3. CLAUDE.md インストール | リポジトリ版で上書き (source of truth) | diff で変更なければスキップ |
| 4. GitHub MCP 登録 | `claude mcp add` 実行 | claude CLI がなければスキップ |

**settings.json マージのポイント**:
`autoUpdatesChannel` や feature flags 等のユーザ固有設定を壊さないよう、`hooks` キーだけを差し替える設計。Python の `json` モジュールで安全にマージ。

## 3. テスト結果

### 3.1 Windows Git Bash テスト

| テスト項目 | 結果 | 備考 |
|---|---|---|
| Python 検出 | OK | Store スタブ (exit 49) をスキップし、`Python312/python.exe` にフォールバック |
| Hook 動作 (`ollama pull`) | OK | `2>&1 \| tail -3` が正しく付与 |
| Hook 動作 (`pip install`) | OK | `-q` フラグが正しく付与 (※) |
| settings.json マージ | OK | `autoUpdatesChannel: "latest"` が保持された |
| setup.sh 冪等性 | OK | 2回実行しても設定の重複・破損なし |
| setup.sh 全ステップ | OK | 4ステップすべて正常完了 |

※ `pip install` の直接テストでは、現在アクティブな Hook が Bash ツール経由のコマンドを先に修正するため、テスト用 JSON 内の文字列も変換された。`ollama pull` での単体テストで Hook 動作を確認済み。

### 3.2 setup.sh 実行ログ (Windows)

```
=== claude-dotfiles setup ===
Source:  /c/Users/above/projects/claude-dotfiles
Target:  /c/Users/above/.claude

[1/4] Installing hooks...
  -> Copied hooks to /c/Users/above/.claude/hooks
[2/4] Merging hook settings into settings.json...
  -> Merged hooks into C:/Users/above/.claude/settings.json
[3/4] Installing CLAUDE.md...
  -> CLAUDE.md already up to date
[4/4] Registering GitHub MCP server...
  -> GitHub MCP server registered

=== Setup complete ===
```

### 3.3 未実施テスト

| テスト項目 | 状況 |
|---|---|
| WSL での `setup.sh` 実行 | 未実施 (WSL 環境で別途実行が必要) |
| Linux / macOS での動作 | 未実施 (環境なし) |
| `python3` が正常に動く環境での検出 | 未実施 (WSL で確認予定) |

## 4. Git コミット履歴

```
0289bd4 Add .gitignore for Claude Code project files
f9d99bf Add Windows Python install path fallback
6771bb6 Initial commit: cross-platform Claude Code dotfiles
```

## 5. 残タスク

- [ ] WSL で `bash setup.sh` を実行し、`python3` パスの検出と Hook 動作を確認
- [ ] WSL での Claude Code セッションで `pip install` → `-q` 自動付与を確認
- [ ] (任意) macOS / Linux マシンでの動作確認
- [ ] (任意) Hook ルールの追加 (npm install, apt install 等)
