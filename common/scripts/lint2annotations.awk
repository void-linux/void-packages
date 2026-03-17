# Converts xlint/etc format lints into GH Actions annotations
# The original line is printed alongside the annotation command
{
	split($0, a, ": ")
	split(a[1], b, ":")
	msg = substr($0, index($0, ": ") + 2)
	if (b[2]) {
		line = ",line=" b[2]
	}
	printf "::error title=Template Lint,file=%s%s::%s\n", b[1], line, msg
}
