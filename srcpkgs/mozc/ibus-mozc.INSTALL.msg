ibus-mozc always starts up in Direct Input mode. If you prefer Hiragana
mode by default, set the IBUS_MOZC_DEFAULT_HIRAGANA environment variable
for ibus-daemon, e.g.:

IBUS_MOZC_DEFAULT_HIRAGANA= ibus-daemon --xim -d

This is a Void Linux extension.
