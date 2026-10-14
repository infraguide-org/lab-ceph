# lab-ceph

Deploy and operate a Ceph cluster from scratch.
The lab needs one bare-metal server with virtualization enabled.

Lab description: [infraguide.org/learn/ceph](https://infraguide.org/learn/ceph/)

## Repository layout
| Path | Content |
|---|---|
| `conf/` | `env.yaml` - network and host layout of the environment, `tmuxp.yaml` - tmux session with a window per host group |
| `deploy/cephadm/` | cephadm configuration of the Ceph cluster |
| `modules/` | additional modules, none yet |
| `slides/` | slide sources (`src`) and the script that builds the index page and `index.json` (`scripts`) |
| `status/` | `build.yml` - result of the automatic lab build, shown on the lab page |

## Slides
The slides are published on GitHub Pages: [infraguide-org.github.io/lab-ceph](https://infraguide-org.github.io/lab-ceph/)

| Deck | Content | Files |
|---|---|---|
| Deploy | Deploy and operate a Ceph cluster from scratch | `slides-deploy` |

Every deck is available as HTML, PDF and PPTX, for example
`https://infraguide-org.github.io/lab-ceph/slides-deploy.pdf`.
[`index.json`](https://infraguide-org.github.io/lab-ceph/index.json) lists the decks in their order, all files, the hosts of the environment (`hosts`) and the path of the environment diagram (`diagram`) in a machine-readable form.
The slides are also part of [infraguide.org](https://infraguide.org/learn/ceph/).

## How to create slides
The sources are Markdown files in `slides/src`, rendered with [Marp](https://marp.app/):

```bash
cd slides/src
marp          # html
marp --pdf    # pdf
marp --pptx   # pptx
```

The output goes to `slides/dist`. Every push to `main` that changes `slides/src`, `slides/scripts`, `conf/env.yaml`
or `status/` builds the slides and the index page and publishes them with the workflow `.github/workflows/slides.yml`.
The order of the decks is set by the `order` field in the front matter of each deck.
