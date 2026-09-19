#!/bin/sh
# Launches Playwright's Chromium with macOS classic (always-visible) scrollers.
#
# macOS picks overlay or classic scrollers from "Show scroll bars: automatically",
# which flips with whether a mouse is attached. Overlay scrollers drop the
# `scrollbar-gutter: stable` gutter, so the same page renders 15 px wider or
# narrower on the same machine. `-AppleShowScrollBars Always` sets the preference
# in this process's argument domain only; no system setting changes.
exec "$FLARE_PLAYWRIGHT_CHROMIUM" "$@" -AppleShowScrollBars Always
