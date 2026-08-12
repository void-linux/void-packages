Niri requires a GBM interface (dri_gbm.so).
A missing GBM interface will result in missing libraries (dri_gbm.so).
It can be provided by several different packages,
but xbps cannot express this type of optional dependency.
Be sure to have one of the following installed;
- the proprietary Nvidia drivers (nonfree), `nvidia`.
- the `mesa-dri` package.
