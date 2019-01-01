===== ibus-libpinyin Post-Install Message

In order to use the ibus input method in various apps (GTK, Qt, and X11), you
will need to add the following lines to your bashrc or equivalent files.

請記得將 .bashrc 或 .profile 檔案中加入：

	export GTK_IM_MODULE=ibus
	export QT_IM_MODULE=ibus
	export XMODIFIERS="@im=ibus"

And when you start ibus, you will need to add the following options:
另外、請在啟動 ibus-daemon 時使用底下選項使 X11 程式能夠使用中文輸入：

	ibus-daemon --daemonize --replace --xim

This should allow Chinese character input in terminal as well as other
applications running in X11/GTK/Qt.

=====
