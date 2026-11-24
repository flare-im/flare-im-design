import { registerFlareMessages } from "./messages";

export function registerFlarePluginJapanese(): void {
  registerFlareMessages("ja-JP", {
    common: { loading: "読み込み中", retry: "再試行", cancel: "キャンセル", confirm: "確認" },
    contactPicker: {
      selectedCount: "{count}人を選択中",
      removeSelection: "{name}の選択を解除",
      title: "連絡先を選択",
      friends: "友達",
      groupMembers: "グループのメンバー",
      search: "検索",
      empty: "連絡先がありません",
      noResults: "該当する連絡先がありません",
      selfSuffix: "（自分）",
      confirm: "確定",
      cancel: "キャンセル",
    },
    pluginForm: {
      required: "必須項目です",
      tooLong: "文字数の上限を超えています",
      outOfRange: "指定範囲外です",
      tooFewItems: "{n}件以上選択してください",
      tooManyItems: "{n}件まで選択できます",
      duplicateItem: "同じ項目を複数選択できません",
      invalid: "形式が正しくありません",
      chooseMembers: "選択",
      date: "日付を選択",
      time: "時刻を選択",
      cancel: "キャンセル",
    },
  });
}
