By default, this package supports only non-interactive graphics output.
For interactive graphics, install:

- pygtk python-cairocffi (for GTK/GTKAgg/GTKCairo backend)
- gtk+3 gir-freedesktop python-gobject python-cairocffi
  (for GTK3Agg/GTK3Cairo backend)
- python-PyQt5 (for Qt5Agg backend)
- python-tkinter (for TkAgg backend)
- python-tornado (for webagg backend)
- python-wxPython (for WX/WXAgg backend)

To change the backend, you have two ways:

- /etc/matplotlibrc (system-wide)
- $HOME/.config/matplotlib/matplotlibrc (per-user basis)

Natively, matplotlib only supports PNG images. Install python-Pillow
to support more file formats.

Matplotlib’s LaTeX support requires a working LaTeX installation and
ghostscript.
