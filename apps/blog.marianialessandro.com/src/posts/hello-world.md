---
title: 'Hello world'
date: '2025-08-01'
description: 'A complete example for checking every PostLayout element'
tags: ['design-system', 'test', 'markdown', 'sveltekit']
draft: false
---

# Content heading (H1)

This post is meant to **test** the layout. It includes examples of _almost everything_.

> Note: the heading above is an H1 inside the content and **should appear** in the ToC.
> The title from front matter (`meta.title`) is rendered by the article header and **should not** appear in the ToC.

---

## Basic section (H2)

Sample paragraph with **bold**, _italic_, highlighted text with <mark>mark</mark>, and `inline code`.
External link: <https://kit.svelte.dev>

### Lists (H3)

- Simple item
- Item with a second line that tests **line wrapping** when it is too long to fit on a single line inside the container.
  - Nested item
  - Another nested item
- Mixed list with `inline code`

### Ordered lists (H3)

1. First
2. Second
3. Third

### Task list (H3)

- [x] Done
- [ ] To do
- [ ] Another item

### Quote (H3)

> “A quote with two paragraphs to check spacing.
>
> Second paragraph of the same quote.”

### Code (H3)

TypeScript example:

```text
export function greet(name: string): string {
	const msg = `Hello, ${name}!`;
	return msg;
}
```

#### Shell (H4)

```bash
# Installation
pnpm install

# Dev server
npm run dev -- --open
```

#### Long line example (H4)

```text
const url =
	'https://example.com/path/very-long/with/many/segments/that/test/code-block-overflow?query=with-parameters&anchor=#hash';
```

---

## Tables (H2)

| Component | Purpose            | Status |
| --------: | ------------------ | :----- |
|   `h1-h4` | Navigation/ToC     | OK     |
|     Lists | Hierarchical text  | OK     |
|      Code | Technical examples | OK     |
|   Figures | Images + captions  | OK     |
| Footnotes | Textual references | OK     |

> Rows and columns should use `border-bottom` and tabular fonts.

---

## Images & Figures (H2)

Figure with caption:

<figure>
  <img src="https://picsum.photos/1200/600" alt="Abstract placeholder landscape" />
  <figcaption>Figure 1 - Placeholder 1200x600, useful for checking responsive behavior.</figcaption>
</figure>

Standalone image without `<figure>`:

<img src="https://picsum.photos/800/450" alt="Second abstract placeholder" />

---

## Expandable Details (H2)

<details>
  <summary>Click to open details</summary>
  <p>Hidden content for testing HTML elements that are not explicitly styled.</p>
</details>

---

## Very Long Link (H2)

This link should wrap correctly:
[https://this-is-a-very-long-url.example/subfolder/even-longer/with-parameters?one=1\&two=2\&three=3\&four=4#section](https://this-is-a-very-long-url.example/subfolder/even-longer/with-parameters?one=1&two=2&three=3&four=4#section)

---

## Section with Accents & Symbols! (H2)

Title with diacritics and symbols for testing **slugify** -> expected: `section-with-accents-symbols`.

### Subsection (H3)

Any content.

#### Depth (H4)

One more level to check ToC indentation.

## Section with Accents & Symbols! (H2)

Same text as the previous heading to verify ID **de-duplication** with the expected `-2` suffix.

---

## Footnote References (H2)

This sentence has a note.[^note1] And another one.[^note2]
Reuse of the first note here.[^note1]

[^note1]: Text for **note 1** with a link to [https://example.com](https://example.com).

[^note2]: Text for **note 2**.
