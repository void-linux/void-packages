#!/usr/bin/env python3

from dataclasses import asdict, dataclass, field
import json
from pathlib import Path
import re
import sys
from typing import Optional


BEGCUT_RE = re.compile("<!-- mdbook:cut -->")
ENDCUT_RE = re.compile(r"<!-- mdbook:endcut -->")

BEGPAGE_RE = re.compile(r"<!-- mdbook:page:(?P<name>[^ ]+) -->")
ENDPAGE_RE = re.compile(r"<!-- mdbook:endpage -->")


@dataclass
class Chapter:
    name: str
    content: str
    path: str
    source_path: str
    number: Optional[list[int]] = None
    sub_items: list['Chapter'] = field(default_factory=list)
    parent_names: list[str] = field(default_factory=list)


@dataclass
class Section:
    Chapter: Chapter


@dataclass
class Book:
    sections: list[Section]


if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1] == "supports":
            raise SystemExit

    doc = Path("Manual.md").read_text()

    # remove TOC anchor links
    doc = re.sub(r'<a id="[^"]+"></a>', "", doc)
    # increase heading levels (Manual.md uses ### as the highest level)
    doc = re.sub(r"^##(#+ .+)$", r"\1", doc, flags=re.MULTILINE)
    # replace relative links with absolute ones
    doc = re.sub(
        r"\[(?P<text>[^\]]+)\]\(\./(?P<url>[^)]+)\)",
        r"[\g<text>](https://github.com/void-linux/void-packages/blob/master/\g<url>)",
        doc
    )
    if False:
        print(doc)
        raise SystemExit

    sections = []
    chapter = []
    num = 1
    heading = ""
    filename = ""
    in_section = False
    in_cut = False

    for lno, line in enumerate(doc.split("\n")):
        if BEGCUT_RE.search(line):
            in_cut = True
        elif in_cut:
            if ENDCUT_RE.search(line):
                in_cut = False
            elif BEGCUT_RE.search(line):
                raise SyntaxError(
                    "missing end-of-cut marker",
                    ("Manual.md", lno+1, 1, line, lno+1, len(line))
                )
        elif m := BEGPAGE_RE.search(line):
            filename = f"{m.group('name')}.md"
            in_section = True
        elif in_section:
            if ENDPAGE_RE.search(line):
                sections.append(
                    Section(
                        Chapter(
                            name=heading,
                            number=[num],
                            content="\n".join(chapter),
                            path=filename,
                            source_path=filename,
                        )
                    )
                )
                num += 1
                heading = ""
                chapter = []
                in_section = False
            elif line.startswith("# ") and not heading:
                _, _, heading = line.partition(" ")
                chapter += [line]
            elif BEGPAGE_RE.search(line):
                raise SyntaxError(
                    "missing end-of-page marker",
                    ("Manual.md", lno+1, 1, line, lno+1, len(line))
                )
            else:
                chapter += [line]

    # get the last section
    sections.append(
        Section(
            Chapter(
                name=heading,
                number=[num],
                content="\n".join(chapter),
                path=filename,
                source_path=filename,
            )
        )
    )

    # mdBook requires this key in the emitted json, for reasons unknown
    book = asdict(Book(sections)) | {"__non_exhaustive": None}
    print(json.dumps(book))
