If you encounter the following error:
  adb: error: cannot stat '/usr/bin/scrcpy-server.jar': No such file or directory
  ERROR: "adb push" returned with value 1

Execute "export SCRCPY_SERVER_PATH=/usr/share/scrcpy/scrcpy-server-v1.9.jar"
before executing scrcpy, or add it in your ~/.bashrc file.
