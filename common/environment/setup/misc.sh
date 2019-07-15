#
# Common variables that can be used by xbps-src.
#
# SITE used for ditfiles mirrors. For use in $distfiles.
set -a

CPAN_SITE="https://www.cpan.org/modules/by-module"
DEBIAN_SITE="http://ftp.debian.org/debian/pool"
FREEDESKTOP_SITE="https://freedesktop.org/software"
GITHUB_SITE="https://github.com"
GNOME_SITE="http://ftp.gnome.org/pub/GNOME/sources"
GNU_SITE="http://ftp.gnu.org/gnu"
KDE_SITE="https://download.kde.org/stable"
KERNEL_SITE="https://www.kernel.org/pub/linux"
MOZILLA_SITE="https://ftp.mozilla.org/pub"
NONGNU_SITE="http://download.savannah.nongnu.org/releases"
PYPI_SITE="https://files.pythonhosted.org/packages/source"
SOURCEFORGE_SITE="http://downloads.sourceforge.net/sourceforge"
UBUNTU_SITE="http://archive.ubuntu.com/ubuntu/pool"
XORG_SITE="https://www.x.org/releases/individual"

# Repetitive sub homepage's with no real project page
# ie. some gnome and xorg projects. For use in $homepage.
XORG_HOME="http://xorg.freedesktop.org/wiki/"

set +a
