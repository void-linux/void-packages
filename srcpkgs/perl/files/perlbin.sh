# Set path to perl scripts.

# Add dirs to path if they exist.
for _dir_ in site vendor core; do
	if [ -d /usr/lib/perl5/${_dir_}_perl/bin ]; then
		PATH=$PATH:/usr/lib/perl5/${_dir_}_perl/bin
	fi
done
export PATH

# If you have modules in non-standard directories you can add them here.
#export PERLLIB=dir1:dir2

