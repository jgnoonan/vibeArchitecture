# Internationalization: Building for Multiple Languages

> This is an architectural planning guide. Internationalization has no dedicated rules file because the decisions are project-specific, but the choices made here affect your database, frontend, API, and testing strategy.

## What Are i18n and l10n?

**Internationalization (i18n)** is designing your application so it *can* support multiple languages, regions, and cultures. It's the plumbing — externalizing strings, handling date formats, supporting different character sets.

**Localization (l10n)** is actually adapting your application for a specific locale — translating the text, formatting dates for that region, using the right currency symbol.

The abbreviations come from the number of letters between the first and last: i-nternationalizatio-n (18 letters), l-ocalizatio-n (10 letters).

**Why separate them?** Because internationalization is an architectural decision you make early. Localization is content work you can do later. If you build with i18n from the start, adding a new language later is straightforward. If you don't, retrofitting is painful — every hardcoded string in every template, every date format assumption, every layout that breaks with longer text.

## Do You Need This?

**You definitely need i18n if:**
- Your users speak different languages
- You're launching in multiple countries
- Legal requirements mandate language support (EU apps often need multiple languages)
- Your application handles dates, numbers, or currency for users in different regions

**You probably don't need i18n if:**
- Your app is for a single-language audience and will stay that way
- It's a personal or internal tool

**The catch:** If there's even a reasonable chance you'll need multiple languages in the future, build the i18n infrastructure now. It's almost free to do at the start and extremely expensive to add later.

## The Key Architectural Decisions

### 1. Externalize All User-Facing Strings

The most fundamental i18n practice: never hardcode text that users see.

**Don't do this:**
```
<h1>Welcome back!</h1>
<p>You have 3 new messages.</p>
```

**Do this:**
```
<h1>{t('welcome_back')}</h1>
<p>{t('new_messages', { count: 3 })}</p>
```

The actual text lives in translation files (JSON, YAML, or similar):

```json
{
  "welcome_back": "Welcome back!",
  "new_messages": "You have {count} new messages."
}
```

For another language, you create a separate file with the same keys:

```json
{
  "welcome_back": "Bienvenue !",
  "new_messages": "Vous avez {count} nouveaux messages."
}
```

**Every framework has i18n libraries for this:** react-intl or next-intl (React/Next.js), vue-i18n (Vue), angular/localize (Angular), django.utils.translation (Django), rails-i18n (Rails), SwiftUI's built-in localization (iOS), Android's string resources.

Ask your AI: *"Set up internationalization for this project using [your framework]'s recommended i18n library."*

### 2. Handle Pluralization

Different languages have different pluralization rules. English has two forms (1 message, 2 messages). Arabic has six forms. Russian has three. Polish has four.

Don't build your own pluralization logic. Use your i18n library's built-in plural support:

```json
{
  "messages": {
    "one": "You have {count} new message.",
    "other": "You have {count} new messages."
  }
}
```

The library picks the right form based on the count and the language's rules.

### 3. Date, Time, Number, and Currency Formatting

These vary dramatically by locale:

| Format | US English | German | Japanese |
|--------|-----------|--------|----------|
| Date | 03/26/2026 | 26.03.2026 | 2026/03/26 |
| Number | 1,234.56 | 1.234,56 | 1,234.56 |
| Currency | $1,234.56 | 1.234,56 € | ¥1,235 |

**Never format these manually.** Use the `Intl` API (built into JavaScript and most modern languages):

```javascript
new Intl.DateTimeFormat('de-DE').format(date)    // "26.3.2026"
new Intl.NumberFormat('de-DE').format(1234.56)   // "1.234,56"
```

**Store dates in UTC in your database.** Display them in the user's local timezone. Never store formatted date strings — store timestamps and format them at display time.

**Store currency amounts as integers (cents).** $12.34 is stored as 1234. This avoids floating-point precision issues that are disastrous for financial calculations. Format for display using the user's locale.

### 4. Database and Character Encoding

