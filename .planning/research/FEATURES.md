# Feature Research: Coffee Journal App

**Domain:** Specialty coffee journal / brew tracking (iOS)
**Researched:** 2026-02-07
**Confidence:** MEDIUM-HIGH (based on competitor analysis of 8+ apps, SCA standards, and community feedback)

## Feature Landscape

Features are organized by functional category. Within each category, features are classified as Table Stakes (users expect them), Differentiators (competitive advantage), or Anti-Features (deliberately avoid).

---

### 1. Equipment Management

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Brew method library | Every competitor has this. Users own multiple devices and need to associate brews with the right method. | LOW | Beanconqueror ships 30+ preset methods (V60, AeroPress, Espresso, Chemex, French Press, etc.). Allow custom methods too. |
| Grinder tracking | Grind size is the single most impactful variable users adjust brew-to-brew. Not tracking it makes the journal useless. | LOW | Store grinder name, type (burr/blade), and numeric setting. Beanconqueror and iBrew both do this. |
| Custom parameter sets per method | Espresso needs pressure/yield; pour-over needs pour stages; immersion needs steep time. One-size-fits-all forms frustrate users. | MEDIUM | Beanconqueror lets users customize which parameters appear per preparation method. This is critical -- do not ship a flat form. |

#### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Equipment archive with usage stats | "How many brews have I done with my V60 vs Chemex?" Helps users see their own habits. No competitor does this well. | LOW | Track brew count, last used date, favorite beans per method. |
| Equipment photos | Visual library of your setup. Satisfies the "coffee station" aesthetic that specialty enthusiasts care about. | LOW | Beanconqueror supports equipment photos but few users bother. Make it optional and delightful, not required. |

#### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Equipment marketplace / purchase links | "Where to buy" seems helpful | Turns journal into an ad platform. Violates privacy-first promise. Affiliate links erode trust with enthusiast audience. | Link to manufacturer website only, user-provided. |
| Bluetooth scale integration (v1) | Beanconqueror supports 15+ Bluetooth scales for live graphing | Massive engineering effort. Requires BLE stack, per-device protocol handling, real-time data streaming. Beanconqueror is open-source with years of work on this. | Defer to v2+. Manual entry is fine for v1. Consider as a future differentiator. |

---

### 2. Coffee Bean Tracking

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Bean entry with origin details | Core of the journal. Users want to record roaster, origin country, region, variety, processing method, roast level. | MEDIUM | iBrew has a database of 3,000+ roasteries and 2,000+ regions. For v1, user-entered text fields are sufficient; don't build a database. |
| Roast date tracking | Freshness is paramount in specialty coffee. Beans peak 5-21 days post-roast and fade after. Users need to see "days since roast" at a glance. | LOW | Store roast date, compute and display "days since roast" prominently. BeanVault does this well with countdown indicators. |
| Bean photos | Users photograph their bags to remember what they bought. Nearly universal across competitors. | LOW | Camera capture + photo library import. Store in iCloud alongside bean record. |
| Active vs. archived beans | Users cycle through beans. Old ones should not clutter the active list but should remain searchable. | LOW | Beanconqueror has explicit archive. Auto-archive after N days of no use is a nice touch. |

#### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Bean inventory / remaining weight | "How much do I have left?" Auto-deduct dose from bag weight per brew. Know when to reorder. | MEDIUM | BeanVault tracks this. Surprisingly few journal apps do it well. High value for enthusiasts who buy multiple bags. |
| Bag scan / photo OCR | Snap a photo of the bean bag label, auto-extract roaster name, origin, variety, roast date. Reduces data entry friction dramatically. | HIGH | No competitor does this well natively. Apple's Vision framework (on-device OCR) makes this feasible on iOS. This is a genuine differentiator for reducing the #1 user complaint: too much data entry. |
| Bean cost tracking and per-cup cost | "This cup cost me $1.23." Enthusiasts spend $15-25/bag and want to know. | LOW | Store price per bag, compute cost per gram, multiply by dose. Simple math, high perceived value. |
| Freshness indicator | Visual indicator (green/yellow/red) based on days since roast. At a glance, "should I still be using this bean?" | LOW | Simple computed UI element. Configurable thresholds (e.g., peak 7-14 days, acceptable 14-28, stale 28+). |

#### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Built-in roaster/bean database | iBrew has 3,000+ roasteries. Seems useful. | Maintenance nightmare. Stale data. Regional bias (your roaster won't be in it). Requires backend or bundled data. Violates offline-first. | User-entered data with smart autocomplete from their own history. Over time, the user builds their own personalized database. |
| Barcode/UPC scanning for bean lookup | Grocery store coffee has barcodes | Specialty coffee bags rarely have standard UPC codes. Would only work for commercial brands, not the target audience (specialty enthusiasts buying from local roasters). | Photo OCR of the actual label is more useful for specialty bags. |

---

### 3. Brew Logging

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Dose (coffee weight in grams) | Fundamental brewing parameter. Every app tracks this. | LOW | Numeric input with 0.1g precision. |
| Water amount (grams or mL) | Second fundamental parameter. | LOW | Numeric input. Show computed ratio (e.g., "1:16.2") automatically. |
| Brew time | Total contact/extraction time. | LOW | Timer or manual entry in mm:ss format. |
| Water temperature | Critical for extraction. | LOW | Numeric input in C or F with user preference. |
| Grind size setting | Most impactful variable for dialing in. | LOW | Numeric or text (depends on grinder type). |
| Brew ratio display | Users think in ratios (1:15, 1:16). Auto-calculate from dose + water. | LOW | Computed field, not user-entered. Display prominently. |
| Overall rating | Users want to rate "was this good?" quickly. | LOW | 1-5 stars or 1-10 scale. Keep it simple. Beanconqueror uses a numeric score. |
| Freeform notes | "Channeled slightly on left side" -- unstructured observations. | LOW | Text field. Essential for the journaling aspect. |

#### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Integrated brew timer with steps | Start timer, app guides you through pour stages (bloom, first pour, second pour, drawdown). Reduces need for a separate timer app. | MEDIUM | Filtru and Timer.Coffee do this well. Timer.Coffee is open-source with 40+ recipes across 20+ methods. For v1, a simple total-time timer is table stakes; step-by-step guided timer is a differentiator. |
| Method-specific parameter forms | Espresso: yield, pressure, preinfusion time. Pour-over: bloom time, number of pours, total drawdown. Cold brew: steep hours. | MEDIUM | Beanconqueror does this -- parameters are configurable per preparation method. Critical for serious users. Without this, espresso users and pour-over users both feel the form is wrong. |
| Brew from previous recipe | "Repeat yesterday's V60 but change grind from 24 to 22." Clone a previous brew, adjust one variable. | LOW | Huge time saver. Reduces data entry from 2 minutes to 10 seconds. Most users brew the same recipe with small tweaks daily. |
| Water quality parameters | Hardness, TDS, mineral content. Advanced users use specific water recipes (Third Wave Water, etc.) | LOW | Optional fields. Beanconqueror tracks this. Niche but valued by serious enthusiasts. |
| Yield / TDS / extraction % | For espresso: liquid yield in grams. With a refractometer: TDS reading and computed extraction yield. | LOW | Numeric fields. Extraction calculator is a nice computed feature (extraction % = brewed coffee weight * TDS / dose * 100). |

#### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Mandatory fields beyond dose/water | "Enforce data quality" | Users will abandon the app if forced to enter 10 fields for every brew. The #1 failure mode for coffee journal apps is making logging feel like homework. | Make dose + water + rating the only required fields. Everything else optional. Let power users fill in what they want. |
| Real-time flow rate graphing | Beanconqueror does this with Bluetooth scales | Requires BLE integration, real-time charting, scale-specific protocols. Massive scope for v1. | Defer entirely. This is v2+ if ever. |
| Social/community brew sharing | "Share my recipe with friends" | Requires backend infrastructure, moderation, user accounts. Violates privacy-first, offline-first principles. | Export as image/PDF for manual sharing. No social network. |

---

### 4. Tasting & Cupping

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Structured scoring (acidity, body, sweetness) | Core to tasting evaluation. Users want to rate specific dimensions, not just "good/bad." | LOW | Sliders or segmented controls, 1-5 scale. Keep dimensions to 3-5 max for casual use. |
| Flavor tag selection | Users want to tag "blueberry, dark chocolate, citrus" without typing. | MEDIUM | Pre-built tag library organized by the SCA flavor wheel hierarchy. 9 main categories (Fruity, Floral, Sweet, Nutty/Cocoa, Spiced, Green/Vegetative, Sour/Fermented, Roasted, Other) with ~110 specific descriptors at the leaf level. Allow custom tags too. |
| Freeform tasting notes | Not everything fits in structured fields. "Reminded me of that Ethiopian from last month." | LOW | Text field. Searchable later for pattern discovery. |

#### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Interactive flavor wheel UI | Visual, tactile flavor selection using the SCA wheel structure. Tap the center "Fruity" to expand into Berry/Citrus/Tropical, then tap "Berry" to get Blueberry/Strawberry/Blackberry. Beautiful and educational. | HIGH | No iOS coffee app does this well. Most use flat tag lists. An interactive radial wheel would be visually striking and align with the monochrome/e-ink aesthetic. HIGH complexity but HIGH differentiation. Consider for v1.x, not v1. |
| SCA-aligned cupping form | Full SCA protocol: Fragrance/Aroma, Flavor, Aftertaste, Acidity, Body, Balance, Uniformity, Clean Cup, Sweetness, Overall (10 categories, 6-10 scale, 0.25 increments). | MEDIUM | iBrew supports this. The new CVA standard (SCA-103/104) replaces the 2004 form with descriptive + affective assessments. For v1, a simplified version (5-7 dimensions) is sufficient. Full SCA form is a power-user option. |
| Tasting comparison / side-by-side | Compare two brews of the same bean with different parameters. "What did changing grind size from 22 to 18 actually do to acidity?" | MEDIUM | Radar chart comparing scoring dimensions. Beanconqueror has radar graph comparisons. Very valuable for learning. |
| Photo of the cup/pour | Visual journal entry. Latte art, brew color, equipment in action. | LOW | Camera integration. Display in timeline view. Adds the "journal" feel vs. pure "data logging." |

#### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| AI-generated tasting notes | "Tell me what I'm tasting" | Patronizing to enthusiasts. Inaccurate. Undermines the skill-building aspect of developing your palate. | Use AI to surface patterns from YOUR past notes ("You tend to find citrus notes in washed Ethiopian coffees"). |
| Professional Q-grader scoring | "I want to score like a pro" | Q-grading requires calibration, controlled conditions, specific protocols. An app score is not a Q-grade. Pretending otherwise misleads users. | Label it clearly as "personal tasting notes" not "cupping score." Offer SCA-aligned dimensions without claiming certification-level accuracy. |

---

### 5. Sync & Data Management

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| iCloud sync across devices | Users brew on iPhone in kitchen, review on iPad on couch. Seamless sync is expected for any modern iOS app. | MEDIUM | CloudKit with SwiftData is the standard approach. No backend needed. Aligns with privacy-first architecture. |
| Data backup / restore | Users must not lose years of brew data. | MEDIUM | iCloud backup handles this implicitly if using CloudKit. Explicit "export all data" option adds confidence. |
| Data export (JSON/CSV) | Power users want their data. GDPR-adjacent expectation. "It's MY data." | LOW | Export all brews, beans, equipment as JSON or CSV. Beanconqueror supports settings export. iBrew exports to PDF. |

#### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| PDF journal export | "Print my coffee journal." Beautiful, formatted output. iBrew does this. | MEDIUM | Generate paginated PDF with brew details, photos, tasting notes. Aligns with the physical journal aesthetic. |
| Import from other apps | "I'm switching from Beanconqueror." Lower switching cost. | HIGH | Would need to reverse-engineer competitor export formats. Beanconqueror's data format is not publicly documented as a standard. Defer unless user demand is clear. |
| Shareable brew card (image) | Single-brew summary as a shareable image. Instagram-ready without being a social platform. | LOW | Generate a styled image with bean name, parameters, rating, flavor tags. Users share manually. No backend needed. |

#### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Cloud backend / account system | "Sync to web" or "share across platforms" | Requires server infrastructure, user accounts, auth, ongoing hosting costs. Violates privacy-first, offline-first architecture. Creates ongoing liability. | iCloud sync covers the multi-device use case within Apple ecosystem. Web access is not the target. |
| Cross-platform sync (Android) | "My partner uses Android" | iOS-only is the stated scope. CloudKit is Apple-only. Adding Android means a backend. | Export/import via JSON file for one-time transfers if needed. |

---

