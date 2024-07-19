- To activate pcscd that is needed to manage the smart card you
  have to activate the runit service typing as root:

  # ln -s /etc/sv/pcscd /var/service/

- DRIVERS

  To use your smart card reader you have to install a USB drivers.
  Install a driver package that is named pcsc-<something> 
    
  The directory that contain the drivers is:

   /usr/lib/pcsc/drivers

- In case you have a serial port reader, you have to create the  
  directory:

  /etc/reader.conf.d

  and put in it the configuration file for your reader, see:

  https://alioth.debian.org/projects/pcsclite/

  for more details.
