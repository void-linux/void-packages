Please read /usr/share/doc/imagescan-plugin-networkscan/README

CRITICAL: The documentation all mention the use of:

    /etc/imagescan/imagescan.conf

But this is incorrect. The correct path is:

    /etc/utsushi/utsushi.conf

The discrepancy stems from the difference in use of software
provided from EPSON(TM) verses the downstream open-source
project.

An example of a working configuration is:
```
[devices]

net.udi    = networkscan:esci://192.168.1.98:1865
net.vendor = Epson
net.model  = ET-2760
net.name   = Epson Network Scanner
```

