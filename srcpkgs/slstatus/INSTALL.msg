To use slstatus, put the following code in your ~/.xinitrc (or similar):

  while true; do
    slstatus
  done &

The loop is needed so that the program runs after suspend to ram.
