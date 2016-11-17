#
# Useful variables for determining Python version and paths.
#
__python2="/usr/bin/python2"
__python3="/usr/bin/python3"

# set version 2 as the default Python
python_version="2"

if [ -x ${__python2} ]; then
  py2_ver="$(${__python2} -c 'import sys; print(sys.version[:3])')"
  py2_lib="$(${__python2} -c 'from distutils.sysconfig import get_python_lib; print(get_python_lib(0, 1))')"
  py2_sitelib="$(${__python2} -c 'from distutils.sysconfig import get_python_lib; print(get_python_lib())')"
  py2_inc="$(${__python2} -c 'from distutils.sysconfig import get_python_inc; print(get_python_inc())')"
fi
if [ -x ${__python3} ]; then
  py3_ver="$(${__python3} -c 'import sys; print(sys.version[:3])')"
  py3_lib="$(${__python3} -c 'from distutils.sysconfig import get_python_lib; print(get_python_lib(0, 1))')"
  py3_sitelib="$(${__python3} -c 'from distutils.sysconfig import get_python_lib; print(get_python_lib())')"
  py3_inc="$(${__python3} -c 'from distutils.sysconfig import get_python_inc; print(get_python_inc())')"
fi
