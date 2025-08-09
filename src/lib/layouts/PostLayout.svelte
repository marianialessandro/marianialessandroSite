<!-- src/lib/components/PostLayout.svelte -->
<script lang="ts">
  export let Content: any;   // componente mdsvex dell’articolo
  export let meta: { title?: string; description?: string; date?: string } = {};
  // Mostra l'H1 sopra al contenuto se presente meta.title
  export let showTitleFromMeta: boolean = true;
</script>

<article class="post" aria-label="Articolo">
  {#if showTitleFromMeta && meta.title}
    <h1 class="post-title">{meta.title}</h1>
  {/if}

  <svelte:component this={Content} />
</article>

<style>
  :global(:root){
    --post-max-width: 70ch;
    --post-font-serif: inherit;
    --post-font-sans: inherit;
    --post-font-mono: inherit;

    --post-text: #121212;
    --post-muted: #666;
    --post-border: #e5e5e5;
    --post-link: #0a66c2;
    --post-code-bg: #f6f8fa;
    --post-quote: #444;
    --post-quote-bar: #ddd;
    --post-hr: #efefef;
    --post-figcap: #777;
    --post-mark: #fff6a8;
  }
  
  /* ——— Contenitore ——— */
  .post{
    color: var(--post-text);
    font-family: var(--post-font-serif);
    font-size: clamp(1.02rem, 0.9rem + 0.5vw, 1.18rem);
    line-height: 1.65;
    max-width: var(--post-max-width);
    margin: 0 auto;
    padding: clamp(16px, 2.5vw, 28px) 16px 80px;
    text-rendering: optimizeLegibility;
    -webkit-font-smoothing: antialiased;
    font-kerning: normal;
    word-break: normal;
    overflow-wrap: anywhere;
  }

  /* Spaziatura blocchi */
  .post :global(p),
  .post :global(ul),
  .post :global(ol),
  .post :global(pre),
  .post :global(blockquote),
  .post :global(table),
  .post :global(figure){
    margin: 0 0 1.1em 0;
  }

  /* ——— Headings ——— */
  .post :global(h1),
  .post :global(h2),
  .post :global(h3),
  .post :global(h4){
    font-family: var(--post-font-serif);
    line-height: 1.25;
    font-weight: 700;
    letter-spacing: -0.01em;
    margin: 1.6em 0 0.6em;
    text-align: left; /* tutti gli heading di default a sinistra */
  }
  .post :global(h1){ font-size: clamp(2rem, 1.5rem + 1.8vw, 3rem); }
  .post :global(h2){ font-size: clamp(1.6rem, 1.3rem + 1.2vw, 2.2rem); }
  .post :global(h3){ font-size: clamp(1.3rem, 1.1rem + 0.8vw, 1.6rem); }
  .post :global(h4){ font-size: 1.1rem; }

  /* Titolo pagina (da meta.title) centrato */
  .post h1.post-title{
    text-align: center;
    margin: 0 0 .6em 0;       /* più vicino all’inizio pagina */
  }

  /* Paragrafi e testo */
  .post :global(p){ color: var(--post-text); }
  .post :global(p + p){ margin-top: 0.2em; }
  .post :global(em){ font-style: italic; }
  .post :global(strong){ font-weight: 700; }
  .post :global(mark){ background: var(--post-mark); padding: 0 .15em; }

  /* Link */
  .post :global(a){
    color: var(--post-link);
    text-decoration: underline;
    text-decoration-thickness: from-font;
    text-underline-offset: 2px;
  }
  .post :global(a:hover){ opacity: .9; }

  /* Liste */
  .post :global(ul), .post :global(ol){ padding-left: 1.25em; }
  .post :global(li){ margin: .3em 0; }
  .post :global(ul){ list-style: disc; }
  .post :global(ol){ list-style: decimal; }

  /* Citazioni */
  .post :global(blockquote){
    color: var(--post-quote);
    font-style: italic;
    padding: .1em 1.1em;
    border-left: 3px solid var(--post-quote-bar);
    margin: 1.4em 0;
  }

  /* Codice */
  .post :global(code){
    font-family: var(--post-font-mono);
    font-size: 0.92em;
    background: var(--post-code-bg);
    padding: .15em .35em;
    border-radius: 4px;
  }
  .post :global(pre){
    background: var(--post-code-bg);
    padding: 1em;
    border-radius: 8px;
    overflow: auto;
  }
  .post :global(pre code){ background: transparent; padding: 0; }

  /* Immagini / figure */
  .post :global(img){
    display: block;
    max-width: 100%;
    height: auto;
    margin: 1.2em auto;
    border-radius: 8px;
  }
  .post :global(figure){ text-align: center; }
  .post :global(figcaption){
    font-family: var(--post-font-sans);
    color: var(--post-figcap);
    font-size: .9rem;
    margin-top: .4em;
  }

  /* Tabelle */
  .post :global(table){
    width: 100%;
    border-collapse: collapse;
    font-variant-numeric: tabular-nums;
  }
  .post :global(th),
  .post :global(td){
    border-bottom: 1px solid var(--post-border);
    padding: .6em .4em;
    text-align: left;
    vertical-align: top;
  }
  .post :global(thead th){
    font-family: var(--post-font-sans);
    font-size: .9rem;
    color: var(--post-muted);
    font-weight: 600;
  }

  /* HR */
  .post :global(hr){
    border: 0;
    height: 1px;
    background: var(--post-hr);
    margin: 2em 0;
  }

  /* Note a piè di pagina (mdsvex/remark) */
  .post :global(sup[id^="fnref"] a),
  .post :global(a.footnote-ref){
    text-decoration: none;
    font-variant-position: super;
  }
  .post :global(section.footnotes){
    border-top: 1px solid var(--post-hr);
    margin-top: 2em;
    padding-top: 1em;
    font-size: .95em;
  }

  /* Responsive: allarga un filo su desktop */
  @media (min-width: 1100px){
    :global(:root){ --post-max-width: 72ch; }
  }
</style>
