---
name: Mouaad Aallam
description: A quiet editorial design system for a personal engineering journal.
colors:
  accent: "#4b0082"
  ink-heading: "#222"
  ink-body: "#666"
  ink-meta: "#6b6b6b"
  ink-prose: "#3f3b36"
  rule: "#ededed"
  paper: "#fff"
  status-paper: "#f7f0e2"
  status-ink: "#5b4519"
  status-rule: "#d9c6a1"
typography:
  display:
    fontFamily: 'Newsreader, "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif'
    fontSize: "6.8rem"
    fontWeight: 500
    lineHeight: 0.93
    letterSpacing: "-0.06em"
  article-display:
    fontFamily: 'Newsreader, "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif'
    fontSize: "5.6rem"
    fontWeight: 500
    lineHeight: 1.1
    letterSpacing: "-0.025em"
  headline:
    fontFamily: 'Newsreader, "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif'
    fontSize: "3.6rem"
    fontWeight: 500
    lineHeight: 1.08
    letterSpacing: "-0.03em"
  title:
    fontFamily: 'Newsreader, "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif'
    fontSize: "3.3rem"
    fontWeight: 500
    lineHeight: 1.15
    letterSpacing: "-0.04em"
  body:
    fontFamily: '"Source Sans 3", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif'
    fontSize: "1.7rem"
    fontWeight: 400
    lineHeight: 1.68
  article-body:
    fontFamily: 'Newsreader, "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif'
    fontSize: "2rem"
    fontWeight: 400
    lineHeight: 1.65
  label:
    fontFamily: '"Source Sans 3", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif'
    fontSize: "1.28rem"
    fontWeight: 500
    lineHeight: 1.72
    letterSpacing: "0.08em"
  code:
    fontFamily: '"JetBrains Mono", "SFMono-Regular", Menlo, Consolas, "Liberation Mono", monospace'
    fontSize: "1.5rem"
    fontWeight: 400
    lineHeight: 1.6
rounded:
  code: "2px"
  image: "4px"
  launcher: "6px"
  row: "10px"
  diagram: "12px"
  pill: "999px"
spacing:
  space-1: ".5rem"
  space-2: ".8rem"
  space-3: "1.2rem"
  space-4: "1.4rem"
  space-5: "1.8rem"
  space-6: "2.4rem"
  space-7: "4rem"
  space-8: "6rem"
components:
  navigation-link:
    textColor: "{colors.ink-body}"
    typography: "{typography.label}"
    padding: "0.5rem 0 0.95rem"
  navigation-current:
    textColor: "{colors.ink-heading}"
  article-row:
    textColor: "{colors.ink-heading}"
    typography: "{typography.title}"
    rounded: "{rounded.row}"
    padding: "18px 0"
  article-row-hover:
    backgroundColor: "rgba(75, 0, 130, 0.035)"
    textColor: "{colors.accent}"
  tag:
    backgroundColor: "{colors.rule}"
    textColor: "{colors.ink-body}"
    rounded: "{rounded.pill}"
    padding: "4px 10px"
  code-block:
    backgroundColor: "{colors.paper}"
    typography: "{typography.code}"
    rounded: "{rounded.code}"
    padding: "0.8rem 1.2rem"
  prose-link:
    textColor: "{colors.ink-prose}"
  explainer-launcher:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.paper}"
    rounded: "{rounded.launcher}"
    padding: "0.9rem 1.2rem"
  status-badge:
    backgroundColor: "{colors.status-paper}"
    textColor: "{colors.status-ink}"
    rounded: "{rounded.pill}"
    padding: "5px 12px"
---

# Design System: Mouaad Aallam

## Overview

**Creative North Star: "The Engineering Journal"**

The site is quiet and editorial: expressive serif headings, restrained navigation, and room to read. Newsreader gives titles their character; Source Sans 3 carries the explanations and interface labels. Components feel refined and restrained.

Hierarchy comes from type, spacing, and fine rules. Indigo marks interactions, small uppercase labels support scanning, and ordinary surfaces stay flat. Implementation sources are `_sass/base/variables.sass`, `_sass/base/general.sass`, the component and page styles in `_sass/`, and `_layouts/default.html`.

**Key Characteristics:**

- Expressive serif titles above a single reading column.
- White paper, warm prose, and a deep indigo interaction accent.
- Small uppercase metadata and navigation with deliberate tracking.
- Flat surfaces separated by space and fine rules.

## Colors

