import json, os, struct, sys

endian = "<" if os.environ.get("XBPS_TARGET_ENDIAN", "le") == "le" else ">"
idx, hdrsz = 0, struct.calcsize(hdrfmt := f"{endian}3I")
buf, shlibs = sys.stdin.buffer.read(), set()
while idx < len(buf):
	namesz, descsz, type_ = struct.unpack_from(hdrfmt, buf, idx)
	idx += hdrsz
	if not (namesz or descsz or type_):
		continue
	name = buf[idx:idx+namesz].decode().rstrip("\0")
	idx += namesz
	descsz = descsz if descsz & 3 == 0 else (descsz | 3) + 1 # align to next 4 byte alignment
	if name == "FDO" and type_ == 0x407c0c0a:
		desc = buf[idx:idx+descsz].decode().rstrip("\0")
		for item in json.loads(desc):
			if item.get("priority", "required") in ("recommended", "required"):
				shlibs.update(item.get("soname", []))
	idx += descsz
print("\n".join(sorted(shlibs)))
