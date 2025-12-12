#!/usr/bin/python3

import sys
from abc import ABC, abstractmethod
from configparser import ConfigParser
from dataclasses import dataclass
from pathlib import Path

@dataclass
class Wrap(ABC):
	src_path: Path

	directory: str | None = None
	patch_url: str | None = None
	patch_fallback_url: str | None = None
	patch_filename: str | None = None
	patch_hash: str | None = None
	patch_directory: str | None = None
	diff_files: str | None = None
	method: str | None = None

	@property
	@abstractmethod
	def distfile(self):
		raise NotImplementedError

	@property
	@abstractmethod
	def checksum(self):
		raise NotImplementedError

	@property
	@abstractmethod
	def filename(self):
		raise NotImplementedError


@dataclass
class WrapFile(Wrap):
	source_url: str | None = None
	source_fallback_url: str | None = None
	source_filename: str | None = None
	source_hash: str | None = None
	lead_directory_missing: str | None = None

	@property
	def distfile(self):
		if self.source_url:
			return f"{self.source_url}>{self.filename}"
		raise ValueError(f"missing source_url in wrap {self.src_path}")

	@property
	def checksum(self):
		if self.source_hash:
			return self.source_hash
		raise ValueError(f"missing source_hash in wrap {self.src_path}")

	@property
	def filename(self):
		if self.source_filename:
			return self.source_filename
		raise ValueError(f"missing source_filename in wrap {self.src_path}")


def read_wrap(p: Path) -> Wrap:
	wrap = ConfigParser()
	with p.open() as f:
		wrap.read_file(f)

	for sec in wrap.sections():
		if sec.startswith("wrap-"):
			break
	else:
		raise ValueError(f"missing 'wrap-*' section in wrap {p}")

	match sec:
		case "wrap-file":
			cls = WrapFile
		case "wrap-git":
			raise NotImplementedError
		case "wrap-hg":
			raise NotImplementedError
		case "wrap-svn":
			raise NotImplementedError
		case _:
			raise NotImplementedError

	return cls(src_path=p, **dict(wrap.items(sec)))


def print_list(var: str, contents: list[str]):
	print(f"""{var}+="
 {"\n ".join(contents)}
\"""")


if __name__ == "__main__":
	distfiles = []
	checksums = []
	skip_extracts = []

	if len(sys.argv[1:]) < 1:
		print(f"usage: {sys.argv[0]} <wrap files...>")
		exit()

	for arg in sys.argv[1:]:
		wrap_path = Path(arg)
		if wrap_path.is_file():
			try:
				wrap = read_wrap(wrap_path)

				distfiles.append(wrap.distfile)
				checksums.append(wrap.checksum)
				skip_extracts.append(wrap.filename)
			except ValueError as e:
				print("=> ERROR:", e, file=sys.stderr)

	print_list("distfiles", distfiles)
	print_list("checksum", checksums)
	print_list("skip_extraction", skip_extracts)
