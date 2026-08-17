---
name: Luminous Dark
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#3a3939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#bccbb9'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#869585'
  outline-variant: '#3d4a3d'
  surface-tint: '#4ae176'
  primary: '#4be277'
  on-primary: '#003915'
  primary-container: '#22c55e'
  on-primary-container: '#004b1e'
  inverse-primary: '#006e2f'
  secondary: '#ddb7ff'
  on-secondary: '#490080'
  secondary-container: '#6f00be'
  on-secondary-container: '#d6a9ff'
  tertiary: '#afc7ff'
  on-tertiary: '#002e6a'
  tertiary-container: '#82abff'
  on-tertiary-container: '#003d88'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#6bff8f'
  primary-fixed-dim: '#4ae176'
  on-primary-fixed: '#002109'
  on-primary-fixed-variant: '#005321'
  secondary-fixed: '#f0dbff'
  secondary-fixed-dim: '#ddb7ff'
  on-secondary-fixed: '#2c0051'
  on-secondary-fixed-variant: '#6900b3'
  tertiary-fixed: '#d8e2ff'
  tertiary-fixed-dim: '#adc6ff'
  on-tertiary-fixed: '#001a42'
  on-tertiary-fixed-variant: '#004395'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '800'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: '1.2'
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: '1.5'
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: '1.6'
  label-caps:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '600'
    lineHeight: '1'
    letterSpacing: 0.1em
  label-status:
    fontFamily: Geist
    fontSize: 13px
    fontWeight: '500'
    lineHeight: '1'
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 40px
  container-margin: 20px
  gutter: 16px
---

## Brand & Style

This design system centers on a **Tech-Forward Dark Mode** aesthetic. It leverages a "True Black" foundation to make vibrant neon accents and soft gradients pop, creating a sense of depth and high-end precision. The brand personality is professional yet energetic, utilizing a mix of **Minimalism** and **Glassmorphism**.

The visual narrative is driven by contrast: deep, void-like backgrounds against electric greens and ethereal purples. This evokes a sense of "The Future of Work"—efficient, digital-first, and premium. Key stylistic hallmarks include high-clarity typography, subtle border treatments that define structure without adding bulk, and a sophisticated use of glows to indicate activity and status.

## Colors

The palette is anchored in an absolute black (`#000000`) to maximize OLED contrast and power efficiency. 

- **Primary (Neon Green):** Reserved for active statuses ("Online"), positive financial indicators, and primary action highlights. It represents growth and connectivity.
- **Secondary (Ethereal Purple):** Used for branding elements, special "Partner" statuses, and decorative gradients. It provides a premium, "pro" feel.
- **Tertiary (Tech Blue):** Used for informational accents, secondary icons, and interactive text links.
- **Neutral/Surface:** We use a tiered gray system for depth. Surfaces sit at `#121212` with borders at `#1F2937` to create a clean separation from the black void.

## Typography

The system uses **Plus Jakarta Sans** for its approachable yet geometric clarity. It maintains high legibility in dark environments. For technical and metadata elements, **Geist** provides a precise, monospaced-adjacent feel that reinforces the "tech-forward" narrative.

Hierarchy is established through weight and color rather than just size. Headlines should use white (`#FFFFFF`) for maximum impact, while secondary body text should drop to a mid-gray (`#94A3B8`) to reduce eye strain and establish a clear visual path.

## Layout & Spacing

This design system utilizes a **fluid grid** model with standardized padding to maintain a structured "card-in-card" look. 

- **Mobile:** 20px side margins with a single-column layout for form factors and cards.
- **Desktop:** A 12-column grid with a maximum content width of 1200px. 
- **Rhythm:** An 8px base unit drives all spacing. Elements within cards use `sm` (12px) or `md` (16px) gaps, while major sections are separated by `xl` (40px) to provide breathing room. 

The layout relies on "safe zones" created by rounded containers, ensuring content never feels cramped against the screen edges.

## Elevation & Depth

Depth is communicated through **Tonal Layering** and **Subtle Outlines** rather than heavy shadows.

- **Level 0 (Background):** Absolute black `#000000`.
- **Level 1 (Containers):** Dark charcoal `#121212` with a 1px border of `#1F2937`.
- **Level 2 (Floating/Active):** Surfaces at `#1E1E1E` with a subtle outer glow using the primary or secondary color at 5-10% opacity.
- **Backdrop Blurs:** Used for navigation bars and modals (20px blur, 70% opacity background) to maintain context while focusing the user.

## Shapes

The system uses a **Rounded** language (0.5rem base) to soften the "hard tech" aesthetic and make the UI feel accessible.

- **Small Components (Tags, Badges):** Fully pill-shaped for distinctiveness.
- **Input Fields & Buttons:** 0.75rem (Rounded-LG) for a comfortable touch target.
- **Cards & Primary Containers:** 1rem (Rounded-LG) to 1.5rem (Rounded-XL) depending on the content scale.
- **Profile Avatars:** Circular with a 2px stroke or outer glow to indicate status.

## Components

- **Buttons:** Primary buttons use a solid white background with black text for maximum contrast. Secondary buttons are outlined with subtle gradients or semi-transparent fills.
- **Chips/Badges:** Small, high-contrast labels. "Partner" badges use purple text on a dark purple tinted background. "Online" status uses a primary green dot.
- **Input Fields:** Dark surfaces (`#0A0A0A`) with a thin border. The border should highlight in the secondary purple or primary green when focused. Labels sit above the field in `label-caps`.
- **Cards:** Defined by a `#121212` fill and `#1F2937` border. Grouped data (like Wallet Balance) should be featured in cards with subtle inner gradients to draw the eye.
- **Navigation:** Bottom-fixed on mobile with glassmorphism effects. Active states are indicated by a vibrant primary green dot above the icon.
- **Lists:** Clean rows separated by thin 1px lines (`#1F2937`) with chevron-right icons to indicate drill-down capability.