Deep Indigo supplies the interaction accent against White Paper and a small set of text neutrals. Frontmatter values preserve the source notation.

### Primary

- **Deep Indigo** (`accent`): general links, article-row hover titles, social-link states, and the mobile explainer launch link. Article prose links use the prose color at rest and turn indigo on hover or keyboard focus.

### Neutral

- **White Paper** (`paper`): the page canvas and code backgrounds.
- **Heading Ink** (`ink-heading`): headings, strong emphasis, and current navigation.
- **Body Gray** (`ink-body`): general interface text and tag labels.
- **Metadata Gray** (`ink-meta`): dates, captions, and supporting author text.
- **Warm Prose** (`ink-prose`): paragraphs, lists, and article links at rest.
- **Pale Rule** (`rule`): dividers, code borders, and tag backgrounds.

The `status-*` colors belong to archived/unlisted badges. Syntax highlighting, Markdown alert variants, and Mermaid diagrams have purpose-specific palettes in the source; they are not extra site-wide accents. Standalone interactive explainers under `assets/files/` have independent styles.

The sidecar's tonal ramps are synthesized preview aids, not additional implementation tokens.

## Typography

Newsreader is the heading and prose family across articles and content pages, including About. Source Sans 3 is the interface family, and JetBrains Mono is reserved for code and the existing explainer label. Prose uses regular Newsreader with optical sizing, real italic, and semibold emphasis. Full fallback stacks are in the frontmatter. The shared layout loads these fonts from Google Fonts.

The root font size is 62.5%: at the browser's default 16px setting, 1rem is 10px. Preserve that context when reading the rem values; sidecar snippets use equivalent pixel sizes so they render correctly outside this root.

| Role | Existing treatment |
| --- | --- |
| Site name | `display`; 5rem at mobile, 5.8rem at tablet, 6.8rem above tablet. |
| Article title | `article-display`; centered, at most 22ch wide within the reading column; fluid 3.6–5.6rem, with 1.1 line height and -0.025em tracking. |
| Page title | 6.2rem, line height 1.02, tracking -0.04em; 4.8rem at mobile. |
| Section headings | `headline` for h2; h3 is 2.9rem and h4 is 2.2rem, with 1.18 line height inside articles and 1.08 elsewhere. |
| Article-list title | `title` in the archive and tags; 2.8rem at mobile and 3rem at tablet, with 1.15 line height. |
| Body | Articles and content pages share the `reading.prose` mixin: Newsreader at 2rem/1.65, reduced to 1.9rem on mobile, with the same paragraph, list, and heading rhythm. Interface text retains `body` sans-serif. |
| Navigation | `label` on internal pages; home links are 1.48rem above tablet. Uppercase, with weight 600 for the current page. |
| Metadata and tags | Article dates use 1.4rem sentence-case sans-serif with 0.02em tracking; article tags use 1.2rem with the same tracking. List dates remain 1.2rem uppercase with tabular numerals. |
| Code | `code` for blocks at 1.5rem/1.6; inline code is 0.8em of its surrounding text, with a faint warm background and baseline alignment. |

Headings use balanced wrapping; prose and list items use pretty wrapping where supported. Long technical terms and URLs can wrap without causing horizontal page scrolling. Source Sans 3 includes regular italic, JetBrains Mono includes bold and italic styles for syntax highlighting, and Newsreader loads optical sizes 6–72 at weights 400, 500, and 600 with reading italics. All families retain fallback stacks and `display=swap`. Font metric adjustment stays scoped to the existing home display; it is not inherited across different font families.

## Layout

**The Reading Column Rule.** Keep ordinary site content in the centered reading wrapper. The active large wrapper is capped at 810px; a 560px normal variant also exists. Both are 96% wide above tablet and 88% wide through tablet.

Article content is capped at the smaller of 66ch and 66rem, 660px at the default browser font size. About prose uses the same 66rem maximum while preserving the portrait layout. Both use 1.65 line height and 1em paragraph separation.

The source media ranges are mobile at at most 400px, tablet from 400px through 1050px, and a separate 780px split for embedded explainers. Article titles use a continuous fluid scale; list-title mobile rules follow tablet rules so their mobile sizes win at exactly 400px.

Main page content starts 125px below the top. On mobile, article navigation stays in document flow with 8rem before the title so enlarged text can wrap without overlapping the article. Article lists occupy 95% of the wrapper; rows devote 75% to the title and 25% to the right-aligned date. At mobile sizes, blog-row dates move above full-width titles. Section headings in articles gain 4.2rem above them; paragraph spacing is tighter within a section. The frontmatter records the source spacing scale, alongside these existing component-specific measurements.

