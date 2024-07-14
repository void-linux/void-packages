To use the Unity greeter, change these values in /etc/lightdm/lightdm.conf:
[LightDM]
dbus-service=true
[Seat:*]
greeter-session=unity-greeter

Make sure to symlink your wallpaper (or any image) to:
/usr/share/backgrounds/warty-final-ubuntu.png
