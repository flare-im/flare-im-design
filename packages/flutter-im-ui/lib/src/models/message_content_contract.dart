enum FlareMessageContentKind {
  text,
  richText,
  markdown,
  code,
  image,
  multiImage,
  video,
  audio,
  file,
  location,
  contactCard,
  linkPreview,
  poll,
  task,
  calendarEvent,
  miniApp,
  topic,
  system,
  notice,
  forward,
  mergedForward,
  reply,
  threadRoot,
  ephemeral,
  readOnce,
  burnAfterRead,
}

enum FlareMessageContentFamily {
  text,
  richText,
  code,
  image,
  video,
  audio,
  file,
  location,
  card,
  link,
  poll,
  task,
  calendar,
  miniApp,
  topic,
  system,
  forward,
  reply,
  thread,
  treatment,
}

enum FlareMessageContentCapability {
  select,
  copy,
  openLink,
  horizontalScroll,
  open,
  save,
  retry,
  zoom,
  swipe,
  play,
  pause,
  fullscreen,
  seek,
  reveal,
  vote,
  toggleTask,
  jumpToOriginal,
  openThread,
  openOnce,
}

class FlareMessageContentContract {
  const FlareMessageContentContract({
    required this.kind,
    required this.family,
    this.wireType,
    this.capabilities = const {},
  });
  final FlareMessageContentKind kind;
  final String? wireType;
  final FlareMessageContentFamily family;
  final Set<FlareMessageContentCapability> capabilities;
}

FlareMessageContentContract resolveMessageContentContract(
  FlareMessageContentKind kind,
) {
  switch (kind) {
    case FlareMessageContentKind.text:
      return _c(kind, 'text', FlareMessageContentFamily.text, {
        FlareMessageContentCapability.select,
        FlareMessageContentCapability.copy,
      });
    case FlareMessageContentKind.richText:
      return _rich(kind);
    case FlareMessageContentKind.markdown:
      return _rich(kind);
    case FlareMessageContentKind.code:
      return _c(kind, 'rich_text', FlareMessageContentFamily.code, {
        FlareMessageContentCapability.select,
        FlareMessageContentCapability.copy,
        FlareMessageContentCapability.horizontalScroll,
      });
    case FlareMessageContentKind.image:
      return _media(kind, 'image', FlareMessageContentFamily.image, {
        FlareMessageContentCapability.open,
        FlareMessageContentCapability.save,
        FlareMessageContentCapability.retry,
        FlareMessageContentCapability.zoom,
      });
    case FlareMessageContentKind.multiImage:
      return _media(kind, 'image_group', FlareMessageContentFamily.image, {
        FlareMessageContentCapability.open,
        FlareMessageContentCapability.save,
        FlareMessageContentCapability.retry,
        FlareMessageContentCapability.zoom,
        FlareMessageContentCapability.swipe,
      });
    case FlareMessageContentKind.video:
      return _media(kind, 'video', FlareMessageContentFamily.video, {
        FlareMessageContentCapability.play,
        FlareMessageContentCapability.pause,
        FlareMessageContentCapability.fullscreen,
        FlareMessageContentCapability.save,
        FlareMessageContentCapability.retry,
      });
    case FlareMessageContentKind.audio:
      return _media(kind, 'audio', FlareMessageContentFamily.audio, {
        FlareMessageContentCapability.play,
        FlareMessageContentCapability.pause,
        FlareMessageContentCapability.seek,
        FlareMessageContentCapability.retry,
      });
    case FlareMessageContentKind.file:
      return _media(kind, 'file', FlareMessageContentFamily.file, {
        FlareMessageContentCapability.open,
        FlareMessageContentCapability.save,
        FlareMessageContentCapability.reveal,
        FlareMessageContentCapability.retry,
      });
    case FlareMessageContentKind.location:
      return _open(kind, 'location', FlareMessageContentFamily.location);
    case FlareMessageContentKind.contactCard:
      return _open(kind, 'card', FlareMessageContentFamily.card);
    case FlareMessageContentKind.linkPreview:
      return _c(kind, 'link_card', FlareMessageContentFamily.link, {
        FlareMessageContentCapability.open,
        FlareMessageContentCapability.copy,
      });
    case FlareMessageContentKind.poll:
      return _c(kind, 'vote', FlareMessageContentFamily.poll, {
        FlareMessageContentCapability.vote,
      });
    case FlareMessageContentKind.task:
      return _c(kind, 'task', FlareMessageContentFamily.task, {
        FlareMessageContentCapability.toggleTask,
        FlareMessageContentCapability.open,
      });
    case FlareMessageContentKind.calendarEvent:
      return _open(kind, 'schedule', FlareMessageContentFamily.calendar);
    case FlareMessageContentKind.miniApp:
      return _open(kind, 'mini_program', FlareMessageContentFamily.miniApp);
    case FlareMessageContentKind.topic:
      return _open(kind, 'custom', FlareMessageContentFamily.topic);
    case FlareMessageContentKind.system:
      return _c(kind, 'system', FlareMessageContentFamily.system, {});
    case FlareMessageContentKind.notice:
      return _open(kind, 'notification', FlareMessageContentFamily.system);
    case FlareMessageContentKind.forward:
      return _open(kind, 'forward', FlareMessageContentFamily.forward);
    case FlareMessageContentKind.mergedForward:
      return _open(kind, 'forward', FlareMessageContentFamily.forward);
    case FlareMessageContentKind.reply:
      return _c(kind, 'quote', FlareMessageContentFamily.reply, {
        FlareMessageContentCapability.jumpToOriginal,
      });
    case FlareMessageContentKind.threadRoot:
      return _c(kind, 'thread', FlareMessageContentFamily.thread, {
        FlareMessageContentCapability.openThread,
      });
    case FlareMessageContentKind.ephemeral:
      return _c(kind, null, FlareMessageContentFamily.treatment, {});
    case FlareMessageContentKind.readOnce:
      return _once(kind);
    case FlareMessageContentKind.burnAfterRead:
      return _once(kind);
  }
}

FlareMessageContentContract _c(
  FlareMessageContentKind kind,
  String? wireType,
  FlareMessageContentFamily family,
  Set<FlareMessageContentCapability> capabilities,
) => FlareMessageContentContract(
  kind: kind,
  wireType: wireType,
  family: family,
  capabilities: capabilities,
);
FlareMessageContentContract _rich(FlareMessageContentKind kind) =>
    _c(kind, 'rich_text', FlareMessageContentFamily.richText, {
      FlareMessageContentCapability.select,
      FlareMessageContentCapability.copy,
      FlareMessageContentCapability.openLink,
    });
FlareMessageContentContract _media(
  FlareMessageContentKind kind,
  String wireType,
  FlareMessageContentFamily family,
  Set<FlareMessageContentCapability> capabilities,
) => _c(kind, wireType, family, capabilities);
FlareMessageContentContract _open(
  FlareMessageContentKind kind,
  String wireType,
  FlareMessageContentFamily family,
) => _c(kind, wireType, family, {FlareMessageContentCapability.open});
FlareMessageContentContract _once(FlareMessageContentKind kind) => _c(
  kind,
  null,
  FlareMessageContentFamily.treatment,
  {FlareMessageContentCapability.openOnce},
);