**Use UTF-8 everywhere.** Your database, your application, your API responses, your HTML pages — all UTF-8. This ensures you can store and display any character from any language, including emoji, Chinese characters, Arabic script, and accented letters.

Most modern databases and frameworks default to UTF-8, but verify:
- PostgreSQL: `CREATE DATABASE mydb ENCODING 'UTF8';`
- MySQL: Use `utf8mb4` (not `utf8`, which can't handle all Unicode characters including emoji)
- Your HTML: `<meta charset="UTF-8">`

**Consider text length in your schema.** German words are often longer than English. Japanese can be more compact. If your database column allows 50 characters for a name, make sure that's enough for names in all target languages. Translation often expands text by 20–40%.

**Collation matters for sorting and searching.** "café" should match "cafe" in a search. Different languages sort characters differently (Swedish puts å, ä, ö at the end of the alphabet, not with a). Use locale-aware collation in your database.

### 5. Right-to-Left (RTL) Layout

Arabic, Hebrew, Farsi, and Urdu are written right-to-left. If you'll support any RTL language, your layout needs to flip.

**The modern approach:** Use CSS logical properties instead of physical ones:

```css
/* Physical (breaks in RTL) */
margin-left: 16px;
text-align: left;

/* Logical (works in both directions) */
margin-inline-start: 16px;
text-align: start;
```

**Set the `dir` attribute** on your HTML based on the current language:
```html
<html lang="ar" dir="rtl">
```

**Test with a RTL language early** if you plan to support one. RTL bugs are hard to spot and hard to fix retroactively.

### 6. Images, Icons, and Media

- Text embedded in images can't be translated. Use text overlays or generate images dynamically.
- Some icons are culturally specific. A mailbox icon looks different in the US vs. Europe. A thumbs-up gesture is offensive in some cultures.
- If your app includes video or audio, plan for subtitles or dubbing.

## Translation Workflow

Once you've built the i18n infrastructure, you need a process for actually translating content.

**For small projects:** Start with machine translation (Google Translate API, DeepL API) and have a native speaker review. Machine translation quality has improved dramatically but still produces awkward phrasing.

**For business projects:** Use a translation management platform (Crowdin, Lokalise, Phrase) that integrates with your codebase. Translators work in the platform, and translated strings are synced back to your project.

**For regulated projects:** Professional human translation with review. Machine translation may not meet accuracy requirements for legal, medical, or financial content.

**Key practice:** Keep your translation files in version control alongside your code. When you add a new string in the default language, it should be obvious which translations are missing.

## When to Start

| Tier | Recommendation |
|------|---------------|
| Personal | Skip i18n unless you personally need multiple languages |
| Shared | Skip unless your group spans languages |
| Public | Set up i18n infrastructure from the start if there's any chance of non-English users. Even if you only ship one language initially, the plumbing is in place. |
| Business | Almost always yes. Even English-only products often expand internationally. Build the infrastructure now. |
| Regulated | Yes, and confirm which languages are legally required in your target markets. |

## Common Mistakes

**Concatenating strings for sentences.** `"Welcome, " + userName + "! You have " + count + " items."` can't be translated because word order varies by language. Use template strings with named placeholders: `t('welcome_with_items', { name: userName, count: count })`.

**Assuming text will be the same length.** German text is typically 30% longer than English. If your button says "Submit" in English, the German "Absenden" fits. But "Kontoinformationen aktualisieren" doesn't fit where "Update Account" did. Design with flexible layouts.

**Hardcoding date formats.** `MM/DD/YYYY` is US-only. Most of the world uses `DD/MM/YYYY` or `YYYY-MM-DD`. Use locale-aware formatting, not hardcoded patterns.

**Forgetting about time zones.** If your user is in Tokyo and your server is in Virginia, "today" means different things. Store UTC, display local.

**Sorting by byte value.** Alphabetical sorting depends on language. Use locale-aware comparison functions, not raw string comparison.
