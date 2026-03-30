# Accessibility: Making Your App Usable by Everyone

> For the compact rules, see `rules/accessibility.md`.

## What Is Accessibility?

Accessibility (often shortened to "a11y" — the "11" represents the 11 letters between the "a" and the "y") means building your application so that people with disabilities can use it. This includes:

- **Vision impairments:** People who are blind and use screen readers (software that reads the screen aloud), people with low vision who zoom in or use high contrast, people who are colorblind
- **Motor impairments:** People who can't use a mouse and navigate entirely with a keyboard, a switch device, or voice commands
- **Hearing impairments:** People who are deaf or hard of hearing and need captions for audio/video content
- **Cognitive differences:** People who benefit from clear language, consistent navigation, and predictable interfaces

About 15% of the world's population has some form of disability. That's over a billion people. Many more have temporary impairments (a broken arm, an eye infection) or situational ones (using a phone in bright sunlight, watching a video in a noisy room).

## Why Should I Care?

Three reasons, in order of importance:

**1. It's the right thing to do.** Your application excludes real people when it's inaccessible. A blind user who can't read your signup form can't use your product. A person who can't use a mouse and can't Tab through your navigation is locked out.

**2. It's the law.** In the United States, the ADA (Americans with Disabilities Act) applies to websites and apps. The European Accessibility Act takes effect in 2025. Canada, Australia, and many other countries have similar laws. Lawsuits over inaccessible websites are common — thousands are filed each year in the US alone.

**3. It's better design for everyone.** Keyboard navigation helps power users who prefer the keyboard. Captions help people watching video in a noisy coffee shop. High contrast helps everyone read in bright sunlight. Clear labels help everyone fill out forms faster. Accessible design is good design.

## The Basics: What Your App Needs

### 1. Structure That Software Can Understand

Sighted users see your page layout — headings are big, navigation is at the top, content is in the middle. Screen reader users can't see the layout. They rely on the HTML structure to understand the page.

**Use the right HTML elements:**

| Instead of... | Use... | Why |
|--------------|--------|-----|
| `<div>` with click handler | `<button>` | Screen readers announce it as a button, keyboard users can press Enter/Space to activate it |
| `<div>` that links somewhere | `<a href="...">` | Screen readers announce it as a link, keyboard users can Tab to it |
| Big bold text for headings | `<h1>`, `<h2>`, `<h3>` | Screen readers let users jump between headings to scan the page |
| Generic `<div>` containers | `<nav>`, `<main>`, `<header>`, `<footer>` | Screen readers use these "landmarks" to let users jump to sections |

This is the single most impactful thing you can do for accessibility. Use HTML elements for their intended purpose, and most of the work is done.

### 2. Images That Can Be Heard

When a screen reader encounters an image, it reads the `alt` attribute aloud. If there's no `alt`, the user knows there's an image but has no idea what it shows.

**Write good alt text:**
- Describe what the image communicates, not what it literally is
- `alt="Team photo of 5 people smiling in an office"` — good
- `alt="IMG_4382.jpg"` — useless
- `alt="Photo"` — useless
- No `alt` attribute at all — the screen reader might read the file URL, which is even worse

