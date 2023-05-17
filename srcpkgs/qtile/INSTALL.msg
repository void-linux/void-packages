!!! Config breakage !!!
    - lazy.qtile.display_kb() no longer receives any arguments. If you passed
      it any arguments (which were ignored previously), remove them.
    - If you have a custom startup Python script that you use instead of
      "qtile start" and run init_log manually, the signature has changed.
      Please check the source for the updated arguments.
    - "KeyChord"'s signature has changed. "mode" is now a boolean to indicate
       whether the mode should persist. The "name" parameter should be used
       to name the chord (e.g. for the ``Chord`` widget).
