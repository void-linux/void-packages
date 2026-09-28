NB. profilex.ijs template
NB. copy template to profilex and edit as required
NB. profilex.ijs overrides profile definitions
NB. profilex.ijs is not replaced by installs/updates
NB. errors may prevent startup
NB. check SystemFolders_j_ before/after changes
NB. install is J folder
NB. home is HOME
NB. userx is /807-user or /j64-807-user
NB. see profile.ijs for more info

NB. example 1: user in J folder
NB.     user=.   install,userx

NB. example 2: user in d:/
NB.     user=.   'd:',userx

NB. example 3: user in home/Documents
NB.     user=.   home,'/Documents',userx

NB. example 4: user in same folder as install
NB.     user=.   ('/'(i:~{.])install),userx

user=.    home,userx   NB. profile default - edit to change
break=.   user,'/break'
config=.  user,'/config'
snap=.    user,'/snap'
temp=.    user,'/temp'
