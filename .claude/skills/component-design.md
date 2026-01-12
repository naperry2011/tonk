# Component Design Skill

Invoke with: `/component-design [component name or description]`

## Purpose
Design and scaffold new UI components following best practices for structure, reusability, and maintainability.

## Instructions

When this skill is invoked:

1. **Clarify requirements**:
   - What is the component's purpose?
   - What props/inputs does it need?
   - What states should it handle (loading, error, empty, etc.)?
   - Does it need to be interactive?
   - Should it be reusable or page-specific?

2. **Analyze existing patterns**: Look at the codebase to understand:
   - File structure conventions
   - Naming conventions
   - Styling approach (CSS modules, styled-components, Tailwind, plain CSS)
   - State management patterns
   - Existing component library or design system

3. **Design the component**:

### Structure
- Keep components focused on a single responsibility
- Extract sub-components when complexity grows
- Separate concerns (presentation vs. logic)

### Props Interface
- Define clear, typed props
- Use sensible defaults
- Document required vs. optional props
- Consider prop validation

### States to Handle
- **Default**: Normal display state
- **Loading**: Data fetching in progress
- **Empty**: No data to display
- **Error**: Something went wrong
- **Disabled**: Interaction not allowed
- **Hover/Focus/Active**: Interactive states

### Accessibility
- Use semantic HTML elements
- Include ARIA attributes where needed
- Ensure keyboard navigation
- Provide visible focus indicators

### Styling
- Follow project's existing styling approach
- Make styles customizable via props or CSS variables
- Consider responsive behavior
- Handle dark mode if applicable

4. **Provide complete implementation**:
   - Component file with full code
   - Styles (if separate)
   - Usage example
   - Props documentation

## Component Template

```
## Component: [ComponentName]

### Purpose
[What this component does]

### Props
| Prop | Type | Default | Description |
|------|------|---------|-------------|
| prop1 | string | - | Description |
| prop2 | boolean | false | Description |

### States
- Default: [description]
- Loading: [description]
- Error: [description]

### Usage Example
[Code showing how to use the component]

### Implementation
[Full component code]

### Styles
[CSS/styling code]

### Accessibility Notes
[Any a11y considerations]
```

## Best Practices Checklist

- [ ] Single responsibility
- [ ] Clear prop interface
- [ ] Handles all states (loading, error, empty)
- [ ] Accessible (keyboard, screen reader)
- [ ] Follows project conventions
- [ ] Responsive if applicable
- [ ] Documented usage
- [ ] No hardcoded values that should be props
