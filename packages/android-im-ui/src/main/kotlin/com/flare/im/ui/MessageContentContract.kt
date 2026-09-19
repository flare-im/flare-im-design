package com.flare.im.ui

enum class FlareMessageContentCapability {
    Select, Copy, OpenLink, HorizontalScroll, Open, Save, Retry, Zoom, Swipe,
    Play, Pause, Fullscreen, Seek, Reveal, Vote, ToggleTask, JumpToOriginal,
    OpenThread, OpenOnce,
}

enum class FlareMessageContentFamily {
    Text, RichText, Code, Image, Video, Audio, File, Location, Card, Link,
    Poll, Task, Calendar, MiniApp, Topic, System, Forward, Reply, Thread, Treatment,
}

enum class FlareMessageContentKind(
    val wireType: String?,
    val family: FlareMessageContentFamily,
    val capabilities: Set<FlareMessageContentCapability>,
) {
    Text("text", FlareMessageContentFamily.Text, setOf(FlareMessageContentCapability.Select, FlareMessageContentCapability.Copy)),
    RichText("rich_text", FlareMessageContentFamily.RichText, setOf(FlareMessageContentCapability.Select, FlareMessageContentCapability.Copy, FlareMessageContentCapability.OpenLink)),
    Markdown("rich_text", FlareMessageContentFamily.RichText, setOf(FlareMessageContentCapability.Select, FlareMessageContentCapability.Copy, FlareMessageContentCapability.OpenLink)),
    Code("rich_text", FlareMessageContentFamily.Code, setOf(FlareMessageContentCapability.Select, FlareMessageContentCapability.Copy, FlareMessageContentCapability.HorizontalScroll)),
    Image("image", FlareMessageContentFamily.Image, setOf(FlareMessageContentCapability.Open, FlareMessageContentCapability.Save, FlareMessageContentCapability.Retry, FlareMessageContentCapability.Zoom)),
    MultiImage("image_group", FlareMessageContentFamily.Image, setOf(FlareMessageContentCapability.Open, FlareMessageContentCapability.Save, FlareMessageContentCapability.Retry, FlareMessageContentCapability.Zoom, FlareMessageContentCapability.Swipe)),
    Video("video", FlareMessageContentFamily.Video, setOf(FlareMessageContentCapability.Play, FlareMessageContentCapability.Pause, FlareMessageContentCapability.Fullscreen, FlareMessageContentCapability.Save, FlareMessageContentCapability.Retry)),
    Audio("audio", FlareMessageContentFamily.Audio, setOf(FlareMessageContentCapability.Play, FlareMessageContentCapability.Pause, FlareMessageContentCapability.Seek, FlareMessageContentCapability.Retry)),
    File("file", FlareMessageContentFamily.File, setOf(FlareMessageContentCapability.Open, FlareMessageContentCapability.Save, FlareMessageContentCapability.Reveal, FlareMessageContentCapability.Retry)),
    Location("location", FlareMessageContentFamily.Location, setOf(FlareMessageContentCapability.Open)),
    ContactCard("card", FlareMessageContentFamily.Card, setOf(FlareMessageContentCapability.Open)),
    LinkPreview("link_card", FlareMessageContentFamily.Link, setOf(FlareMessageContentCapability.Open, FlareMessageContentCapability.Copy)),
    Poll("vote", FlareMessageContentFamily.Poll, setOf(FlareMessageContentCapability.Vote)),
    Task("task", FlareMessageContentFamily.Task, setOf(FlareMessageContentCapability.ToggleTask, FlareMessageContentCapability.Open)),
    CalendarEvent("schedule", FlareMessageContentFamily.Calendar, setOf(FlareMessageContentCapability.Open)),
    MiniApp("mini_program", FlareMessageContentFamily.MiniApp, setOf(FlareMessageContentCapability.Open)),
    Topic("custom", FlareMessageContentFamily.Topic, setOf(FlareMessageContentCapability.Open)),
    System("system", FlareMessageContentFamily.System, emptySet()),
    Notice("notification", FlareMessageContentFamily.System, setOf(FlareMessageContentCapability.Open)),
    Forward("forward", FlareMessageContentFamily.Forward, setOf(FlareMessageContentCapability.Open)),
    MergedForward("forward", FlareMessageContentFamily.Forward, setOf(FlareMessageContentCapability.Open)),
    Reply("quote", FlareMessageContentFamily.Reply, setOf(FlareMessageContentCapability.JumpToOriginal)),
    ThreadRoot("thread", FlareMessageContentFamily.Thread, setOf(FlareMessageContentCapability.OpenThread)),
    Ephemeral(null, FlareMessageContentFamily.Treatment, emptySet()),
    ReadOnce(null, FlareMessageContentFamily.Treatment, setOf(FlareMessageContentCapability.OpenOnce)),
    BurnAfterRead(null, FlareMessageContentFamily.Treatment, setOf(FlareMessageContentCapability.OpenOnce)),
}

data class FlareMessageContentContract(
    val kind: FlareMessageContentKind,
    val wireType: String? = kind.wireType,
    val family: FlareMessageContentFamily = kind.family,
    val capabilities: Set<FlareMessageContentCapability> = kind.capabilities,
)

fun resolveMessageContentContract(kind: FlareMessageContentKind) = FlareMessageContentContract(kind)
