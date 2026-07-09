---
name: Analytics tab shows dummy data
description: The Analytics tab is not wired to the backend — it renders generated fake data
---

# Analytics tab is dummy data

The Analytics tab does not fetch from the backend. Its controller loads `AnalyticsDummyData.generateDummyData()` on a simulated delay, so every chart/number on that screen is fabricated.

**Why it matters:** If the user asks "why are my analytics wrong / not matching my real missions," the answer is that the screen was never connected to real data — not a calculation bug. Wiring it up requires real backend aggregation endpoints (or computing from the missions/clients already fetched elsewhere) and is a product decision the user must approve.

**How to apply:** Don't "fix" analytics numbers by tweaking the dummy generator. Either connect it to real data (needs backend or client-side aggregation of existing mission data) or clearly label it as sample data.
