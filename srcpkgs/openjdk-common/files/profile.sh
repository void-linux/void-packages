# only modify the environment if an openjdk*-jre package is installed
if [ -e "/usr/lib/jvm/default-jre" ]; then
	# if an openjdk* package is installed, prefer it to the selected jre
	if [ -e "/usr/lib/jvm/default-jdk" ]; then
		export JAVA_HOME="/usr/lib/jvm/default-jdk"
	else
		export JAVA_HOME="/usr/lib/jvm/default-jre"
	fi
	# append the select jdk and jre bin and man dirs to the relevant PATHs
	export PATH="$PATH:/usr/lib/jvm/default-jdk/bin:/usr/lib/jvm/default-jre/bin"
	export MANPATH="$MANPATH:/usr/lib/jvm/default-jdk/man:/usr/lib/jvm/default-jre/man"
fi
