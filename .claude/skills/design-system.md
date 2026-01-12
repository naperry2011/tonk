# Design System Skill

Invoke with: `/design-system [action]`

Actions: `audit`, `create`, `tokens`, `document`, `component-library`

## Purpose
Create and maintain consistent design tokens, colors, typography, spacing, and component patterns across the codebase.

## Instructions

When this skill is invoked:

### Action: `audit`
Analyze the current codebase for design consistency:

1. **Scan for colors**: Find all color values (hex, rgb, hsl) and identify:
   - How many unique colors exist
   - Which could be consolidated
   - Missing color relationships (hover states, disabled states)

2. **Scan for typography**: Find font declarations and identify:
   - Font families in use
   - Font sizes (are they consistent scale?)
   - Line heights and letter spacing

3. **Scan for spacing**: Find margin/padding values and identify:
   - Spacing scale consistency
   - Common patterns

4. **Report findings** with recommendations for standardization.

### Action: `create`
Set up a new design system foundation:

1. **Create CSS custom properties file** with:
   - Color palette (primary, secondary, neutrals, semantic)
   - Typography scale
   - Spacing scale
   - Border radii
   - Shadows
   - Transitions
   - Breakpoints

2. **Provide usage guidelines** for each category.

### Action: `tokens`
Create or update design tokens:

```css
:root {
  /* Colors */
  --color-primary-50: #eff6ff;
  --color-primary-100: #dbeafe;
  --color-primary-500: #3b82f6;
  --color-primary-600: #2563eb;
  --color-primary-700: #1d4ed8;

  /* Semantic Colors */
  --color-success: #22c55e;
  --color-warning: #f59e0b;
  --color-error: #ef4444;
  --color-info: #3b82f6;

  /* Neutrals */
  --color-gray-50: #f9fafb;
  --color-gray-100: #f3f4f6;
  --color-gray-200: #e5e7eb;
  --color-gray-300: #d1d5db;
  --color-gray-400: #9ca3af;
  --color-gray-500: #6b7280;
  --color-gray-600: #4b5563;
  --color-gray-700: #374151;
  --color-gray-800: #1f2937;
  --color-gray-900: #111827;

  /* Typography */
  --font-family-sans: system-ui, -apple-system, sans-serif;
  --font-family-mono: 'SF Mono', Consolas, monospace;

  --font-size-xs: 0.75rem;    /* 12px */
  --font-size-sm: 0.875rem;   /* 14px */
  --font-size-base: 1rem;     /* 16px */
  --font-size-lg: 1.125rem;   /* 18px */
  --font-size-xl: 1.25rem;    /* 20px */
  --font-size-2xl: 1.5rem;    /* 24px */
  --font-size-3xl: 1.875rem;  /* 30px */
  --font-size-4xl: 2.25rem;   /* 36px */

  --line-height-tight: 1.25;
  --line-height-normal: 1.5;
  --line-height-relaxed: 1.75;

  /* Spacing */
  --space-1: 0.25rem;  /* 4px */
  --space-2: 0.5rem;   /* 8px */
  --space-3: 0.75rem;  /* 12px */
  --space-4: 1rem;     /* 16px */
  --space-5: 1.25rem;  /* 20px */
  --space-6: 1.5rem;   /* 24px */
  --space-8: 2rem;     /* 32px */
  --space-10: 2.5rem;  /* 40px */
  --space-12: 3rem;    /* 48px */
  --space-16: 4rem;    /* 64px */

  /* Border Radius */
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;
  --radius-full: 9999px;

  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
  --shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);
  --shadow-xl: 0 20px 25px rgba(0, 0, 0, 0.15);

  /* Transitions */
  --transition-fast: 150ms ease;
  --transition-normal: 200ms ease;
  --transition-slow: 300ms ease;

  /* Z-index Scale */
  --z-dropdown: 100;
  --z-modal: 200;
  --z-popover: 300;
  --z-tooltip: 400;
  --z-toast: 500;
}
```

### Action: `document`
Generate documentation for the existing design system:
- List all tokens with examples
- Show color swatches
- Demonstrate typography scale
- Provide usage examples

### Action: `component-library`
Audit or create a component library:
- Identify reusable patterns
- Suggest standardization
- Create base components (Button, Input, Card, Modal, etc.)

## Output Format

```
## Design System [Action]: [Summary]

### Current State
[Analysis of what exists]

### Recommendations
[What should be improved/added]

### Implementation
[Code and files to add/modify]

### Usage Guide
[How to use the design system]
```
