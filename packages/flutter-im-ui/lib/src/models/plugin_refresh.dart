bool flarePluginMayRefresh({
  required bool visible,
  required bool foreground,
  required bool loading,
  required bool refreshing,
  required bool busy,
  required bool interaction,
}) => visible && foreground && !loading && !refreshing && !busy && !interaction;
