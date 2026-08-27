# Accessibility Rules

> Applies to: Public tier and above.
> For detailed explanations: see `guides/accessibility/accessibility-basics.md` (WCAG 2.2 Criteria Behind the Rules; Native Mobile Apps).

## Why Accessibility Matters

- Accessibility means people with vision, hearing, motor, and cognitive disabilities can use your application: screen readers, keyboard-only, voice control, high-contrast settings.
- It is not optional for public applications: the ADA (US), the European Accessibility Act (EU), and equivalents elsewhere require it, and lawsuits are common.
- **Target: WCAG 2.2 Level AA**, the level laws and procurement standards (EN 301 549, Section 508, ADA Title II) reference. The rules below cover AA, including criteria new in 2.2.
- Accessibility improves usability for everyone; build it in from the start, because retrofitting costs roughly 10x.

## Structure and Semantics

- Use semantic HTML for its purpose: `<button>`, `<a>`, `<nav>`, `<main>`, `<header>`, `<footer>`, `<h1>`–`<h6>` in hierarchy.
- Never use a `<div>` or `<span>` as a button or link.
- Heading levels follow a logical hierarchy (no `<h1>` to `<h4>` jumps for styling); use CSS for size.
- Every page has exactly one `<h1>` describing the page.
- Lists use `<ul>`, `<ol>`, or `<dl>`.

## Images and Media

- Every `<img>` has an `alt` attribute describing what the image conveys (`alt="Sales chart showing 40% growth in Q3"`, not `alt="chart.png"`).
- Decorative images use `alt=""`.
- Videos have captions or transcripts (auto-generated captions reviewed for accuracy).
- Audio content has a transcript.

## Keyboard Navigation

- Every interactive element is reachable and operable by keyboard alone: Tab to move, Enter/Space to activate, Escape to close.
- Focus order follows the visual reading order.
- Focus is visible; never `outline: none` without an equally visible alternative.
- No keyboard traps: anything you can Tab into, you can Tab or Escape out of.
- The focused element is never fully hidden by sticky headers, cookie banners, or chat widgets (WCAG 2.2 SC 2.4.11 Focus Not Obscured).
- Custom components (date pickers, sliders, comboboxes) implement the WAI-ARIA Authoring Practices keyboard pattern for that widget.

## Color and Contrast

- Text contrast at least 4.5:1 (3:1 for large text), measured with a checker tool.
- Never use color as the only way to convey information; add icons, text, or patterns.
- UI controls (buttons, inputs, links) have at least 3:1 contrast against their surroundings.
- If light and dark modes are offered, both meet contrast requirements.

## Forms

- Every input has a visible `<label>` linked by `for`/`id`; placeholder text is not a label.
- Error messages are specific and associated with the field ("Email address is required" next to the email field).
- Required fields are marked without relying on color alone (asterisk plus a legend).
- Validation errors are announced to screen readers via `aria-live` or `aria-describedby`.
- Group related fields with `<fieldset>` and `<legend>` (radio buttons and checkboxes especially).
- Don't make users re-enter information already given in the same process; auto-populate or offer "same as shipping address", except for security re-confirmation such as a password (WCAG 2.2 SC 3.3.7 Redundant Entry).
- Login never requires a cognitive test with no alternative (WCAG 2.2 SC 3.3.8 Accessible Authentication): password managers and paste work; image/puzzle CAPTCHAs get an alternative (object-recognition-free method, email/passkey login, or a mechanism like Turnstile). This constrains the bot controls in `rules/security.md`.

## ARIA (Use Sparingly)

- First rule of ARIA: don't use ARIA if a native HTML element does the job (`<button>` beats `<div role="button">`).
- When needed: `aria-label` for elements with no visible text, `aria-describedby` for instructions or errors, `aria-live` for dynamic updates, `aria-expanded` for collapsibles.
- Incorrect ARIA is worse than no ARIA (a `role="button"` that can't be activated by keyboard).

## Mobile Accessibility

- Touch targets at least 44x44 CSS pixels (WCAG 2.2 SC 2.5.8 minimum is 24x24 with spacing; 44x44 matches platform guidance).
- Support pinch-to-zoom; never set `user-scalable=no` or `maximum-scale=1`.
- Content is readable without horizontal scrolling at 320px viewport width (WCAG SC 1.4.10 Reflow; equals a phone at 400% zoom).

## Native Mobile Apps (Flutter, SwiftUI, Jetpack Compose, React Native)

The web rules above have direct native equivalents, and AI-generated native UI skips them even more reliably than it skips `alt` text. Apply from the first screen; see `guides/accessibility/accessibility-basics.md` (Native Mobile Apps).

- **Every interactive control has an accessible name** (tooltip or semantic label on icon-only buttons and custom tap surfaces), localized like any other string.
- **No bare gesture handlers for anything actionable:** use focusable, activatable platform primitives (buttons, `InkWell`/`FocusableActionDetector`, accessibility actions); long-press-only or swipe-only actions get a discoverable alternative (overflow or context menu).
- **Errors are announced, never just painted:** field errors through the platform's error slot (e.g. `errorText`); screen-level errors through a live region or accessibility announcement.
- **Non-text content has a text alternative:** semantic labels on meaningful images; icon-only or color-dot status also exists as text; decorative images excluded from semantics.
- **Compute contrast in both themes:** 4.5:1 text, 3:1 large text/UI components, checked with a real calculation in light and dark even if one isn't shipped yet.
- **Touch targets ≥ 44×44pt (iOS) / 48×48dp (Android);** don't shrink targets to fix a layout.
- **Text survives 200% OS font scaling:** flexible layouts, no fixed-height text containers, never pin font size to dodge an overflow.
- **Nothing animates indefinitely:** looping animation has a pause/stop affordance or ends within ~5 seconds, respects OS reduce-motion, and never flashes more than 3 times per second.
- **Test with VoiceOver/TalkBack and at maximum font scale on a real device;** ten minutes per screen.

## AI-Generated Code Review

AI coding agents frequently generate inaccessible code. After the AI generates UI code, verify these before moving on (ask: *"Check this component for accessibility issues."*):

- Missing `alt` attributes on images
- `<div>`/`<span>` used for interactive elements instead of `<button>`/`<a>`
- Forms without labels (placeholder only)
- Focus outline removed (`outline: none`)
- Color-only indicators (red/green with no text or icon)
- Non-semantic headings (styled text instead of heading tags)
- Click handlers on non-interactive elements without keyboard equivalents

## Testing

- Test keyboard-only: complete core tasks with Tab, Enter, Space, Escape, and arrow keys.
- Test with a screen reader (macOS VoiceOver, Cmd+F5; Windows NVDA, free); even 10 minutes catches major issues.
- Run an automated checker (axe browser extension, Lighthouse, pa11y); they catch a lot, not everything.
- At Business tier and above, put the checker in CI (`@axe-core/playwright` for pages, `jest-axe`/`vitest-axe` for components) and fail the build on new violations.
- Check color contrast with a tool (WebAIM contrast checker or browser DevTools).
