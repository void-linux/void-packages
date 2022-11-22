- TeX Live is free software see the files:

  /usr/share/licenses/texlive-bin/LICENSE.TL
  /usr/share/licenses/texlive-bin/LICENSE.CTAN

=====================================================================

  This package sets the location of TeX Live binaries and manual
  pages using the file: /etc/profile.d/texlive.sh.

  see  http://www.tug.org/texlive/quickinstall.html for details 

  Check if your PATH and MANPATH are updated correctly with:

  $ printenv

  You may need to reboot to ensure that the paths are updated
  correctly, for the impatients, if you want you can type

  $ source /etc/profile

  and check PATH and MANPATH.

=====================================================================

  To update you TeX Live installation use only the program

  /opt/texlive/${VERSION}/bin/<arch>/tlmgr.

  where <arch> is:
    - X86_64-linux  ==> x86_64 architecture
    - i386-linux    ==> i386 architecture

  see:

  http://www.tug.org/texlive/doc/tlmgr.html#EXAMPLES
  
  for the details and the documentation in 
    		 		 
  WARNING: To avoid messing up your TeX Live installation, DON'T use
  the installation scripts in /opt/texlive-installer.
