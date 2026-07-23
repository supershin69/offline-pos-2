# Portfolio Website Design Specification

**Version:** 1.0
**Purpose:** A complete design and implementation guideline for AI assistants and human developers.

---

# 1. Design Philosophy

This portfolio is **not** intended to impress visitors with flashy effects.

Its primary goal is to communicate:

- Reliability
- Professionalism
- Engineering quality
- Attention to detail
- Trustworthiness
- Elegance

The design should make visitors think:

> "This developer builds reliable custom software."

The website should feel like a combination of:

- Apple's elegance
- GitHub's practicality and intuitiveness

Every design decision should support clarity instead of visual spectacle.

---

# 2. Core Principles

## Precision

Everything should feel intentional.

Avoid arbitrary spacing, sizing, or inconsistent styling.

Consistency builds trust.

---

## Simplicity

Do not decorate for decoration's sake.

Every animation, border, shadow, and color should have a purpose.

---

## Readability First

Content is the hero.

Design supports the content.

---

## Confidence Through Restraint

Avoid trying too hard.

A restrained interface feels more professional than one full of visual effects.

---

# 3. Theme

The website supports:

- Light
- Dark
- System (default)

The initial theme should follow the user's operating system.

There must never be a flash of the wrong theme during loading.

If a manual theme selector exists:

- System
- Light
- Dark

Persist the user's selection.

---

# 4. Color Philosophy

Neutral colors dominate.

Accent colors should be used sparingly.

Accent colors exist only to communicate interaction.

Never use accent colors as decoration.

---

## Suggested Palette

### Dark

Background:

- #0D1117

Surface:

- #161B22

Primary Text:

- #F5F5F5

Secondary Text:

- #9CA3AF

Border:

- rgba(255,255,255,0.08)

Primary Accent:

- #2563EB

---

### Light

Background:

- #FFFFFF

Surface:

- #F8FAFC

Primary Text:

- #111827

Secondary Text:

- #6B7280

Border:

- rgba(0,0,0,0.08)

Primary Accent:

- #2563EB

---

# 5. Typography

Preferred fonts:

- Geist
- Inter
- SF Pro (fallback if available)

Avoid decorative fonts.

Typography should feel modern, elegant, and highly readable.

---

# 6. Spacing System

**All spacing values MUST be multiples of 4.**

Never invent random values.

Use this scale only.

```
4
8
12
16
20
24
28
32
40
48
56
64
80
96
128
160
192
```

Examples

Small spacing:

- 8
- 12
- 16

Component padding:

- 16
- 20
- 24

Section spacing:

- 64
- 80
- 96

Hero spacing:

- 128
- 160

---

# 7. Border Radius

**All border radius values MUST be multiples of 4.**

Preferred values:

Buttons:

- 8px

Inputs:

- 8px

Cards:

- 12px

Images:

- 12px

Dialogs:

- 16px

Avoid:

- perfectly square corners
- overly rounded corners

The interface should feel modern but not playful.

---

# 8. Shadows

Very subtle.

Used only to improve hierarchy.

Never create floating UI.

---

# 9. Layout

The website should use centered content.

Example:

```
Full Width Background

──────────────────────────────

       Centered Content

──────────────────────────────
```

Background stretches across the viewport.

Content stays centered.

Maximum content width should be consistent throughout the site.

Suggested maximum width:

```
1280px
```

---

# 10. Grid

Desktop:
12-column grid

Tablet:
8-column grid

Mobile:
4-column grid

Use consistent gutters.

---

# 11. Responsive Philosophy

The mobile experience must feel equally elegant.

Do NOT simply shrink desktop.

Instead:

Re-layout intelligently.

Maintain breathing room.

Increase readability.

Respect touch targets.

---

Minimum touch target:

```
44px
```

---

# 12. Animation Philosophy

Animation level:

5/10

Elegant.

Purposeful.

Never distracting.

---

Animation duration

Fast:
150ms

Normal:
200ms

Large transitions:
300ms

Slow reveals:
400ms

Avoid animations longer than 500ms.

---

Animation easing

Prefer smooth easing.

No bouncing.

No elastic effects.

---

Page Load

Hero:

Fade + slight upward movement.

Navigation:

Fade in.

