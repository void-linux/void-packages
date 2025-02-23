#!/bin/sh

exec_mame() {
  /usr/libexec/mame/mame \
    -artpath "$HOME/.mame/artwork;artwork" \
    -ctrlrpath "$HOME/.mame/ctrlr;ctrlr" \
    -inipath $HOME/.mame/ini \
    -rompath $HOME/.mame/roms \
    -samplepath "$HOME/.mame/samples;samples" \
    -cfg_directory $HOME/.mame/cfg \
    -comment_directory $HOME/.mame/comments \
    -diff_directory $HOME/.mame/diff \
    -input_directory $HOME/.mame/inp \
    -nvram_directory $HOME/.mame/nvram \
    -snapshot_directory $HOME/.mame/snap \
    -state_directory $HOME/.mame/sta \
    -video opengl \
    -createconfig
}

if [ "$1" = "--newini" ]; then
  echo "Rebuilding the ini file at $HOME/.mame/mame.ini"
  echo "Modify this file for permanent changes to your MAME"
  echo "options and paths before running MAME again."
  cd $HOME/.mame
  if [ -e mame.ini ]; then
    echo "Your old ini file has been renamed to mame.ini.bak"
    mv mame.ini mame.ini.bak
  fi
  exec_mame
elif [ ! -e $HOME/.mame ]; then
  echo "Running MAME for the first time..."
  echo "Creating an ini file for MAME at $HOME/.mame/mame.ini"
  echo "Modify this file for permanent changes to your MAME"
  echo "options and paths before running MAME again."
  mkdir $HOME/.mame
  for f in artwork cfg comments ctrlr diff ini ip nvram \
	  samples snap sta roms; do
  	mkdir $HOME/.mame/${f}
  done
  cd $HOME/.mame && exec_mame
else
  cd /usr/share/mame
  /usr/libexec/mame/mame "$@"
fi
