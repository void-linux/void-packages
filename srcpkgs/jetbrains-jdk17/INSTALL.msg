JDK17 is not yet fully supported by JetBrains' tooling, although existing evidence is that JDK17 is in general more performant.

It is necessary to add the following to the vmoptions file for any of the JetBrains' IDEs you use in order for the IDE to start:
	--illegal-access=warn
	-Dsun.java2d.metal=true
	--add-opens=java.desktop/java.awt.event=ALL-UNNAMED
	--add-opens=java.desktop/sun.font=ALL-UNNAMED
	--add-opens=java.desktop/java.awt=ALL-UNNAMED
	--add-opens=java.desktop/sun.awt=ALL-UNNAMED
	--add-opens=java.base/java.lang=ALL-UNNAMED
	--add-opens=java.base/java.util=ALL-UNNAMED
	--add-opens=java.desktop/javax.swing=ALL-UNNAMED
	--add-opens=java.desktop/sun.swing=ALL-UNNAMED
	--add-opens=java.desktop/javax.swing.plaf.basic=ALL-UNNAMED
	--add-opens=java.desktop/java.awt.peer=ALL-UNNAMED
	--add-opens=java.desktop/javax.swing.text.html=ALL-UNNAMED
	--add-exports=java.desktop/sun.font=ALL-UNNAMED

Details found at https://mustafaakin.dev/posts/2021-12-08-running-intellij-idea-with-jdk17-for-better-render-performance/
