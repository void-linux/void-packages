
              ATTENTION, ACHTUNG, ATENCION

There are currently problems with the update process if the sh alternative is
not set to dash.

To find out what the current sh alternative is:

	xbps-alternatives -l -g sh

To set the sh alternative to dash:
	
	xbps-alternatives -g sh -s dash
