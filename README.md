# lab-ceph

Deploy and operate a Ceph cluster from scratch.
The lab needs one bare-metal server with virtualization enabled.

Lab description: [infraguide.org/learn/ceph](https://infraguide.org/learn/ceph/)

## Slides
The slides are published on GitHub Pages: [infraguide-org.github.io/lab-ceph](https://infraguide-org.github.io/lab-ceph/)

| Deck | Content | Files |
|---|---|---|
| Deploy | Deploy and operate a Ceph cluster from scratch | `slides-deploy` |

Every deck is available as HTML, PDF and PPTX, for example
`https://infraguide-org.github.io/lab-ceph/slides-deploy.pdf`.
[`index.json`](https://infraguide-org.github.io/lab-ceph/index.json) lists all decks and files in a machine-readable form.
The slides are also part of [infraguide.org](https://infraguide.org/learn/ceph/).

## How to create slides
The sources are Markdown files in `slides/src`, rendered with [Marp](https://marp.app/):

```bash
cd slides/src
marp          # html
marp --pdf    # pdf
marp --pptx   # pptx
```

The output goes to `slides/dist`. Every push to `main` that changes `slides/src` or `slides/scripts`
builds the slides and publishes them with the workflow `.github/workflows/slides.yml`.
