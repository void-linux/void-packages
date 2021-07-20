- FOP environment configuration file is:

  /etc/fop.conf

  it is preconfigured as follow:

  FOP_OPTS="-Xmx512m"
  FOP_HOME="/usr/share/fop"

  note in FOPS_OPTS="-Xmx<your memory size>m" is preconfigured as 512 Mb
  if you want use a different amount of memory modify it according your
  needs.

  According to my limited knowledge of FOP the configuration file for
  the part that produce the documentations reside in a different file in
  XML format, see an example in:

  /usr/share/doc/fop/conf/

  For hint about this configurations see the proper page at:

  http://xmlgraphics.apache.org/fop/1.1/configuration.html

  For hints on usign fop see:

  http://wiki.apache.org/xmlgraphics-fop/FrontPage

  In this package I've included the full documentation in HTML format
  in:

  /usr/share/doc/fop/javadocs/

 =============

  You may need to reboot to ensure that PATH is update correctly,
  for the impatients, if you want you can type

  $ . /etc/profile

  and check the PATH.

 =============

  The dictionaries for the hyphenationa are available on the package:

  offo-hyphenation

  The package install it in:

  /usr/share/fop/lib

  as a jar file, see the offo-hyphenation documentation for more info.

  Some part of the code of FOP are not licensed under Apache-2.0,
  see in /usr/share/fop/lib/ for the licenses of this parts
  of code that for convenience are in the distribution of FOP.

  Happy FOPping!