**For decorative images** (backgrounds, dividers, visual flourishes that don't convey information), use `alt=""`. This tells the screen reader to skip it entirely.

### 3. Forms People Can Fill Out

Forms are where accessibility breaks most often. The rules are simple:

**Every input needs a label.**
Not a placeholder — a label. Placeholders disappear when you start typing, so a user who gets distracted and comes back doesn't know what the field is for. Screen readers may not announce placeholder text.

```html
<!-- Good -->
<label for="email">Email address</label>
<input id="email" type="email">

<!-- Bad — no label, only placeholder -->
<input type="email" placeholder="Email address">
```

**Errors must say what's wrong and where.**
"Something went wrong" doesn't help anyone. "Please enter a valid email address" next to the email field helps everyone.

**Required fields must be marked clearly.**
An asterisk (*) with a note at the top of the form ("* required") is the standard pattern. Don't rely on color alone — a colorblind user won't see the red outline.

### 4. Keyboard Navigation That Works

Many people can't use a mouse — people with motor impairments, people using screen readers, power users who prefer the keyboard. Your app must work without a mouse.

**Test it:** Put your mouse in a drawer and try to use your app.
- Can you Tab to every button, link, and form field?
- Can you press Enter or Space to activate buttons?
- Can you see which element is currently focused? (There should be a visible outline or highlight)
- Can you close modals and dropdowns with Escape?
- Does the Tab order make sense? (Left to right, top to bottom)

The most common failure: **removing the focus outline.** Designers sometimes add `outline: none` because the blue focus ring "looks ugly." This makes your app unusable for keyboard users. If you don't like the default outline, replace it with a custom visible focus indicator — never remove it.

### 5. Color That Works for Everyone

About 8% of men and 0.5% of women are colorblind. The most common type makes red and green look similar.

**Never use color as the only indicator:**
- Error messages: Don't just make the border red. Add an error icon and text.
- Status indicators: Don't use only red/green dots. Add labels ("Active" / "Inactive") or distinct icons.
- Charts and graphs: Use patterns or labels in addition to colors.

**Check your contrast:**
Text must be readable against its background. The standard (WCAG AA) requires:
- Normal text: 4.5:1 contrast ratio
- Large text (18px+ bold, or 24px+): 3:1 contrast ratio

Use Chrome DevTools (inspect an element, look at the contrast ratio in the color picker) or the WebAIM Contrast Checker website. Don't guess — check.

### 6. Content That Updates Announces Itself

When content changes on the page without a full reload — a notification appears, a form validation error pops up, a chat message arrives — screen reader users won't know about it unless you tell them.

Use `aria-live` regions to announce dynamic changes:

```html
<div aria-live="polite">
  <!-- Content that updates dynamically goes here -->
  <!-- "polite" means announce when the user is idle -->
</div>
```

Use `aria-live="polite"` for non-urgent updates (form validation, status messages). Use `aria-live="assertive"` only for critical alerts that need immediate attention.

## WCAG: The Accessibility Standard

WCAG (Web Content Accessibility Guidelines) is the international standard for web accessibility. There are three levels:

- **Level A:** The bare minimum. If you fail this, many users literally cannot use your app.
- **Level AA:** The standard most laws require and most organizations target. This is the right goal for your project.
- **Level AAA:** The highest level. Nice to have but not required for most applications.

**For vibeArchitecture projects:** Target WCAG 2.1 Level AA. The rules in `rules/accessibility.md` cover the AA requirements.

## Testing Accessibility

You don't need to be an expert to test accessibility. Here's a practical approach:

### Automated Testing (5 minutes)

Run an automated scanner. These catch about 30–40% of accessibility issues — the structural ones.

- **Lighthouse** (built into Chrome): Open DevTools > Lighthouse tab > check "Accessibility" > Generate report
- **axe DevTools** (browser extension): Install from Chrome Web Store, click "Scan" on any page
- **pa11y** (command line): `npx pa11y https://your-site.com`

Ask your AI: *"Run an accessibility check on this component and fix any issues."*

### Keyboard Testing (10 minutes)

The most valuable manual test. Put your mouse away and use your app:

1. Press Tab repeatedly. Do you visit every interactive element? In a logical order?
2. Can you see which element is focused at all times?
3. Can you activate every button and link with Enter or Space?
4. Can you close modals and dropdowns with Escape?
5. Can you navigate through the entire core user flow?

If you get stuck anywhere, that's an accessibility bug.

### Screen Reader Testing (15 minutes)

Try your app with a screen reader:

- **macOS:** Press Cmd+F5 to start VoiceOver. Use Tab and VoiceOver keys (Ctrl+Option+arrow keys) to navigate. Press Cmd+F5 again to stop.
- **Windows:** Download NVDA (free) from nvaccess.org. Press Insert+Down to read from the current position.
- **Mobile:** On iOS, triple-click the side button for VoiceOver. On Android, find TalkBack in Settings > Accessibility.

Listen for:
- Are buttons announced as "button"? Are links announced as "link"?
- Do images have meaningful descriptions?
- Can you understand the page structure from headings alone?
- Are form fields labeled correctly?

Even 10 minutes of screen reader testing is dramatically better than nothing.

### Contrast Checking (5 minutes)

- Open Chrome DevTools
- Inspect any text element
- In the Styles panel, click on a color value
- The color picker shows the contrast ratio and whether it passes AA/AAA

Check your key text: body text, headings, button labels, form labels, error messages.

## Common Accessibility Mistakes in AI-Generated Code

AI coding agents are consistently bad at accessibility. They prioritize visual appearance over semantic structure. Watch for:

1. **Using `<div>` for everything.** AI loves divs. It will create `<div class="button" onClick={...}>` instead of `<button>`. Every time.

2. **Missing alt text.** AI generates `<img src="...">` without alt attributes, or adds meaningless ones like `alt="image"`.

3. **Placeholder-only form fields.** AI uses `<input placeholder="Enter your email">` without a `<label>`. Looks fine visually. Invisible to screen readers.

4. **Removing focus outlines.** AI often includes `outline: none` or `*:focus { outline: 0 }` in CSS resets for aesthetic reasons.

5. **Color-only indicators.** AI uses red/green for error/success states without text or icons.

6. **Non-semantic headings.** AI styles text to look like a heading using CSS instead of using `<h2>`, `<h3>`, etc.

**The fix:** After the AI generates UI code, ask: *"Review this code for accessibility. Check for semantic HTML, alt text, form labels, keyboard navigation, color contrast, and focus management."*

## Getting Started

If your existing codebase has no accessibility consideration:

1. **Run Lighthouse.** Get a baseline score. Don't panic at the number.
2. **Fix the headings.** Make sure your page has an `<h1>` and a logical heading hierarchy. This takes 10 minutes and helps everyone.
3. **Add labels to forms.** Every input gets a visible `<label>`. This takes 15 minutes.
4. **Add alt text to images.** Go through your images and add meaningful descriptions. This takes 20 minutes.
5. **Test with keyboard.** Fix any places where you get stuck.
6. **Run Lighthouse again.** Compare the score. You'll be surprised how much improves.

Don't try to fix everything at once. Each of these steps makes your app measurably more accessible. Do them in order and your most critical issues are fixed first.
