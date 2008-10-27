#
# Perl files with hardcoded shebang path.
#
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

unset mono_perl_files mono_bash_files

#
# Fix up wrong pkg-config prefix vars.
#
mono_pc_files="data/cecil.pc.in data/dotnet.pc.in
 data/dotnet35.pc.in data/mint.pc.in data/mono-cairo.pc.in
 data/mono.pc.in data/smcs.pc.in scripts/mono-nunit.pc.in"

for f in ${mono_pc_files}; do
	$sed_cmd -e "s|\${pcfiledir}/../..|$XBPS_MASTERDIR|g"	\
		$wrksrc/$f > $wrksrc/$f.sed &&  \
		$mv_cmd $wrksrc/$f.sed $wrksrc/$f
done

unset mono_pc_files

#
# Fix up hardcoded default path in mcs.
#
$sed_cmd -e "s|/usr/local|$XBPS_MASTERDIR|g"	\
	$wrksrc/mcs/build/config-default.make >	\
	$wrksrc/mcs/build/config-default.make.in &&	\
	$mv_cmd $wrksrc/mcs/build/config-default.make.in \
		$wrksrc/mcs/build/config-default.make
