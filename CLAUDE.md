# グローバル開発ルール

## トークン節約

- コミットは `/commit` スキルを使うこと（手動で git status/diff/add/commit しない）
- subagent で定型タスク（テスト追加、ドキュメント更新、lint 実行等）は `model: "haiku"` を指定する
- 設計判断が複数ある実装タスクでは EnterPlanMode を使う