### 6. Insights & Intelligence

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Basic statistics | Total brews, beans tried, favorite methods, average rating. | LOW | Simple aggregations over local data. Every journal app shows these. |
| Brew history timeline | Chronological list of all brews. Searchable, filterable. | LOW | Core navigation pattern. List view with date, bean name, method, rating. |
| Filter and search | Find "all V60 brews with Ethiopian beans rated 4+" | MEDIUM | Multi-criteria filtering. Requires thoughtful data model with proper indexing. |

#### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Apple Intelligence pattern insights | "You rate washed Ethiopians 0.8 points higher than naturals." "Your best V60 brews use 93C water and grind setting 22-24." On-device ML surfacing patterns the user hasn't noticed. | HIGH | Apple's Foundation Models framework (iOS 26+) provides free on-device LLM inference with structured output. Feed brew history as context, get personalized insights. This is the project's stated core differentiator. Stoic journal app already does this pattern successfully. |
| Brew optimization suggestions | "Try grinding finer -- your last 3 brews with this bean were under-extracted (low TDS, sour notes)." | HIGH | Requires enough data points + domain knowledge encoded in prompts. Foundation Models framework supports tool calling (model can query app data). Build incrementally: start with simple heuristics, add LLM insights later. |
| Year in review / monthly summary | "In January you brewed 47 cups, tried 6 new beans, your top-rated was..." BeanBook does annual summaries. | MEDIUM | Engaging, shareable content. Generates delight and retention. |
| Flavor profile evolution | "Your palate has shifted toward fruity, acidic coffees over the past 6 months." Visualize how preferences change over time. | MEDIUM | Aggregate flavor tags and scores over time. Show trend charts. Requires sufficient data history. |
| Bean recommendation based on preferences | "Based on your high ratings for washed Kenyan coffees, you might enjoy washed Burundi." | HIGH | On-device inference using taste profile and bean attribute correlations. Genuinely novel -- no competitor does this well with on-device ML. |

#### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Cloud-based AI / ChatGPT integration | "Use GPT-4 for insights" | Requires sending personal brew data to external servers. Violates privacy-first promise. Ongoing API costs. Internet dependency. | Apple Foundation Models framework runs entirely on-device. Free inference, no data leaves the device. This is the correct approach. |
| Gamification (badges, streaks, leaderboards) | "Motivate daily logging" | Specialty coffee enthusiasts are intrinsically motivated. Gamification feels patronizing and cheap for this audience. Streaks punish missed days. | Show "gentle" stats like "you've been brewing for 47 days" without shame mechanics. |
| Predictive brew quality scoring | "Predict if this brew will be good before I make it" | Not enough signal. Too many unmeasured variables (bean age day-to-day, water temp accuracy, pour technique). Predictions will be wrong and erode trust. | Show "similar past brews" instead. Let the user draw their own conclusions. |

---

### 7. UI/UX

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Quick brew logging (< 30 seconds) | If logging takes longer than drinking, users stop. The #1 reason coffee journal apps fail is data entry friction. | MEDIUM | Pre-fill from last brew with same method/bean. Minimize taps. Big touch targets. Smart defaults. |
| Dark mode | Standard iOS expectation. Also reduces eye strain for early-morning brewers. | LOW | System-following dark mode. With monochrome design, this is natural. |
| Intuitive navigation | Users should find beans, brews, equipment without thinking. | MEDIUM | Tab bar: Brew (log), Beans, History, Insights. Maximum 4-5 tabs. |

#### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Monochrome / e-ink aesthetic | Stated design goal. No competitor has this. Calm, focused, premium feel. Stands out in a sea of colorful coffee apps. | MEDIUM | Requires disciplined design system. Grayscale palette with occasional accent. Typography-driven hierarchy. Think: Kindle meets coffee journal. |
| Home screen / Lock Screen widgets | "Days since roast" for current bean. "Last brew" summary. Quick-log button. | MEDIUM | WidgetKit supports Home Screen, Lock Screen (AccessoryRectangular, AccessoryCircular, AccessoryInline), and Apple Watch complications with shared code. |
| Apple Watch app / complication | Quick-log a brew rating from your wrist. See current bean freshness. | HIGH | Significant additional surface. Defer to v1.x unless scope allows. Same WidgetKit code can power watch complications. |
| Haptic feedback and micro-interactions | Satisfying tactile response when logging. Premium feel. | LOW | UIFeedbackGenerator for key actions (save brew, rate, complete timer). Small effort, big polish. |
| Siri / Shortcuts integration | "Hey Siri, log a coffee" -- quick voice logging. | MEDIUM | App Intents framework. Define key actions (log brew, check bean freshness, start timer). |

#### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Skeuomorphic coffee-themed UI | "Make it look like a coffee shop" | Dated aesthetic. Competes with content for attention. Hard to maintain. Ages poorly. | Monochrome, typographic, content-first design. Let the coffee photos provide the color and warmth. |
| Onboarding tutorial | "Users need to learn the app" | If you need a tutorial, the app is too complicated. Specialty coffee users are tech-savvy and impatient. | Progressive disclosure. Show the simplest form first. Reveal advanced features as users explore. Empty states that teach by example. |
| Animation-heavy transitions | "Make it feel alive" | Slows down power users who log multiple brews daily. Conflicts with e-ink aesthetic. Drains battery. | Subtle, fast transitions. Prefer instant navigation with micro-animations only on meaningful state changes (save confirmation, timer completion). |

---

## Feature Dependencies

```
[Bean Entry]
    |
    +--requires--> [Brew Log] (every brew references a bean)
    |                  |
    |                  +--requires--> [Tasting Notes] (attached to a brew)
    |                  |
    |                  +--requires--> [Equipment] (brew references method + grinder)
    |                  |
    |                  +--enhances--> [Brew Timer] (optional, starts before brew log)
    |
    +--enhances--> [Bean Inventory] (track remaining weight)
    |
    +--enhances--> [Freshness Indicator] (computed from roast date)

[Brew Log] + [Tasting Notes]
    |
    +--enables--> [Statistics / History] (aggregation over brews)
    |
    +--enables--> [Apple Intelligence Insights] (pattern detection over history)
    |
    +--enables--> [Brew Comparison] (side-by-side requires 2+ brews)
    |
    +--enables--> [Flavor Profile Evolution] (trend over time)

[iCloud Sync]
    |
    +--independent of features above (infrastructure layer)
    +--required before--> [Widgets] (widgets read shared data)

[Data Export]
    |
    +--independent (can be added anytime)
    +--enhances--> [PDF Journal Export]
    +--enhances--> [Shareable Brew Card]
```

### Dependency Notes

- **Bean Entry must exist before Brew Log:** Every brew references a bean. Build bean CRUD first.
- **Equipment must exist before Brew Log:** Every brew references a method and optionally a grinder. Build equipment CRUD first.
- **Brew Log + Tasting is the core loop:** This is what users do daily. Must be fast and frictionless.
- **Statistics require brew history:** Need a critical mass of data (~10+ brews) before insights are meaningful.
- **Apple Intelligence requires substantial history:** Pattern detection needs ~30-50+ brews with consistent attribute recording to produce non-trivial insights.
- **iCloud Sync is infrastructure:** Build early so data model supports it from day one. Retrofitting sync is painful.
- **Widgets depend on shared data container:** App Group and shared SwiftData store must be architected upfront.

---

## MVP Definition

### Launch With (v1)

Minimum viable coffee journal -- enough to replace a paper notebook.

