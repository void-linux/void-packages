#!/bin/sh

exec_mess() {
  /usr/share/mame/mess \
    -artpath "$HOME/.mess/artwork;artwork" \
    -ctrlrpath "$HOME/.mess/ctrlr;ctrlr" \
    -inipath $HOME/.mess/ini \
    -rompath $HOME/.mess/roms \
    -samplepath "$HOME/.mess/samples;samples" \
    -cfg_directory $HOME/.mess/cfg \
    -comment_directory $HOME/.mess/comments \
    -diff_directory $HOME/.mess/diff \
    -input_directory $HOME/.mess/inp \
    -nvram_directory $HOME/.mess/nvram \
    -snapshot_directory $HOME/.mess/snap \
    -state_directory $HOME/.mess/sta \
    -video opengl \
    -createconfig
}

if [ "$1" = "--newini" ]; then
  echo "Rebuilding the ini file at $HOME/.mess/mame.ini"
  echo "Modify this file for permanent changes to your MESS"
  echo "options and paths before running MESS again."
  cd $HOME/.mess
  if [ -e mame.ini ]; then
    echo "Your old ini file has been renamed to mame.ini.bak"
    mv mame.ini mame.ini.bak
  fi
  exec_mess
elif [ ! -e $HOME/.mess ]; then
  echo "Running MESS for the first time..."
  echo "Creating an ini file for MESS at $HOME/.mess/mame.ini"
  echo "Modify this file for permanent changes to your MAME"
  echo "options and paths before running MAME again."
  mkdir $HOME/.mess
  for f in artwork cfg comments ctrlr diff ini ip nvram \
	  samples snap sta roms; do
  	mkdir $HOME/.mess/${f}
  done
  cd $HOME/.mess && exec_mess
else
  cd /usr/share/mame
  ./mame "$@"
fi
