# UI/UX Review Skill

Invoke with: `/ui-ux-review [file or component name]`

## Purpose
Analyze user interface and user experience aspects of the codebase, providing actionable feedback to improve usability, accessibility, and overall design quality.

## Instructions

When this skill is invoked:

1. **Identify the target**: Determine which file, component, or page to review. If no specific target is provided, ask the user what they'd like reviewed.

2. **Read the relevant files**: Examine HTML structure, CSS styling, and JavaScript/TypeScript interaction logic.

3. **Analyze and report on these areas**:

### Usability
- Is the interface intuitive and easy to navigate?
- Are interactive elements clearly identifiable (buttons, links, inputs)?
- Is there appropriate feedback for user actions (hover states, loading states, success/error messages)?
- Are form inputs properly labeled and validated?

### Accessibility (a11y)
- Do images have alt text?
- Is there proper heading hierarchy (h1, h2, h3...)?
- Are colors meeting contrast requirements (WCAG AA minimum)?
- Can the interface be navigated by keyboard?
- Are ARIA labels used appropriately?
- Is focus management handled correctly?

### Visual Hierarchy
- Is the most important content prominently displayed?
- Is there clear visual grouping of related elements?
- Is whitespace used effectively?
- Is typography readable and consistent?

### Responsiveness
- Does the layout adapt to different screen sizes?
- Are touch targets appropriately sized for mobile (minimum 44x44px)?
- Is content readable without horizontal scrolling on mobile?

### Interaction Design
- Are animations smooth and purposeful (not distracting)?
- Are loading states handled gracefully?
- Is error handling user-friendly?

4. **Provide recommendations**: List specific, actionable improvements with code examples where helpful.

5. **Prioritize findings**: Categorize issues as:
   - **Critical**: Blocks users or causes major usability issues
   - **Important**: Significantly impacts user experience
   - **Enhancement**: Nice-to-have improvements

## Output Format

```
## UI/UX Review: [Component/Page Name]

### Summary
[Brief overview of the component and its purpose]

### Findings

#### Critical Issues
- [Issue description + recommendation]

#### Important Issues
- [Issue description + recommendation]

#### Enhancements
- [Suggestion for improvement]

### Accessibility Checklist
- [ ] Alt text on images
- [ ] Proper heading hierarchy
- [ ] Keyboard navigation
- [ ] Color contrast
- [ ] Focus indicators

### Recommended Actions
1. [First priority action]
2. [Second priority action]
...
```
