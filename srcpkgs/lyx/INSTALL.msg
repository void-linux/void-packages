  LyX the document processor need a set of TeXLive packages present
  to deploy his power.

  To check if some of theese packages are missing go to:
  menu "Help" and choose "Latex Configuration" this (long) page give
  you some help on what is missing and where to found it.
  
  If you have the installed TeXLive with the voidlinux installer, 
  by default it install the small scheme of installation, you have
  to install the missing packages, the quickiest way is to run as 
  root:

  'tlmgr install algorithm2e algorithms apacite bbding bezos bibtopic'
  'tlmgr install breakurl covington csquotes diagbox endnotes enumitem'
  'tlmgr install epstopdf esint eurosym feyn fragments framed frankenstein'
  'tlmgr install harvard hyphenat jurabib lettrine luainputenc marginnote'
  'tlmgr install mathdesign mathdots mhchem multirow nicefrac nomencl'
  'tlmgr install picinpar pict2e prettyref preview rotfloat rsfs shapepar'
  'tlmgr install sidecap splitindex symbol tex-gyre ulem units wasy wasysym'
  'tlmgr install wrapfig xargs'


   As there are many flavour of your preferred applications, I didn't
   force you to use any in particular so you must have at least:
   a text editor, a PS and/or PDF viewer, an internet browser.

   If LyX appear on your screen a looking in the file:
      '~/.lyx/configure.log'
   may give you an idea of what is supported by LyX.

   Happy LyXing

   The Void Linux maintainers		 
