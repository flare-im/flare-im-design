<script setup>
import { ref } from 'vue';
import { FlareRecentSearches, FlareSearchPanel } from "@flare-im/vue-ui/components";
import { flareRememberSearch } from "@flare-im/vue-ui/contracts";
import DemoStage from './DemoStage.vue';

// 搜索页的空闲态:最近搜索放在 page 布局的 FlareSearchPanel 的 idle 插槽里,点一条立即搜索。
// 宿主持有这份列表(这里就是一个 ref);记哪些、去重、上限是 kit 的 flareRememberSearch。
const recent = ref(['周屿', '发版协调', '设计评审纪要']);
const kinds = { all: '全部', contact: '联系人', group: '群聊', message: '聊天记录' };
const people = ['周屿', '周一帆', '周舟', '周末', '周知', '周全', '周详', '周密', '周到'].map((title, index) => ({ id: `u${index}`, kind: 'contact', title }));
const snapshot = ref({ criteria: { query: '', filterId: 'all' }, state: 'idle', groups: [] });

function search(criteria) {
  recent.value = flareRememberSearch(recent.value, criteria.query);
  const scoped = criteria.filterId !== 'all';
  snapshot.value = {
    criteria,
    state: 'success',
    groups: [
      { kind: 'contact', label: '联系人', items: scoped ? people : people.slice(0, 2), hasMore: !scoped },
      ...(criteria.filterId === 'all' || criteria.filterId === 'message'
        ? [{ kind: 'message', label: '聊天记录', items: [{ id: 'm1', kind: 'message', title: '周屿', subtitle: `${criteria.query} 的交互稿发你了`, meta: '9/14' }] }]
        : []),
    ].filter((group) => criteria.filterId === 'all' || group.kind === criteria.filterId),
  };
}
function leave() {
  snapshot.value = { criteria: { query: '', filterId: 'all' }, state: 'idle', groups: [] };
}
</script>
<template>
  <DemoStage>
    <div class="recent-demo" data-recent-searches-demo>
      <FlareSearchPanel layout="page" :snapshot="snapshot" :filters="kinds" search-text="搜索联系人、群聊、聊天记录" idle-text="输入关键字，搜索联系人、群聊和聊天记录" require-query @search="search" @cancel="leave">
        <template v-if="recent.length" #idle="{ search: searchNow }">
          <FlareRecentSearches :items="recent" @pick="searchNow" @clear="recent = []" />
        </template>
      </FlareSearchPanel>
    </div>
  </DemoStage>
</template>
<style scoped>
/* 一张手机搜索页的高度:面板是整页(宿主给高度),页头不滚,只有结果在它下面滚。 */
.recent-demo { width: 100%; max-width: 390px; height: 420px; margin-inline: auto; overflow: hidden; border: 1px solid var(--flare-color-border-secondary); border-radius: var(--flare-size-radius-lg); background: var(--flare-color-bg-primary); }
</style>
