---
name: review-accessibility
description: >-
  Accessibility (a11y)-focused code review. Apply when reviewing UI code for
  screen reader support, keyboard navigation, color contrast, WCAG compliance,
  semantic HTML, ARIA labels, and inclusive design.
user-invocable: false
---

# Accessibility Review

Review code from an accessibility (a11y) perspective.

## Review Checklist

### Screen Reader Support
- Verify all interactive elements have accessible labels
- Check images have meaningful alt text (or empty alt for decorative)
- Ensure dynamic content changes are announced
- Verify form fields have associated labels

### Keyboard Navigation
- Check all interactive elements are keyboard accessible
- Verify logical tab order follows visual layout
- Ensure focus indicators are visible
- Check keyboard traps do not exist (can always escape)

### Visual & Color
- Verify color contrast meets WCAG AA (4.5:1 text, 3:1 large text)
- Check information is not conveyed by color alone
- Ensure text is resizable without loss of content
- Verify animations can be disabled (prefers-reduced-motion)

### Semantic Structure
- Check proper heading hierarchy (h1 > h2 > h3)
- Verify semantic HTML elements are used (nav, main, article)
- Ensure lists use proper list elements
- Check landmark regions are properly defined

### Mobile Accessibility
- Verify touch targets are at least 44x44dp
- Check content descriptions on Android (contentDescription)
- Ensure accessibility traits on iOS (accessibilityLabel, accessibilityHint)
- Verify gesture-based actions have alternatives

### WCAG Compliance
- Level A: All essential requirements met
- Level AA: Enhanced requirements for public-facing applications
- Check forms have clear error identification and suggestions
- Verify time-based content can be paused or extended

## Output Format

| Level | Description |
|-------|-------------|
| Blocker | WCAG A violation, prevents access for some users |
| Major | WCAG AA violation, significant barrier |
| Minor | Usability issue for assistive technology users |
| Enhancement | Improves experience but not a violation |