The explainer embed is a deliberate exception: above 780px it can extend to `min(1480px, 94vw)` around the reading column. At 780px and below, the iframe is hidden and a compact panel links to the standalone explainer. Wider article images have their own source-defined breakout treatment.

## Elevation & Depth

**The Flat by Default Rule.** Use space, typography, and fine borders to separate ordinary content. Article rows and tags have no resting elevation.

The profile portrait is the small exception confirmed for this system: hover changes opacity to 0.8 and adds `0 0 4px 0 rgba(0,0,0,0.18), 0 0 12px 0 rgba(0,0,0,0.15)`. The white shadow around divider ornaments masks the rule beneath them; it does not lift a content surface.

## Shapes

Corners are mostly quiet: code uses the `code` radius, images use `image`, and article-row interaction backgrounds use `row`. Tags and status labels use `pill`; portraits are circular. Diagram frames use `diagram`, and the mobile explainer link uses `launcher`.

Thin horizontal rules recur between lists, author information, and the footer. List and footer dividers have a small outlined square at their midpoint. Blockquotes use a warm gray left rule.

## Components

### Navigation

Uppercase text links have no resting underline. Hover reveals a fine underline; keyboard focus adds an outline and reveals the rule. The current page uses darker text, weight 600, and a persistent underline. Home navigation has a centered variant; internal navigation sits at the upper right with reduced gaps and type on mobile.

### Article rows

Rows are open text links, not raised cards. Titles turn indigo on hover or focus within, and the row gains the faint indigo background recorded in `article-row-hover`. Dates remain smaller, uppercase, and secondary. The entire row is a link.

### Tags and status labels

Tags are compact pale-gray pills with uppercase labels. Tag-index labels use wider tracking (0.12em). Archived/unlisted status labels use the warm `status-*` colors, a thin border, 600 weight, and 0.1em tracking. Status labels are informational; tags link to topic sections. Both retain the shared focus treatment when interactive; the source defines no tag-specific hover fill.

### Prose, quotations, and code

Article prose links stay underlined and use the surrounding prose color until hover or focus. The shared link focus outline is 2px indigo at 24% opacity with a 0.25rem offset; navigation overrides its opacity and offset.

Blockquotes use a 2px warm-gray left rule, 2rem left padding, and the surrounding reading size. Code blocks sit on paper with a 1px pale border, small corners, and horizontal overflow. Inline code has a faint warm background, light padding, and cloned background fragments when it wraps. The `inline_code_breaks` filter inserts invisible break opportunities after identifier punctuation; it preserves code text and leaves code blocks untouched. Emergency wrapping still handles a single token wider than the column. Preserve the syntax palette rather than recoloring code as decorative branding.

### Explainers and alerts

The mobile explainer panel has a pale background, a thin border, and a solid indigo launch link with white text. Its focus outline is 3px indigo, offset by 3px. This is a contextual link treatment, not evidence of a general button or form library.

Markdown alerts use a colored title and left rule for their semantic variant. Mermaid diagrams sit in a pale framed container. Their colors remain local to those content types.

### Portrait, icons, and motion

The header portrait is circular (125px wide); the About portrait is proportional to the reading column. Social links use inline SVG icons and change from heading ink to indigo on hover or focus. Hover labels use a dark small-corner tooltip.

Navigation transitions run for 180ms; article rows and portrait interactions use 200ms; social tooltip opacity and movement use 150ms. The header entrance lasts 600ms after a 300ms delay and runs only when reduced motion is not requested. Other transitions retain their existing source behavior; this record does not claim universal motion suppression.

## Do's and Don'ts

### Do:

- **Do** pair Newsreader headings with Source Sans 3 body and interface text.
- **Do** preserve the reading wrapper and documented content-specific breakouts.
- **Do** keep navigation selection visible and article links recognizable without hover.
- **Do** retain keyboard focus indicators and the reduced-motion guard on the header entrance.
- **Do** keep code, status, alerts, and diagrams semantically distinct from the general accent.

### Don't:

- **Don't** turn the article list into a grid of elevated cards.
- **Don't** use the portrait hover shadow as a resting surface treatment.
- **Don't** promote standalone explainer palettes into the shared site palette.
- **Don't** treat synthesized tonal ramps or unimplemented form controls as existing design tokens or components.
