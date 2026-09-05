NOTICE: fsearch 0.3.x configuration format changed.

The old configuration (0.2.x) used fsearch.conf in INI format.
This format is no longer valid. fsearch does NOT
automatically migrate your settings.
You must migrate your settings to the new JSON format BEFORE
launching the new version.

Before launching the new version:

  1. Backup your old config (recommended)
     mv ~/.config/fsearch/fsearch.conf \
        ~/.config/fsearch/fsearch.conf.bak 2>/dev/null

  2. Remove legacy database index
     rm -f ~/.local/share/fsearch/fsearch.db

  3. Migrate your settings to the new JSON format.
     See the mapping below for common settings.

Configuration migration (0.2.x -> 0.3.x):

Old format (fsearch.conf - INI):

  [Database]
  folders=/home/void;/media/storage;
  exclude_paths=/home/void/.cache;/tmp;
  exclude_patterns=*.tmp;*.bak;

  [Interface]
  dark_theme=true
  show_hidden_files=false

New format (fsearch.conf - JSON):

  {
    "database": {
      "indexed_locations": [
        "/home/void",
        "/media/storage"
      ],
      "excluded_locations": [
        "/home/void/.cache",
        "/tmp"
      ],
      "excluded_wildcards": [
        "*.tmp",
        "*.bak"
      ]
    },
    "ui": {
      "show_hidden_files": false
    }
  }

Once the new configuration is in place:

  1. Open FSearch.
  2. Go to Database -> Update Database (or press Ctrl+R).
  3. Ensure mounted partitions or secondary drives are listed
     under Preferences -> Database -> Included Locations.