Sections:

Reveal on scroll.

---

Hover

Cards:

- Lift slightly
- Shadow increases
- Border brightens

Buttons:

- Slight background adjustment
- Scale down slightly when pressed

---

Layout

Filtering projects:

Smooth rearrangement.

Pagination:

Smooth fade transition.

Expansion:

Animate height naturally.

---

# 13. Micro Interactions

Use many small interactions instead of large animations.

Examples:

- Animated underline
- Smooth hover states
- Focus rings
- Card elevation
- Image fade-in
- Active navigation indicator
- Search input focus animation
- Filter chip transitions
- Pagination transitions

Everything should feel alive without being distracting.

---

# 14. Things To Avoid

Never use:

- Neon gradients
- Heavy glassmorphism
- Giant glowing blobs
- Rainbow colors
- Comic fonts
- Auto-playing videos
- Particle backgrounds
- Excessive parallax
- Loud animations
- Unnecessary motion
- Busy interfaces

---

# 15. Homepage Structure

Hero

↓

Services

↓

Featured Projects

↓

Technical Expertise

↓

About

↓

Contact

---

# 16. Hero

Headline should focus on value first.

Example philosophy:

Reliable Custom Software,
Built with Precision.

Then introduce the developer.

Example:

I'm Shin Thant, a full-stack software engineer specializing in custom web, mobile, and backend systems.

Primary CTA

View Projects

Secondary CTA

Contact Me

---

# 17. Projects

Projects are represented by engineering cards.

Each card opens a full case study.

Card contains:

- Cover image
- Title
- Short description
- Technology chips
- Read Case Study

---

# 18. Case Studies

Case studies are CMS-driven.

The author creates them through an admin panel.

Content should support arbitrary ordering.

Example:

Title

↓

Text

↓

Image

↓

Text

↓

Image

↓

Text

The renderer simply displays blocks in sequence.

Do not force a rigid template.

---

# 19. Images

Images must preserve their original aspect ratio.

Never crop screenshots to satisfy layouts.

Instead:

- Downscale if necessary
- Preserve proportions
- Center horizontally
- Allow height to vary naturally

Containers should blend into the page background rather than forcing images into fixed-height boxes.

---

# 20. Search & Filtering

Projects should support:

Search by:

- Project name

Filter by:

- Project type

Examples:

- POS
- E-commerce
- Inventory
- ERP
- Internal Tools

Sorting:

- Newest
- Oldest
- Recently Updated

Pagination required.

Design should scale gracefully as the project library grows.

---

# 21. Icons

Use Lucide outline icons.

Avoid filled icon sets.

Avoid skeuomorphic icons.

---

# 22. Accessibility

Minimum contrast should satisfy WCAG AA.

Keyboard navigation must be fully supported.

Visible focus indicators are required.

Animations should respect `prefers-reduced-motion`.

Semantic HTML is required.

Images require alt text.

---

# 23. Performance

Performance is part of the design.

Optimize:

- Images
- Fonts
- Animations
- Bundle size

Use lazy loading where appropriate.

Animations should remain smooth on mid-range mobile devices.

---

# 24. Design Checklist

Every screen should answer YES to these questions:

✓ Does it feel elegant?

✓ Does it feel trustworthy?

✓ Is everything aligned?

✓ Is spacing consistent?

✓ Are interactions subtle?

✓ Is content easy to read?

✓ Does mobile feel equally polished?

✓ Does every animation have a purpose?

✓ Does this look like someone who builds professional software?

---

# 25. AI Implementation Rules

When generating UI:

DO:

- Follow the spacing scale.
- Use multiples of 4 for all spacing and border radii.
- Prefer whitespace over clutter.
- Preserve image aspect ratios.
- Keep animations subtle.
- Maintain consistency.
- Design mobile first-class, not as an afterthought.

DO NOT:

- Invent random spacing values.
- Overuse the accent color.
- Add decorative visual effects.
- Introduce unnecessary animations.
- Sacrifice readability for aesthetics.

---

# Final Design Statement

This portfolio should feel like the digital equivalent of a well-engineered product.

Visitors should leave believing that the developer values quality, maintainability, and thoughtful execution—not because the site says so, but because every design decision quietly demonstrates it.
