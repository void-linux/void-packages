#!/usr/bin/python3

import json
import os
import sys

wordsz = 4 # Elf32_Word and Elf64_Word

def align_up(v: int) -> int:
	if v % wordsz == 0:
		return v
	return v + (wordsz - (v % wordsz))

if __name__ == "__main__":
	endian = "little" if os.environ.get("XBPS_TARGET_ENDIAN", "le") == "le" else "big"
	shlibs = set()
	while True:
		try:
			namesz = int.from_bytes(sys.stdin.buffer.read(wordsz), byteorder=endian)
			descsz = int.from_bytes(sys.stdin.buffer.read(wordsz), byteorder=endian)
			type_ = int.from_bytes(sys.stdin.buffer.read(wordsz), byteorder=endian)

			if namesz == 0 and descsz == 0 and type_ == 0:
				break

			name = sys.stdin.buffer.read(namesz).decode().rstrip("\0")
			desc = sys.stdin.buffer.read(align_up(descsz)).decode().rstrip("\0")

			if name == "FDO" and type_ == 0x407c0c0a:
				data = json.loads(desc)
				for item in data:
					if item.get("priority", "required") in ("recommended", "required"):
						shlibs.update(item.get("soname", []))
		except EOFError:
			break

	for shlib in shlibs:
		print(shlib)
