Install the "latest" HP48 GX ROM to make the calculator usable:

mkdir ~/.hp48
curl -L http://downloads.sourceforge.net/project/x48.berlios/gxrom-r.bz2 | bunzip2 > ~/.hp48/rom
x48 -rom ~/.hp48/rom

