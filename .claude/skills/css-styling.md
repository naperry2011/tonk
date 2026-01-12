# CSS/Styling Skill

Invoke with: `/css-styling [task description]`

## Purpose
Assist with CSS architecture, responsive design, layouts, animations, and visual styling challenges.

## Instructions

When this skill is invoked:

1. **Understand the request**: Determine if the user needs help with:
   - Fixing a specific styling issue
   - Creating a new layout
   - Making something responsive
   - Adding animations/transitions
   - Refactoring CSS architecture
   - Debugging CSS problems

2. **Gather context**: Read relevant CSS/SCSS files and the HTML/JSX they style.

3. **Provide solutions based on the task type**:

### Layout Problems
- Use modern CSS (Flexbox, Grid) over legacy approaches
- Provide complete, working code snippets
- Explain the reasoning behind layout choices
- Consider both desktop and mobile layouts

### Responsive Design
- Use mobile-first approach when appropriate
- Suggest appropriate breakpoints
- Use relative units (rem, em, %, vw/vh) over fixed pixels where appropriate
- Test mental models at common breakpoints: 320px, 768px, 1024px, 1440px

### Animations & Transitions
- Prefer CSS transitions for simple state changes
- Use CSS animations for complex, multi-step animations
- Consider `prefers-reduced-motion` for accessibility
- Optimize for performance (prefer transform/opacity)

### CSS Architecture
- Follow existing project conventions
- Keep specificity low
- Avoid `!important` unless absolutely necessary
- Use CSS custom properties (variables) for theming
- Organize styles logically (layout, typography, colors, components)

### Debugging
- Check for specificity conflicts
- Verify cascade order
- Look for inheritance issues
- Check for box model problems (padding, margin, border)
- Verify units and values

4. **Code Examples**: Always provide complete, copy-paste ready code.

5. **Browser Compatibility**: Note any compatibility concerns for modern CSS features.

## Common Patterns

### Centering
```css
/* Flexbox centering */
.container {
  display: flex;
  justify-content: center;
  align-items: center;
}

/* Grid centering */
.container {
  display: grid;
  place-items: center;
}
```

### Responsive Grid
```css
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1rem;
}
```

### Smooth Transitions
```css
.element {
  transition: transform 0.2s ease, opacity 0.2s ease;
}

@media (prefers-reduced-motion: reduce) {
  .element {
    transition: none;
  }
}
```

### Card Shadow
```css
.card {
  box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24);
  transition: box-shadow 0.2s ease;
}
.card:hover {
  box-shadow: 0 4px 6px rgba(0,0,0,0.15), 0 2px 4px rgba(0,0,0,0.12);
}
```

## Output Format

```
## CSS Solution: [Brief Description]

### The Problem
[What we're solving]

### Solution
[CSS code with comments]

### How It Works
[Brief explanation of the approach]

### Usage
[How to apply this in the codebase]

### Browser Support
[Any compatibility notes]
```
