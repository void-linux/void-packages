#
# Useful variables for determining Python version and paths.
#

# set version 2 as the default Python
python_version="2"

py2_ver="2.7"
py2_lib="/usr/lib/python${py2_ver}"
py2_sitelib="${py2_lib}/site-packages"
py2_inc="/usr/include/python${py2_ver}"

py3_ver="3.6"
py3_abiver="m"
py3_lib="/usr/lib/python${py3_ver}"
py3_sitelib="${py3_lib}/site-packages"
py3_inc="/usr/include/python${py3_ver}${py3_abiver}"
