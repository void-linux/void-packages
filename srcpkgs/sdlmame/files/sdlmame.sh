#!/bin/sh

exec_mame() {
  /usr/share/sdlmame/sdlmame \
    -artpath "$HOME/.mame/artwork;artwork" \
    -ctrlrpath "$HOME/.mame/ctrlr;ctrlr" \
    -inipath $HOME/.mame/ini \
    -rompath $HOME/.mame/roms \
    -samplepath $HOME/.mame/samples \
    -cfg_directory $HOME/.mame/cfg \
    -comment_directory $HOME/.mame/comments \
    -diff_directory $HOME/.mame/diff \
    -input_directory $HOME/.mame/inp \
    -memcard_directory $HOME/.mame/memcard \
    -nvram_directory $HOME/.mame/nvram \
    -snapshot_directory $HOME/.mame/snap \
    -state_directory $HOME/.mame/sta \
    -video opengl \
    -createconfig
}

if [ "$1" = "--newini" ]; then
  echo "Rebuilding the ini file at $HOME/.mame/sdlmame.ini"
  echo "Modify this file for permanent changes to your SDLMAME"
  echo "options and paths before running SDLMAME again."
  cd $HOME/.mame
  if [ -e sdlmame.ini ]; then
    echo "Your old ini file has been renamed to sdlmameini.bak"
    mv sdlmame.ini sdlmameini.bak
  fi
  exec_mame
elif [ ! -e $HOME/.mame ]; then
  echo "Running SDLMAME for the first time..."
  echo "Creating an ini file for SDLMAME at $HOME/.mame/sdlmame.ini"
  echo "Modify this file for permanent changes to your SDLMAME"
  echo "options and paths before running SDLMAME again."
  mkdir $HOME/.mame
  for f in artwork cfg comments ctrlr diff ini ip memcard nvram \
	  samples snap sta roms; do
  	mkdir $HOME/.mame/${f}
  done
  cd $HOME/.mame && exec_mame
else
  cd /usr/share/sdlmame
  ./sdlmame "$@"
fi
