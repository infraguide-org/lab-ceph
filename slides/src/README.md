# Marp slide sources

Markdown sources for workshop slides, rendered with [Marp](https://marp.app/).
This directory is excluded from Jekyll builds (see `exclude` in `_config.yml`).

## How to create slides
```bash
marp          # html slides
marp --pdf    # pdf
marp --pptx   # pptx
```

## Publishing
Every push to `main` that changes `slides/src/**` runs `.github/workflows/slides.yml`.
It builds html, pdf and pptx and deploys them to GitHub Pages:
https://infraguide-org.github.io/lab-ceph/ (`index.json` lists the decks).
The infraguide.org build fetches the files from there.
All pictures must be local files under `assets/`, no references to infraguide.org.
