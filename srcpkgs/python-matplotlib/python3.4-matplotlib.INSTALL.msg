This is the base package which supports only non-GUI and non-interactive
graphics output. For interactive graphics install one of the following
packages:

  - python3.4-matplotlib-gtk3 (for GTK3Agg/GTK3Cairo backend)
  - python3.4-matplotlib-qt4 (for Qt4Agg backend)
  - python3.4-matplotlib-qt5 (for Qt5Agg backend)
  - python3.4-matplotlib-tk (for TkAgg backend)
  - python3.4-matplotlib-web (for webagg backend)

To change the backend, you have two ways:

  - /etc/matplotlibrc (system-wide)
  - $HOME/.config/matplotlib/matplotlibrc (per-user basis)

Natively, matplotlib only supports PNG images. Install python3.4-Pillow
to support more file formats.

Matplotlib’s LaTeX support requires a working LaTeX installation and
ghostscript.
