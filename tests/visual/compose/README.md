# Compose screenshot runner

`RcScreenshotHarnessTest` is the active AndroidX Compose pixel gate. It captures
the Activity's visible frame, excluding nondeterministic system bars, and compares
ARGB pixels against three checked-in baselines: light, dark, and 200% text. The gate
permits only font-raster noise (at most 0.5% changed pixels and at most two levels per
channel); any larger color or geometry delta fails.

`runner.json` pins API 35, Pixel 9 density (420 dpi), `en-US`, and disabled
animations. Baselines were captured and compared on `Pixel_9_API_35`; changing
the emulator profile is a baseline migration and requires visual review.
