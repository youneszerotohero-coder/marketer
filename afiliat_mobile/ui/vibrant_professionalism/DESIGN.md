---
name: Vibrant Professionalism
colors:
  surface: '#f8f9fa'
  surface-dim: '#d9dadb'
  surface-bright: '#f8f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f5'
  surface-container: '#edeeef'
  surface-container-high: '#e7e8e9'
  surface-container-highest: '#e1e3e4'
  on-surface: '#191c1d'
  on-surface-variant: '#504535'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#827563'
  outline-variant: '#d4c4af'
  surface-tint: '#7e5700'
  primary: '#7e5700'
  on-primary: '#ffffff'
  primary-container: '#ffc04d'
  on-primary-container: '#724f00'
  inverse-primary: '#fabc49'
  secondary: '#5f5e5e'
  on-secondary: '#ffffff'
  secondary-container: '#e2dfde'
  on-secondary-container: '#636262'
  tertiary: '#006d36'
  on-tertiary: '#ffffff'
  tertiary-container: '#52e586'
  on-tertiary-container: '#006330'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdeab'
  primary-fixed-dim: '#fabc49'
  on-primary-fixed: '#281900'
  on-primary-fixed-variant: '#5f4100'
  secondary-fixed: '#e5e2e1'
  secondary-fixed-dim: '#c8c6c5'
  on-secondary-fixed: '#1c1b1b'
  on-secondary-fixed-variant: '#474746'
  tertiary-fixed: '#6dfe9c'
  tertiary-fixed-dim: '#4de082'
  on-tertiary-fixed: '#00210c'
  on-tertiary-fixed-variant: '#005227'
  background: '#f8f9fa'
  on-background: '#191c1d'
  surface-variant: '#e1e3e4'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  stat-display:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.01em
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
  xl: 32px
  container-padding: 16px
  card-gap: 12px
---

## Brand & Style

The design system is engineered for the high-energy, results-oriented world of digital marketing. It balances **Corporate Modernism** with an **Energetic Pulse**, ensuring the interface feels reliable enough for financial data yet vibrant enough to motivate daily user engagement. 

The aesthetic is characterized by high-clarity layouts, generous whitespace, and purposeful pops of color. It targets professionals who need to digest complex data (commissions, orders, wallets) quickly on the go. The emotional response should be one of "controlled momentum"—efficient, optimistic, and highly organized.

## Colors

This design system utilizes a high-energy primary orange-yellow (`#FFC04D`) as its focal point for actions and brand identity. 

- **Primary**: Used for main CTAs, active states, and brand-critical elements.
- **Secondary**: A deep charcoal for primary text and high-contrast UI elements, providing a professional anchor to the vibrant primary.
- **Tertiary (Success)**: A crisp green specifically for financial gains and "Delivered" statuses.
- **Neutral/Background**: A tiered system of cool greys. The base background is `#F9FAFB` to distinguish card surfaces from the canvas.
- **Status Tones**: Soft washes of color (low opacity versions of primary/tertiary) are used for badge backgrounds to ensure legibility without visual clutter.

## Typography

The design system relies on **Inter** for its exceptional legibility in data-heavy environments. 

- **Numerical Hierarchy**: For statistic cards, use `stat-display`. It is tightened for visual impact.
- **Semantic Clarity**: Use `label-caps` for section headers and metadata to provide clear visual anchors.
- **Readability**: Body text maintains a 1.5x line-height ratio to ensure comfort during long sessions of order management.

## Layout & Spacing

The layout follows a **Fluid Mobile-First** model based on a 4px baseline grid. 

- **Margins**: Standard screen horizontal margin is `16px`.
- **Card Spacing**: Elements within cards use `12px` (sm) or `16px` (md) padding to maintain a compact yet breathable feel.
- **Grid**: Use a 2-column grid for product cards on mobile screens to maximize screen real estate, switching to a single-column list for order history.

## Elevation & Depth

Hierarchy is established through **Ambient Shadows** and **Tonal Layering**. 

- **The Canvas**: The base layer is `#F9FAFB`.
- **Cards**: All cards use a pure white (`#FFFFFF`) surface to "pop" against the grey background.
- **Shadows**: Use a very soft, diffused shadow: `0px 4px 12px rgba(0, 0, 0, 0.05)`. This creates depth without the "heavy" feel of traditional enterprise apps.
- **Interactive Elements**: Buttons and active cards may use a slightly more pronounced shadow on hover/press to simulate tactile feedback.

## Shapes

The shape language is friendly and modern. 

- **Standard Elements**: Buttons and inputs use a `8px` radius.
- **Containers**: Information cards use a larger `16px` radius (`rounded-lg`) to create a distinct, modern "object" feel.
- **Outer Containers**: Deeply nested components or large dashboard sections may scale up to `24px` (`rounded-xl`) for a softer, more premium aesthetic.

## Components

### Bottom Navigation
A fixed footer with 5 tabs: **Home, Shop, Orders, Wallet, Profile**. 
- **Inactive**: Outline icons in a medium grey.
- **Active**: Filled icon or primary-colored outline with a 4px dot indicator underneath.
- **Typography**: 10px-11px labels, only visible on the active tab or persistent depending on space.

### Statistic Cards
Large, high-contrast numerical displays.
- **Structure**: Label (top-left), Primary Stat (center), Trend Indicator (bottom-right).
- **Coloring**: Use Tertiary Green for positive trends and a soft red for negative.

### Product Cards
- **Image**: 1:1 aspect ratio with `8px` top corner radius.
- **Commission Badge**: A floating `rounded-xl` pill in the top right of the image, using the Primary color with dark text for maximum visibility.
- **Footer**: Product title (2 lines max) and price in bold.

### Status Badges
Small, pill-shaped indicators for order status.
- **Pending**: Soft orange background with deep orange text.
- **Delivered**: Soft green background with deep green text.
- **Cancelled**: Soft grey background with dark grey text.

### Inputs & Buttons
- **Primary Button**: Full-width, `primary_color_hex` background, `secondary_color_hex` text for high contrast.
- **Input Fields**: Subtle grey border (`#E5E7EB`) that turns `primary_color_hex` on focus.