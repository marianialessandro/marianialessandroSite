# Cover Prompt

Prompt base da usare con Gemini per generare cover coerenti con lo stile attuale del blog.

```text
Generate a blog cover image for a personal technical/product blog.

Visual style:
Minimal editorial design, clean white background, subtle cool-gray structure, crisp geometry, quiet professional mood. Use a small but intentional Svelte-orange accent (#ff3e00). The image should feel like a refined engineering notebook, not a marketing banner.

Composition:
16:9 landscape cover image, suitable for a blog card and article hero. Leave some calm negative space. Use abstract but meaningful visual metaphors: workbench notes, small interface fragments, code-like grids, decision paths, archive cards, calendar marks, lightweight diagrams, modular blocks.

Color palette:
Mostly white (#ffffff), near-black (#0b0f14), muted gray (#4b5563), light border gray (#e5e7eb), with restrained orange accents (#ff3e00). Optional very subtle desaturated blue-gray details.

Rendering:
High-resolution, sharp, modern, flat-to-lightly-dimensional illustration. Soft shadows, thin lines, rounded rectangles with subtle borders, no heavy gradients, no neon, no dark background.

Important constraints:
No readable text, no logos, no fake UI labels, no people, no stock photo look, no clutter, no dramatic lighting, no purple/blue gradient background. The image must work when cropped with object-fit: cover.
```

Per un singolo post, aggiungere in fondo:

```text
Article topic: "[TITOLO DEL POST]"
Article description: "[DESCRIZIONE]"
Tags: [TAG1, TAG2, TAG3]

Create a visual metaphor for this topic while preserving the exact style above.
```

Formato consigliato: 1792x1024, o comunque 16:9.

## Esempi

### Building in public

```text
Article topic: "Building in public"
Article description: "Small product notes, experiments, and decisions from the workbench"
Tags: product, notes, process

Create a minimal editorial cover showing a tidy digital workbench: small note cards, branching decision lines, tiny product blocks, and one orange active marker. No readable text.
```

### Notes on 2026

```text
Article topic: "Notes on 2026"
Article description: "A short note to check how the archive groups posts in 2026"
Tags: notes, archive

Create a minimal editorial cover showing an abstract archive timeline: grouped cards by year, subtle calendar structure, light gray grid lines, and one restrained orange highlight. No readable text.
```

### Summer maintenance

```text
Article topic: "Summer maintenance"
Article description: "A current-year placeholder post for testing latest archive ordering"
Tags: maintenance, sveltekit

Create a minimal editorial cover showing a clean maintenance scene for a web project: modular UI panels being aligned, tiny tool indicators, subtle Svelte-orange accents, lots of white space. No readable text.
```

## Note pratiche

Evitare testo dentro l'immagine: il layout del blog aggiunge gia titolo, data, descrizione e tag. Le cover devono restare leggibili anche quando vengono ritagliate da `object-fit: cover`.
