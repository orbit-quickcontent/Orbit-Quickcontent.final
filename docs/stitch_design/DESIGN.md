---
name: Kinetic Noir
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#393939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#bbc9cf'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#859399'
  outline-variant: '#3c494e'
  surface-tint: '#47d6ff'
  primary: '#a5e7ff'
  on-primary: '#003543'
  primary-container: '#00d2ff'
  on-primary-container: '#00566a'
  inverse-primary: '#00677f'
  secondary: '#edb1ff'
  on-secondary: '#520070'
  secondary-container: '#6e208c'
  on-secondary-container: '#e498ff'
  tertiary: '#e3d7ff'
  on-tertiary: '#3a0093'
  tertiary-container: '#cab6ff'
  on-tertiary-container: '#5d00e1'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#b6ebff'
  primary-fixed-dim: '#47d6ff'
  on-primary-fixed: '#001f28'
  on-primary-fixed-variant: '#004e60'
  secondary-fixed: '#f9d8ff'
  secondary-fixed-dim: '#edb1ff'
  on-secondary-fixed: '#320046'
  on-secondary-fixed-variant: '#6e208c'
  tertiary-fixed: '#e9ddff'
  tertiary-fixed-dim: '#cfbdff'
  on-tertiary-fixed: '#22005d'
  on-tertiary-fixed-variant: '#5300cc'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
typography:
  display-lg:
    fontFamily: Montserrat
    fontSize: 48px
    fontWeight: '800'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Montserrat
    fontSize: 32px
    fontWeight: '800'
    lineHeight: '1.2'
  headline-md:
    fontFamily: Montserrat
    fontSize: 24px
    fontWeight: '700'
    lineHeight: '1.3'
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: '1.5'
  label-caps:
    fontFamily: Space Grotesk
    fontSize: 12px
    fontWeight: '700'
    lineHeight: '1.0'
    letterSpacing: 0.1em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  container-max: 1200px
  gutter: 1.5rem
  margin-mobile: 1rem
  stack-sm: 0.5rem
  stack-md: 1.5rem
  stack-lg: 3rem
---

## Brand & Style

This design system is built for a premium, high-energy videography marketplace. It balances technical precision with cinematic flair, targeting professional creators and brands who value speed and high-end production quality.

The aesthetic is **Modern Dark Mode** with **Glassmorphic** influences. It utilizes deep "Pitch Black" foundations to make content and vibrant gradients pop. The emotional response is one of elite access, innovation, and creative momentum. Visuals are characterized by high-contrast typography, glowing neon accents, and depth created through subtle tonal layering and vibrant background blurs.

## Colors

The palette is anchored in a true black (`#000000`) to provide an infinite canvas for cinematic content. 

- **Primary & Secondary:** A high-vibrancy duo of Neon Blue and Electric Purple. These are used for primary actions, progress indicators, and "live" statuses.
- **Surface Tiers:** Charcoal grays (`#121212`, `#1A1A1A`) are used for card containers and inputs to create a "lifted" effect from the black background.
- **Accents:** Success states use a vibrant Emerald, while destructive actions (like "Log Out") use a deep, muted Crimson to maintain the dark aesthetic without being jarring.

## Typography

The typography system uses a tri-font strategy to balance impact, readability, and technical aesthetics.

- **Headlines:** Montserrat provides a bold, geometric authority. For "hero" sections, use the primary gradient on specific keywords to draw the eye.
- **Body:** Plus Jakarta Sans offers a soft, approachable counter-balance to the aggressive headlines, ensuring long-form descriptions remain legible.
- **Labels:** Space Grotesk is used for metadata, micro-copy, and technical specs (like "4K" or "60min") to reinforce the tech-forward nature of the platform.
- **Serif Accent:** Use *Newsreader* sparingly in italics for stylized sub-headings (e.g., "The Orbit *Edge*") to add a touch of editorial luxury.

## Layout & Spacing

The system follows a **Fluid Grid** model based on an 8px rhythm. 

- **Desktop:** 12-column layout with 24px gutters. Content is primarily centered in a 1200px container.
- **Mobile:** Single column with 16px side margins.
- **Component Padding:** Internal card padding is generous (24px to 32px) to allow the "breathable" premium feel seen in the reference images. 
- **Rhythm:** Use "Stacking" variables to maintain vertical consistency. `stack-lg` should separate major sections like "Featured Packages" and "Booking History."

## Elevation & Depth

Hierarchy is established through **Tonal Layers** and **Backdrop Blurs**.

- **Level 0 (Base):** Pitch black `#000000`.
- **Level 1 (Cards/Containers):** Charcoal `#121212` with a 1px subtle border (`rgba(255,255,255,0.1)`).
- **Level 2 (Modals/Overlays):** Semi-transparent `#1A1A1A` with a `20px` backdrop blur to create a glass effect.
- **Shadows:** Avoid traditional black shadows. Instead, use a "Glow" effect for active elements: a subtle outer glow using the primary blue or purple at 15-20% opacity.

## Shapes

The shape language is consistently "Rounded" to soften the high-contrast dark aesthetic.

- **Standard Containers:** Use `1rem` (16px) corner radius for most cards and input fields.
- **Buttons:** Use a hybrid approach; primary CTA buttons are `0.5rem` (rounded) while tags/status chips use a full pill-shape.
- **Icon Enclosures:** Small utility icons (search, notifications) should be enclosed in circles or highly rounded squares (12px radius) to maintain a modern, friendly touch.

## Components

### Buttons
- **Primary:** Use the linear gradient (Blue to Purple) with white bold text. 
- **Secondary/Ghost:** 1px border of `rgba(255,255,255,0.2)` with no background. Text is white.
- **Action Links:** Small, uppercase labels with a chevron icon, utilizing the Primary Blue color.

### Input Fields
- **Container:** Dark charcoal background with a 1px border that glows Primary Blue on focus.
- **Icons:** Leading icons should be used to provide visual cues (e.g., envelope for email, phone for contact). Use a lower opacity (60%) for these icons.

### Cards
- **Price Cards:** High contrast. Price should be the largest element using Montserrat Bold. Feature lists should use custom checkmark icons in Primary Blue.
- **Status Cards:** Use a thin top-border or "active" indicator (a small glowing dot) to show live status, such as "In Progress."

### Navigation
- **Floating Bar:** Use a bottom-fixed glassmorphic dock for mobile navigation. Active states are indicated by a vibrant top-line gradient and colored icons.
- **Top Header:** Clean, minimal, with the logo centered or left-aligned and profile/notification actions grouped on the right in circular containers.