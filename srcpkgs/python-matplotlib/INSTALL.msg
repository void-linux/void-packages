This is the base package which supports only non-GUI and non-interactive
graphics output. For interactive graphics install one of the following
packages:

  - python-matplotlib-gtk (for GTK/GTKAgg/GTKCairo backend)
  - python-matplotlib-gtk3 (for GTK3Agg/GTK3Cairo backend)
  - python-matplotlib-qt4 (for Qt4Agg backend)
  - python-matplotlib-qt5 (for Qt5Agg backend)
  - python-matplotlib-tk (for TkAgg backend)
  - python-matplotlib-web (for webagg backend)
  - python-matplotlib-wx (for WX/WXAgg backend)

To change the backend, you have two ways:

  - /etc/matplotlibrc (system-wide)
  - $HOME/.config/matplotlib/matplotlibrc (per-user basis)

Natively, matplotlib only supports PNG images. Install python-Pillow
to support more file formats.

Matplotlib’s LaTeX support requires a working LaTeX installation and
ghostscript.
