import { registerFlareMessages, type FlareMessageTree } from "./messages";

/** Shared labels for Japanese administrative lists and plugin pages. */
const messages: FlareMessageTree = {
  filterBar: {
    label: "絞り込み条件",
    search: "検索",
    reset: "リセット",
    more: "その他の条件",
    moreCount: "その他の条件（{count}）",
    less: "条件を折りたたむ",
  },
  dataTable: {
    actions: "操作",
    columns: "列の設定",
    empty: "データはありません",
    range: "{total} 件中 {from}～{to} 件",
    perPage: "1ページ {size} 件",
    pagination: "ページ切り替え",
    previous: "前のページ",
    next: "次のページ",
  },
  pluginView: {
    detail: "詳細を表示",
    loading: "読み込み中",
    empty: "記録はありません",
    all: "すべて",
    retry: "再試行",
  },
};

export function registerFlareAdminJapanese(): void {
  registerFlareMessages("ja-JP", messages);
}
