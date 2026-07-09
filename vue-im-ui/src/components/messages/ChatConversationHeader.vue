<template>
  <header class="im-chat-header">
    <div class="im-chat-header__identity">
      <slot name="identity" />
    </div>
    <div class="im-chat-header__actions">
      <slot name="actions" />
    </div>
  </header>
</template>

<style scoped>
.im-chat-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  min-height: var(--layout-header, 60px);
  min-width: 0;
  padding: 8px 16px;
  border-bottom: 1px solid var(--im-chat-hdr-border, var(--flare-color-border-primary, #e7e9ee));
  background: var(--im-chat-hdr-bg, var(--flare-color-bg-primary, #ffffff));
  box-shadow: none;
}

.im-chat-header__identity {
  display: flex;
  align-items: center;
  min-width: 0;
  flex: 1;
}

.im-chat-header__actions {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-shrink: 0;
}

@media (min-width: 900px) {
  .im-chat-header {
    min-height: 62px;
    padding-inline: 18px;
  }
}
</style>
