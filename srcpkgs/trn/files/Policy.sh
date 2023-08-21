#!/bin/sh
#
#  This file was produced by running the Policy_sh.SH script, which
#  gets its values from config.sh, which is generally produced by
#  running Configure.
# 
# login name of the person who configured trn (not particularly interesting).
cf_by='chris'
# time of configuration (not particularly interesting).
cf_time='Sat Jul 12 18:45:04 CEST 2014'

#		install directives.

#	The base of all our install directives
prefix='/usr'
#		bin directories (string values)
#	name of the final resting place
bin='/usr/bin'
#	how to get to the final resting place (thank you, AFS)
installbin='/usr/bin'

#		private libraries
#	name of the final resting place for those items in the library
#	directory (string value)
privlib='/usr/lib/trn'
#	How to get to the library final resting place (thanks, AFS)
installprivlib='/usr/lib/trn'

#	interesting questions about man
# 	where do man page sources go?
mansrc='/usr/share/man/man1'
#	what extention do man pages get?
manext='1'

#		path to assorted programs that we might want to override.
#	name of the default editor.  (string value)
defeditor='/usr/bin/vi'
#	prefered user shell (string value)
prefshell='/bin/sh'
#	favorite local pager (string value)
pager='/usr/bin/less'
# where is inews?  (string value)
d_inews='define'
installinews='/usr/bin'
useinews='/usr/bin/inews'
extrainews=''
#	path to interactive speller or "none" (string value)
ispell_prg='none'
#	spelling options for ispell_prg or "spell" if "none" (string value)
ispell_options=''

#		internal options
#	ignore the ORGANIZATION environment variable? (define/undef)
d_ignoreorg='undef'
#	does the mailer understand FQDN addressing? (define/undef)
d_internet='define'
#	do you have a news admin? (define/undef)
d_newsadm='undef'
#	name of the news admin? (string value)
newsadmin='root'
#	read via NNTP? (define/undef)
d_nntp='define'
#	use the XDATA NNTP extension? (define/undef)
d_xdata=''
#	path to a file containing a server name, or a hostname (string value)
servername='no default'

#	distribution names (string values)
# local city
citydist='none'
# "local" country
cntrydist='none'
# "local" continent
contdist='none'
# site distribution
locdist='none'
# organizational distribution
orgdist='none'
# state/province distribution name
statedist='none'
# multistate region distribution name
multistatedist='none'

#		Naming information.
#	password file contains names (define/undef)
d_passnames='define'
#	berkeley style password entries (name first in GCOS) (define/undef)
d_berknames='define'
#	USG style password entries (account number first in GCOS)
#	(define/undef)
d_usgnames='undef'
#	what type of name to use.. (bsd/usg/other)
nametype='bsd'

#	How portable do we want to be? Determines if we do lookups now
#	or wait until run time.  (define/undef)
d_portable='undef'

#		news library information
#	where is the news library (usually /usr/lib/news) may contain ~<usrname>
newslib='/tmp'
#	absolute path name to /usr/lib/news.
newslibexp='/tmp'
#	where is the news spool (usually /{var,usr}/spool/news)
newsspool='none'
#	active file stuff, like where is it, what is its name, etc
#	path to the active file. (string value)
active='remote'
#	do we have an active.times file? (define/undef)
d_acttimes='define'
#	path to the active.times file. (string value)
acttimes='remote'
#	organizations name. path to file, or constant string
orgname='/etc/organization'

#	only one of the two following is needed
#	command to find the posting hosts name (string value, optional)
phostcmd='hostname'
#	file containing posting hosts name or constant string
#				(string value, optional)
#
phost='.'

#	what should we use? mthreads or overview
#	use the mthreads format? (define/undef)
d_usemt=''
#	where do we find the thread files? (string value)
threaddir='remote'
#	use the overview format? (define/undef)
d_useov=''
#	where do we find the .overview fils? (string value)
overviewdir='remote'

#	trn start up options
trn_init='FALSE'
#	start up with the selector? 
trn_select='TRUE'

# Added for Void Linux
hint='previous'
d_genauth='define'
cc="$CC"
ccflags="$CFLAGS -DINET6"
optimize=""
ldflags="$LDFLAGS"
mailer='/usr/bin/sendmail'
mailfile='/var/mail/%L'
mailcap='/etc/mailcap'
usenm='false'
locincpth=''
loclibpth=''
