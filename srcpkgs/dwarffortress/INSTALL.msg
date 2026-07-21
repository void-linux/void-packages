Dwarf Fortress stores user data in:
  ~/.local/share/dwarffortress/       (symlinks and runtime)
  ~/.local/share/Bay 12 Games/Dwarf Fortress/  (saves, mods)

To reset the runtime directory after a package update:
  rm -rf ~/.local/share/dwarffortress

If upgrading from version 51.x, old saves were stored in:
  ~/.local/share/dwarffortress/data/save/
