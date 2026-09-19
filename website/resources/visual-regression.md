---
title: Visual Regression
layout: false
---

# Visual regression

The shared core fixture below is rendered by the published Vue component entry point. Its light,
dark, large-text, accessibility, and brand-theme captures are compared in Playwright.

<script setup>
import RcVisualFixture from '../.vitepress/theme/demos/RcVisualFixture.vue'
</script>

<RcVisualFixture />