- [ ] **Bean entry** (roaster, origin, variety, process, roast level, roast date, photo) -- core data model
- [ ] **Equipment management** (brew methods, grinders with settings) -- referenced by brews
- [ ] **Brew logging** (dose, water, time, temp, grind, ratio auto-calc, rating, notes) -- the daily action
- [ ] **Method-specific parameter forms** (espresso vs. pour-over vs. immersion) -- prevents "wrong form" frustration
- [ ] **Structured tasting** (acidity/body/sweetness 1-5, flavor tags from SCA wheel, freeform text) -- the journal's value
- [ ] **Brew history with search/filter** -- find and learn from past brews
- [ ] **Clone previous brew** -- reduce daily data entry to seconds
- [ ] **Basic statistics** (total brews, beans tried, top-rated, averages) -- immediate value from data
- [ ] **iCloud sync** -- multi-device from day one (architect for it; don't retrofit)
- [ ] **Dark mode / monochrome design system** -- the visual identity
- [ ] **Roast date freshness indicator** -- simple computed value, high utility

### Add After Validation (v1.x)

Features to add once core journaling is proven and users have data history.

- [ ] **Apple Intelligence insights** -- needs iOS 26+ and user data history to be useful; flagship differentiator but not launch-blocking
- [ ] **Integrated brew timer with step-by-step guidance** -- significant UI work; users can use phone timer for v1
- [ ] **Bean inventory / remaining weight tracking** -- high value, moderate complexity
- [ ] **Interactive flavor wheel UI** -- high differentiation but high complexity; flat tag list works for v1
- [ ] **Home Screen and Lock Screen widgets** -- "days since roast," quick-log button
- [ ] **PDF journal export** -- premium feel, aligns with physical journal aesthetic
- [ ] **Shareable brew card (image)** -- social sharing without social features
- [ ] **Tasting comparison / radar charts** -- needs 2+ brews of same bean to be useful
- [ ] **Bag photo OCR for bean data entry** -- genuine differentiator, Apple Vision framework
- [ ] **Data export (JSON/CSV)** -- user expectation for data ownership

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **Bluetooth scale integration** -- massive engineering effort, Beanconqueror already dominates here
- [ ] **Apple Watch app / complications** -- additional platform surface
- [ ] **Siri / Shortcuts integration** -- voice-driven quick logging
- [ ] **Bean recommendation engine** -- needs large personal dataset
- [ ] **Flavor profile evolution over time** -- needs months of data
- [ ] **Water quality tracking** -- niche, power-user feature
- [ ] **Year in review / monthly summaries** -- needs calendar year of data
- [ ] **Import from other apps** -- only if user demand is clear

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Bean entry with origin details | HIGH | MEDIUM | P1 |
| Brew logging with auto-ratio | HIGH | LOW | P1 |
| Method-specific parameter forms | HIGH | MEDIUM | P1 |
| Structured tasting (sliders + tags) | HIGH | MEDIUM | P1 |
| Clone previous brew | HIGH | LOW | P1 |
| Roast date freshness indicator | HIGH | LOW | P1 |
| iCloud sync | HIGH | MEDIUM | P1 |
| Brew history with search/filter | HIGH | MEDIUM | P1 |
| Basic statistics | MEDIUM | LOW | P1 |
| Monochrome design system | HIGH | MEDIUM | P1 |
| Dark mode | MEDIUM | LOW | P1 |
| Bean inventory tracking | HIGH | MEDIUM | P2 |
| Apple Intelligence insights | HIGH | HIGH | P2 |
| Integrated brew timer (steps) | MEDIUM | MEDIUM | P2 |
| Home/Lock Screen widgets | MEDIUM | MEDIUM | P2 |
| Interactive flavor wheel | MEDIUM | HIGH | P2 |
| Bag photo OCR | HIGH | HIGH | P2 |
| PDF journal export | MEDIUM | MEDIUM | P2 |
| Shareable brew card | LOW | LOW | P2 |
| Data export (JSON/CSV) | MEDIUM | LOW | P2 |
| Tasting comparison charts | MEDIUM | MEDIUM | P2 |
| Bluetooth scale integration | MEDIUM | HIGH | P3 |
| Apple Watch app | LOW | HIGH | P3 |
| Siri / Shortcuts | LOW | MEDIUM | P3 |
| Bean recommendations | MEDIUM | HIGH | P3 |
| Flavor evolution trends | LOW | MEDIUM | P3 |
| Water quality tracking | LOW | LOW | P3 |
| Year in review | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for launch -- the core journal experience
- P2: Should have, add in v1.x -- differentiators and polish
- P3: Nice to have, v2+ -- advanced features requiring maturity

---

## Competitor Feature Analysis

| Feature | Beanconqueror | iBrew Coffee | Filtru | BeanBook | Tastify | Our Approach |
|---------|---------------|--------------|--------|----------|---------|--------------|
| **Platforms** | iOS + Android | iOS + Android | iOS only | iOS | Web | iOS only |
| **Bean tracking** | Detailed, with scan/import | 3,000+ roaster DB | Basic | Photo-based | Sample management | User-entered with OCR assist (v1.x) |
| **Brew logging** | 30+ params, highly customizable | 60+ methods, detailed | Guided with timer | Basic | Cupping-focused | Method-specific forms, clone-from-previous |
| **Tasting** | SCA cupping form, radar charts | 300+ flavor descriptors | Basic notes | Ratings + notes | Full CVA protocol, remote cupping | Structured sliders + SCA flavor tags + freeform |
| **Timer** | Basic | Basic | Step-by-step with visual pour guide | None | None | Basic v1, step-by-step v1.x |
| **BT Scales** | 15+ scale brands | None | 8 scale brands | None | None | None v1, consider v2+ |
| **Analytics** | Charts, spending, consumption | PDF export | None | Year in Review, AI chat | Reports, flavor wheels | Basic stats v1, Apple Intelligence v1.x |
| **Sync** | iCloud backup (iOS) | Unknown | Unknown | Unknown | Cloud | iCloud native with CloudKit |
| **Design** | Functional, dense | Clean, modern | Polished, guided | Minimal, modern | Professional/enterprise | Monochrome, e-ink aesthetic |
| **Pricing** | Free, open-source | Unknown (likely freemium) | Free + PRO tier | Free (likely freemium) | Enterprise SaaS | Free or one-time purchase (TBD) |
| **AI/ML** | None | None | None | AI chatbot | None | Apple Intelligence on-device insights |
| **Privacy** | Local-first, open-source | Unknown | Unknown | Unknown | Cloud-based | Privacy-first, no backend, iCloud only |

### Competitive Positioning

**Beanconqueror** is the power-user champion: open-source, free, incredibly deep with Bluetooth scale integration and 30+ parameters. It wins on raw capability but loses on design polish and onboarding simplicity. It is cross-platform (Ionic/TypeScript).

**iBrew Coffee** has the largest content database (3,000+ roasters, 300+ flavors) but this is a maintenance liability and creates backend dependency.

**Filtru** has the best guided brewing experience with visual pour guides and Bluetooth scale graphing, but is timer-first, journal-second.

**BeanBook** is the newest entrant with the most modern design sensibility and AI features (chatbot), but appears thin on brew parameter depth.

**Tastify** targets professionals (remote cupping sessions, CVA protocol) -- different audience entirely.

**Our opportunity:** Native iOS app with the depth of Beanconqueror, the design sensibility of BeanBook, and a genuine differentiator in Apple Intelligence on-device insights. No competitor combines deep brew tracking + beautiful monochrome design + privacy-first on-device AI. The gap in the market is a premium-feeling, privacy-respecting iOS journal that makes logging fast and insights automatic.

---

## Sources

### Competitor Products Analyzed
- [Beanconqueror](https://beanconqueror.com/) - open-source coffee tracking app (HIGH confidence)
- [Beanconqueror GitHub](https://github.com/graphefruit/Beanconqueror) - source code and README (HIGH confidence)
- [iBrew Coffee](https://ibrew.coffee/) - specialty coffee journal (MEDIUM confidence)
- [Filtru](https://getfiltru.com/) - brew guide and timer app (MEDIUM confidence)
- [BeanBook](https://beanbook.app/) - modern coffee journal (MEDIUM confidence)
- [Tastify](https://www.tastify.com/features) - professional cupping platform (MEDIUM confidence)
- [BeanVault](https://coffeebeantracker.com/features/) - bean inventory tracker (LOW confidence)

### Industry Standards
- [SCA Coffee Taster's Flavor Wheel](https://sca.coffee/research/coffee-tasters-flavor-wheel) - 9 main categories, ~110 descriptors (HIGH confidence)
- [SCA CVA Cupping Standards](https://sca.coffee/sca-news/sca-new-cva-cupping-standards) - new SCA-102/103/104 standards replacing 2004 form (HIGH confidence)
- [SCA Flavor Wheel Deep Dive - Steel Oak Coffee](https://steeloakcoffee.com/blogs/specialty-coffee-journal/exploring-the-coffee-tasters-flavor-wheel) (MEDIUM confidence)

### Apple Platform
- [Apple Foundation Models Framework](https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/) - on-device LLM, free inference, structured output, iOS 26+ (HIGH confidence)
- [WidgetKit Documentation](https://developer.apple.com/widgets/) - Home Screen, Lock Screen, Watch complications (HIGH confidence)

### Market Research
- [Homegrounds Best Coffee Apps](https://www.homegrounds.co/best-coffee-apps/) - roundup of 7 apps with pros/cons (MEDIUM confidence)
- [CartaCoffee 8 Best Apps](https://www.cartacoffee.com/blogs/island-blog/8-best-apps-for-coffee-enthusiasts) (LOW confidence)
- [Timer.Coffee](https://www.timer.coffee/) - open-source brew timer with 40+ recipes (MEDIUM confidence)

---
*Feature research for: Coffee Journal iOS App*
*Researched: 2026-02-07*
