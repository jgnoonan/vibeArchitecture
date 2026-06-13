# Accessibility Rules

> Applies to: Public tier and above.
> For detailed explanations: see `guides/accessibility/`

## Why Accessibility Matters

- Accessibility means your application can be used by people with disabilities — vision impairments, hearing loss, motor difficulties, cognitive differences. This includes people using screen readers, keyboard-only navigation, voice control, or high-contrast settings.
- It's not optional for public applications. The ADA (US), the European Accessibility Act (EU), and similar laws in other jurisdictions require digital products to be accessible. Lawsuits over inaccessible websites are common and increasing.
- Accessibility also improves usability for everyone. Keyboard navigation helps power users. Captions help people in noisy environments. Clear contrast helps people in bright sunlight. Good accessibility is good design.
- Retrofitting accessibility is expensive and painful. Building it in from the start costs almost nothing extra. This is a "do it now or pay 10x later" decision.

## Structure and Semantics

- Use semantic HTML elements for their intended purpose. `<button>` for buttons, `<a>` for links, `<nav>` for navigation, `<main>` for main content, `<header>` and `<footer>` for page structure, `<h1>` through `<h6>` for headings in proper hierarchy. Screen readers use these elements to understand page structure.
- Never use a `<div>` or `<span>` as a button or link. They are invisible to assistive technology unless you manually add ARIA roles, keyboard handling, and focus management — which is more work than using the correct element.
- Heading levels must follow a logical hierarchy. Don't skip from `<h1>` to `<h4>` because you want a smaller font. Use CSS for styling, headings for structure.
- Every page must have exactly one `<h1>` that describes the page content. Screen reader users often navigate by jumping between headings.
- Lists of items should use `<ul>`, `<ol>`, or `<dl>`. Screen readers announce "list of 5 items," helping users understand the content structure.

## Images and Media

- Every `<img>` element must have an `alt` attribute. Describe what the image conveys, not what it literally shows. Good: `alt="Sales chart showing 40% growth in Q3"`. Bad: `alt="chart.png"`. Worse: no alt attribute at all.
- Decorative images (visual flourishes that convey no information) should have `alt=""` (empty alt). This tells screen readers to skip them.
- Videos must have captions or transcripts. Auto-generated captions are a reasonable starting point but should be reviewed for accuracy.
- Audio content must have a transcript available.

## Keyboard Navigation

- Every interactive element must be reachable and operable using only the keyboard. Tab to move between elements, Enter or Space to activate, Escape to close.
- Focus order must follow a logical sequence — generally matching the visual reading order (left to right, top to bottom for LTR languages).
- Focus must be visible. Users must be able to see which element is currently focused. Never remove the default focus outline (`outline: none`) without providing an equally visible alternative.
- Keyboard traps are not allowed. If a user can Tab into an element (a modal, a dropdown, a widget), they must be able to Tab or Escape out of it.
- Custom components (date pickers, sliders, comboboxes) must implement keyboard interaction patterns. When building custom components, follow the WAI-ARIA Authoring Practices for the appropriate widget pattern.

## Color and Contrast

- Text must have a contrast ratio of at least 4.5:1 against its background (3:1 for large text). Use a contrast checker tool — don't eyeball it.
- Never use color as the only way to convey information. "Fields in red are required" fails for colorblind users. Use icons, text labels, or patterns alongside color.
- UI controls (buttons, inputs, links) must have at least 3:1 contrast against their surrounding area.
- Support both light and dark modes if offered, ensuring contrast requirements are met in both.

## Forms

- Every form input must have a visible `<label>` element associated with it using `for`/`id` attributes. Placeholder text is NOT a substitute for a label — it disappears when the user starts typing.
- Error messages must be specific and associated with the field that has the error. "Something went wrong" is not helpful. "Email address is required" next to the email field is.
- Required fields must be marked in a way that doesn't depend on color alone. An asterisk with a legend ("* required") is the standard pattern.
- Form validation errors must be announced to screen readers. Use `aria-live` regions or associate error messages with inputs using `aria-describedby`.
- Group related fields with `<fieldset>` and `<legend>`. Radio buttons and checkboxes especially need this.

## ARIA (Use Sparingly)

- ARIA (Accessible Rich Internet Applications) attributes add accessibility information to custom components. But the first rule of ARIA is: don't use ARIA if a native HTML element does the job. A `<button>` is always better than a `<div role="button">`.
- When you must use ARIA: `aria-label` for elements with no visible text, `aria-describedby` to link instructions or errors to an input, `aria-live` for dynamic content that updates without a page reload, `aria-expanded` for collapsible sections.
- Incorrect ARIA is worse than no ARIA. A `role="button"` on a div that can't be activated with a keyboard gives screen reader users a button they can't click.

## Mobile Accessibility

- Touch targets must be at least 44x44 CSS pixels. Small tap targets are unusable for people with motor impairments.
- Support pinch-to-zoom. Never disable user scaling (`user-scalable=no` or `maximum-scale=1`). People with low vision need to zoom.
- Ensure content is readable without horizontal scrolling at 320px viewport width (equivalent to a phone held vertically at 400% zoom).

## AI-Generated Code Review

AI coding agents frequently generate inaccessible code. Watch for these common issues:

- Missing `alt` attributes on images
- `<div>` and `<span>` used for interactive elements instead of `<button>` and `<a>`
- Forms without labels (using placeholder text only)
- Focus outline removed for aesthetics (`outline: none` in CSS)
- Color-only indicators (red/green for error/success with no text or icon)
- Non-semantic headings (styling text as a heading without using heading tags)
- Click handlers on non-interactive elements without keyboard equivalents

After the AI generates UI code, verify these items before moving on. Ask your AI: *"Check this component for accessibility issues."*

## Testing

- Test with keyboard only. Put your mouse away and try to complete the core tasks in your application using only Tab, Enter, Space, Escape, and arrow keys.
- Test with a screen reader. On macOS, VoiceOver is built in (Cmd+F5). On Windows, NVDA is free. Even a 10-minute test catches major issues.
- Run an automated accessibility checker. Tools like axe (browser extension), Lighthouse (built into Chrome DevTools), or pa11y (command line) catch structural issues automatically. They won't catch everything, but they catch a lot.
- Check color contrast with a tool. WebAIM's contrast checker or the browser DevTools contrast checker.
