# Source: https://github.com/infraguide-org/lab-ceph
# Copyright (c) 2026 infraguide.org, MIT License
#
# Replaces the ```plantuml code blocks of the given markdown files with an image that a
# PlantUML server renders, because Marp itself does not know PlantUML. The diagram is
# deflated into the image url, so the server needs no access to the sources.
# Usage: plantuml-embed.py <server-url> <file.md>...
# A block may carry alt="..." width="..." height="...", e.g.
# ```plantuml alt="Overview" width="700px". They become the alt text and the size keywords
# of the Marp image, and the size also goes to the server as a scale directive, so the svg
# arrives in the wanted size no matter how the renderer handles the keywords.
import re
import sys
import zlib

ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
BLOCK = re.compile(r"^```plantuml[ \t]*([^\n]*)\n(.*?)\n?^```[ \t]*$", re.DOTALL | re.MULTILINE)


def encode(diagram):
    """Deflate and encode the diagram the way the PlantUML servers expect it in the url."""
    deflate = zlib.compressobj(9, zlib.DEFLATED, -15)
    data = deflate.compress(diagram.encode()) + deflate.flush()
    url = ""
    for start in range(0, len(data), 3):
        chunk = data[start:start + 3] + b"\0\0"   # the last chunk is padded with zeros
        url += (ALPHABET[chunk[0] >> 2]
                + ALPHABET[(chunk[0] & 0x03) << 4 | chunk[1] >> 4]
                + ALPHABET[(chunk[1] & 0x0F) << 2 | chunk[2] >> 6]
                + ALPHABET[chunk[2] & 0x3F])
    return url


def scale(attributes):
    """Turn width/height into the PlantUML scale directive that sizes the rendered svg."""
    sizes = {name: attributes.get(name, "").removesuffix("px") for name in ("width", "height")}
    sizes = {name: value for name, value in sizes.items() if value.isdigit()}
    if len(sizes) == 2:
        return "scale %s*%s" % (sizes["width"], sizes["height"])   # fit into the box
    for name, value in sizes.items():
        return "scale %s %s" % (value, name)
    return ""   # no size, or one in units the server does not take, e.g. a percentage


def image(server, options, diagram):
    """Build the Marp image tag that points to the diagram on the PlantUML server."""
    attributes = dict(re.findall(r'([a-z]+)="([^"]*)"', options))
    if not diagram.lstrip().startswith("@start"):
        diagram = "@startuml\n%s\n@enduml" % diagram
    directive = scale(attributes)
    if directive:   # right behind @startuml, where the server expects its directives
        diagram = re.sub(r"@start\w+[^\n]*\n", lambda start: start[0] + directive + "\n",
                         diagram, count=1)
    keywords = ["%s:%s" % (short, attributes[name])
                for name, short in (("width", "w"), ("height", "h")) if name in attributes]
    keywords.append(attributes.get("alt", "PlantUML diagram"))
    return "![%s](%s/svg/%s)" % (" ".join(keywords), server, encode(diagram))


def main(server, paths):
    for path in paths:
        with open(path, encoding="utf-8") as markdown:
            text = markdown.read()
        embedded = BLOCK.sub(lambda block: image(server, block[1], block[2]), text)
        if embedded != text:
            with open(path, "w", encoding="utf-8") as markdown:
                markdown.write(embedded)
            print("plantuml-embed: %s diagram(s) in %s" % (len(BLOCK.findall(text)), path))


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(__doc__ or "usage: plantuml-embed.py <server-url> <file.md>...")
    main(sys.argv[1].rstrip("/"), sys.argv[2:])
