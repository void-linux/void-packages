export NIX_USER_PROFILE_DIR=/nix/var/nix/profiles/per-user/$USER

mkdir -m 0755 -p $NIX_USER_PROFILE_DIR
if test "$(stat --printf '%u' $NIX_USER_PROFILE_DIR)" != "$(id -u)"; then
	echo "WARNING: bad ownership on $NIX_USER_PROFILE_DIR" >&2
fi

if ! test -L $HOME/.nix-profile; then
	echo "creating $HOME/.nix-profile" >&2
	if test "$USER" != root; then
		ln -s $NIX_USER_PROFILE_DIR/profile $HOME/.nix-profile
	else
		# Root installs in the system-wide profile by default.
		ln -s /nix/var/nix/profiles/default $HOME/.nix-profile
	fi
fi

export PATH=/nix/var/nix/profiles/default/bin:$PATH
export PATH=$HOME/.nix-profile/bin:$PATH

if [ "$USER" = root -a ! -e $HOME/.nix-channels ]; then
	echo "http://nixos.org/channels/nixpkgs-unstable nixpkgs" \
		> $HOME/.nix-channels
fi

NIX_USER_GCROOTS_DIR=/nix/var/nix/gcroots/per-user/$USER
mkdir -m 0755 -p $NIX_USER_GCROOTS_DIR
if test "$(stat --printf '%u' $NIX_USER_GCROOTS_DIR)" != "$(id -u)"; then
	echo "WARNING: bad ownership on $NIX_USER_GCROOTS_DIR" >&2
fi

if [ ! -e $HOME/.nix-defexpr -o -L $HOME/.nix-defexpr ]; then
	echo "creating $HOME/.nix-defexpr" >&2
	rm -f $HOME/.nix-defexpr
	mkdir $HOME/.nix-defexpr
	if [ "$USER" != root ]; then
		ln -s /nix/var/nix/profiles/per-user/root/channels \
			$HOME/.nix-defexpr/channels_root
	fi
fi
