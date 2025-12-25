---
title: "Hello world"
date: "2025-08-01"
description: "Esempio completo per verificare ogni elemento del PostLayout"
tags: ["design-system", "test", "markdown", "sveltekit"]
draft: false
---

# Intestazione nel contenuto (H1)

Questo post serve per **testare** il layout. Contiene esempi di _quasi tutto_.  

> Nota: il titolo sopra è un H1 nel contenuto e **deve apparire** nel ToC.
> Il titolo preso dal front-matter (`meta.title`) viene reso con `.post-title` e **non** deve comparire nel ToC.

---

## Sezione base (H2)

Paragrafo di prova con **grassetto**, _corsivo_, testo evidenziato con <mark>mark</mark> e `inline code`.
Link esterno: <https://kit.svelte.dev>

### Liste (H3)

- Punto semplice
- Punto con seconda riga che testa l’**andata a capo** quando è troppo lunga per stare su una sola linea dentro il contenitore.
  - Sotto-punto (lista annidata)
  - Altro sotto-punto
- Lista mista con `inline code`

### Liste ordinate (H3)

1. Primo
2. Secondo
3. Terzo

### Task list (H3)

- [x] Fatto
- [ ] Da fare
- [ ] Un altro elemento

### Citazione (H3)

> “Una citazione con due paragrafi per vedere la spaziatura.
>
> Secondo paragrafo della stessa citazione.”

### Codice (H3)

Esempio TypeScript:

```ts
export function greet(name: string): string {
  const msg = `Ciao, ${name}!`;
  return msg;
}
````

#### Shell (H4)

```bash
# Installazione
pnpm install

# Dev server
npm run dev -- --open
```

#### Esempio con riga lunga (H4)

```js
const url = "https://example.com/path/super-lungo/con/tanti/segmenti/che/mettono/alla/prova/l'overflow/del/blocco/di/codice?query=con-parametri&ancora=#hash";
```

---

## Tabelle (H2)

| Componente | Scopo                 | Stato |
| ---------: | --------------------- | :---- |
|    `h1–h4` | Navigazione/ToC       | OK    |
|      Liste | Contenuti gerarchici  | OK    |
|     Codice | Esempi tecnici        | OK    |
|     Figure | Immagini + didascalia | OK    |
|  Footnotes | Riferimenti testuali  | OK    |

> Righe e colonne dovrebbero usare `border-bottom` e font tabulari.

---

## Immagini & Figure (H2)

Figura con didascalia:

<figure>
  <img src="https://picsum.photos/1200/600" alt="Immagine di test (placeholder)" />
  <figcaption>Figura 1 — Placeholder 1200×600, utile per vedere il comportamento responsive.</figcaption>
</figure>

Immagine singola (senza `<figure>`):

<img src="https://picsum.photos/800/450" alt="Altra immagine di test" />

---

## Dettagli espandibili (H2)

<details>
  <summary>Clicca per aprire i dettagli</summary>
  <p>Contenuto nascosto per testare elementi HTML non stilizzati esplicitamente.</p>
</details>

---

## Link molto lungo (H2)

Questo link deve andare a capo correttamente:
[https://questa-e-una-url-molto-lunga.example/sottocartella/ancora/piu-lunga/con-parametri?uno=1\&due=2\&tre=3\&quattro=4#sezione](https://questa-e-una-url-molto-lunga.example/sottocartella/ancora/piu-lunga/con-parametri?uno=1&due=2&tre=3&quattro=4#sezione)

---

## Sezione con accénti & simboli! (H2)

Titolo con diacrìtici e simboli per testare lo **slugify** → atteso: `sezione-con-accenti-simboli`.

### Sottosezione (H3)

Contenuto qualsiasi.

#### Profondità (H4)

Ancora un livello per verificare l’indentazione del ToC.

## Sezione con accénti & simboli! (H2)

Stesso testo del titolo precedente per verificare la **de-duplicazione** degli ID (atteso suffisso `-2`).

---

## Riferimenti a piè di pagina (H2)

In questa frase c’è una nota.[^nota1] E anche un’altra.[^nota2]
Riuso della prima nota qui.[^nota1]

[^nota1]: Testo della **nota 1** con un link a [https://example.com](https://example.com).

[^nota2]: Testo della **nota 2**.
