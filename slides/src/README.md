# Marp slide sources

Markdown sources for workshop slides, rendered with [Marp](https://marp.app/).

## How to create slides
Use `../scripts/build.sh`, not `marp` directly:
```bash
../scripts/build.sh                   # html into ../dist, the default
../scripts/build.sh . html pdf pptx   # html, pdf and pptx (slower)
```
The decks go to `../dist`, and the script copies `assets/` there as well. The built html
references the pictures relative to itself, so a bare `marp` run leaves the slides without
them. It uses `marp` from `$PATH`, or `npx @marp-team/marp-cli@4` when there is none; set
`MARP` to pick another command.

The script builds from a copy of these sources in a temporary directory, so the diagram
step below never writes into the sources.

## PlantUML diagrams
Marp knows no PlantUML, so `../scripts/plantuml-embed.py` replaces every ```` ```plantuml ````
block in the copy with an image that a PlantUML server renders:
````markdown
```plantuml alt="Infrastructure overview" width="700px"
!include <edgy/edgy>
...
```
````
`alt`, `width` and `height` are optional and become the alt text and the size of the Marp
image. A size in pixels also travels to the server as a `scale` directive, so the server
already renders the diagram in that size; a percentage only sizes the Marp image. The
diagram itself travels deflated inside the image url, so the server renders it without any
access to this repository.

* The default server is https://www.plantuml.com/plantuml; set `PLANTUML_SERVER` to use
  another one, e.g. `PLANTUML_SERVER=http://localhost:8080` for a self-hosted server.
* The step needs `python3`. Without it the build prints a warning and the blocks stay
  code blocks.
* The server has to be reachable: the html loads the diagram when a slide is shown, pdf
  and pptx already while they are built.

Mermaid diagrams work differently: they are rendered in the browser by the script in the
deck front matter and therefore only show up in the html.

## Publishing
Every push to `main` that changes `slides/src/**` runs `.github/workflows/slides.yml`.
It builds html, pdf and pptx and uploads `slides/dist` as the GitHub Pages artifact, so the
files are served as they are, without a Jekyll build:
https://infraguide-org.github.io/lab-ceph/ (`index.json` lists the decks).
The infraguide.org build fetches the files from there.
All pictures must be local files under `assets/`, no references to infraguide.org. The
PlantUML and mermaid diagrams are the exception, as they come from their render server
resp. CDN; put a picture under `assets/` if a deck has to work offline.
