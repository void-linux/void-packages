#
# Replaces hardcoded shebang files in some scripts.
#
# Perl files with hardcoded shebang path.
mono_perl_files="mcs/errors/do-tests.pl mcs/tools/scan-tests.pl
msvc/create-windef.pl mono/benchmark/test-driver mono/cil/make-opcodes-def.pl
mono/metadata/make-bundle.pl mono/mini/genmdesc.pl mono/tests/stress-runner.pl"
#
# Bash files with hardcoded shebang path.
#
mono_bash_files="mono/arch/arm/dpiops.sh mono/arch/arm/fpaops.sh
mono/arch/arm/vfpops.sh mono/tests/make_imt_test.sh
scripts/mono-find-provides.in scripts/mono-find-requires.in
scripts/mono-test-install web/mono-build-w32.sh
mcs/class/Mono.WebBrowser/build-csproj2k5
mcs/class/Managed.Windows.Forms/build-csproj
mcs/class/Managed.Windows.Forms/build-csproj2k5
mcs/class/Mono.Cairo/Samples/gtk/compile.sh
mcs/class/Mono.Cairo/Samples/png/compile.sh
mcs/class/Mono.Cairo/Samples/win32/compile.sh
mcs/class/Mono.Cairo/Samples/x11/compile.sh mcs/tools/tinderbox/tinderbox.sh"

. $XBPS_TMPLHELPDIR/replace-interpreter.sh

for f in ${mono_bash_files}; do
	replace_interpreter bash $f
done

for f in ${mono_perl_files}; do
	replace_interpreter perl $f
done
