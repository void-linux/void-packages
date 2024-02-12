# Converts xlint/etc format lints into GH Actions annotations
# The original line is printed alongside the annotation command
{
	split($0, a, ": ")
	split(a[1], b, ":")
	msg = substr($0, index($0, ": ") + 2)
	severity = "error"
	if (b[3]) {
		line = ",line=" b[3]
		severity = b[2]
	} else if (b[2]) {
		line = ",line=" b[2]
	}
	printf "::%s title=Template Lint,file=%s%s::%s\n", severity, b[1], line, msg
}
