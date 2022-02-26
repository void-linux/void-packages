#!/usr/bin/env python3

from dataclasses import asdict, dataclass, field
import json
from pathlib import Path
import re
import sys
from typing import Optional


HEADING_RE = re.compile(r"###? (?:\w|\d)")
ANCHOR_RE = re.compile(r'<a id=".+"></a>')
REL_LINK_RE = re.compile(r"\[(.*)\]\(\./(.*)\)")


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


def slugify(s: str) -> str:
    return s.lower().replace(" ", "-").replace(".", "-").replace("`", "")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1] == "supports":
            raise SystemExit

    doc = Path("Manual.md").read_text().split("\n")

    sections = []
    curr_chapter = []
    hlevel = None
    heading = None
    fn = None
    in_section = False

    for line in doc:
        line = REL_LINK_RE.sub(r"[\1](https://github.com/void-linux/void-packages/blob/master/\2)", line)

        if HEADING_RE.match(line):
            if in_section:
                if ANCHOR_RE.search(curr_chapter[-1]):
                    del curr_chapter[-1]

                sections.append(
                    Section(
                        Chapter(
                            name=heading,
                            number=num,
                            content="\n".join(curr_chapter),
                            path=fn,
                            source_path=fn,
                        )
                    )
                )
            curr_chapter = ["#" + line.lstrip("#")]
            hlevel, heading = line.split(" ", maxsplit=1)
            fn = f"./{slugify(heading)}.md"

            match len(hlevel):
                # intro/help
                case 2:
                    num = None
                # other "top" level headings
                case 3:
                    num = [ len(sections) ]
                case _:
                    continue

            in_section = True
        elif in_section:
            curr_chapter.append(line.replace("####", "##", 1))

    # get the last section
    sections.append(
        Section(
            Chapter(
                name=heading,
                number=num,
                content="\n".join(curr_chapter),
                path=fn,
                source_path=fn,
            )
        )
    )

    # mdBook requires this key in the emitted json, for reasons unknown
    book = asdict(Book(sections)) | {"__non_exhaustive": None}
    print(json.dumps(book))
