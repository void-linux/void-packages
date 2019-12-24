From c8b862b491cfbbb4f79b24d7cd90e4fb1f37cb9f Mon Sep 17 00:00:00 2001
From: Diego Escalante Urrelo <diegoe@gnome.org>
Date: Fri, 25 Oct 2019 04:49:15 -0500
Subject: [PATCH] WIP: build: Fix link_whole usage for meson 0.52.0

Meson 0.52.0 changed how link_whole behaves and in doing so broke our
usage of link_whole internally.

A quick glance over mesonbuild/backend/ninjabackend.py seems to confirm
Christian's suspicion that link_with is what we want for internal use,
and link_whole for the final binary.

You can see some more references to this and similar issues in the
following jhbuild commit:
https://gitlab.gnome.org/GNOME/jhbuild/commit/dbe679045ff5982577f22e7af8dc8fdfbd1c6311

Fixes: https://gitlab.gnome.org/GNOME/gnome-builder/issues/1057
---
 src/libide/code/meson.build       |  2 +-
 src/libide/core/meson.build       |  2 +-
 src/libide/debugger/meson.build   |  2 +-
 src/libide/editor/meson.build     |  2 +-
 src/libide/foundry/meson.build    |  2 +-
 src/libide/greeter/meson.build    |  2 +-
 src/libide/gui/meson.build        |  2 +-
 src/libide/io/meson.build         |  2 +-
 src/libide/lsp/meson.build        |  2 +-
 src/libide/plugins/meson.build    |  2 +-
 src/libide/projects/meson.build   |  2 +-
 src/libide/search/meson.build     |  2 +-
 src/libide/sourceview/meson.build |  2 +-
 src/libide/terminal/meson.build   |  2 +-
 src/libide/themes/meson.build     |  2 +-
 src/libide/threading/meson.build  |  2 +-
 src/libide/tree/meson.build       |  2 +-
 src/libide/vcs/meson.build        |  2 +-
 src/libide/webkit/meson.build     |  2 +-
 src/meson.build                   | 26 +++++++++++++++++++++++++-
 20 files changed, 44 insertions(+), 20 deletions(-)

diff --git a/src/libide/code/meson.build b/src/libide/code/meson.build
index ddacdc162..1a4fc5d26 100644
--- a/src/libide/code/meson.build
+++ b/src/libide/code/meson.build
@@ -175,7 +175,7 @@ libide_code = static_library('ide-code-' + libide_api_version,
 libide_code_dep = declare_dependency(
               sources: libide_code_private_headers + libide_code_generated_headers,
          dependencies: libide_code_deps,
-           link_whole: libide_code,
+            link_with: libide_code,
   include_directories: include_directories('.'),
 )
 
diff --git a/src/libide/core/meson.build b/src/libide/core/meson.build
index 1fa82fad9..bb75cbf26 100644
--- a/src/libide/core/meson.build
+++ b/src/libide/core/meson.build
@@ -117,7 +117,7 @@ libide_core = static_library('ide-core-' + libide_api_version, libide_core_sourc
 libide_core_dep = declare_dependency(
               sources: libide_core_private_headers + libide_core_generated_headers,
          dependencies: libide_core_deps,
-           link_whole: libide_core,
+            link_with: libide_core,
   include_directories: include_directories('.'),
 )
 
diff --git a/src/libide/debugger/meson.build b/src/libide/debugger/meson.build
index dffca20ca..b5e72d5c0 100644
--- a/src/libide/debugger/meson.build
+++ b/src/libide/debugger/meson.build
@@ -84,7 +84,7 @@ libide_debugger = static_library('ide-debugger-' + libide_api_version,
 libide_debugger_dep = declare_dependency(
               sources: libide_debugger_private_headers + libide_debugger_generated_headers,
          dependencies: libide_debugger_deps,
-           link_whole: libide_debugger,
+            link_with: libide_debugger,
   include_directories: include_directories('.'),
 )
 
diff --git a/src/libide/editor/meson.build b/src/libide/editor/meson.build
index 2838425b7..808ed784f 100644
--- a/src/libide/editor/meson.build
+++ b/src/libide/editor/meson.build
@@ -107,7 +107,7 @@ libide_editor = static_library('ide-editor-' + libide_api_version, libide_editor
 
 libide_editor_dep = declare_dependency(
          dependencies: libide_editor_deps,
-           link_whole: libide_editor,
+            link_with: libide_editor,
   include_directories: include_directories('.'),
               sources: libide_editor_generated_headers,
 )
diff --git a/src/libide/foundry/meson.build b/src/libide/foundry/meson.build
index 226397c15..d4878aa11 100644
--- a/src/libide/foundry/meson.build
+++ b/src/libide/foundry/meson.build
@@ -178,7 +178,7 @@ libide_foundry = static_library('ide-foundry-' + libide_api_version,
 
 libide_foundry_dep = declare_dependency(
          dependencies: libide_foundry_deps,
-           link_whole: libide_foundry,
+            link_with: libide_foundry,
   include_directories: include_directories('.'),
               sources: libide_foundry_generated_headers,
 )
diff --git a/src/libide/greeter/meson.build b/src/libide/greeter/meson.build
index 3968ca41e..121d498d0 100644
--- a/src/libide/greeter/meson.build
+++ b/src/libide/greeter/meson.build
@@ -83,7 +83,7 @@ libide_greeter = static_library('ide-greeter-' + libide_api_version,
 libide_greeter_dep = declare_dependency(
               sources: libide_greeter_private_headers + libide_greeter_generated_headers,
          dependencies: libide_greeter_deps,
-           link_whole: libide_greeter,
+            link_with: libide_greeter,
   include_directories: include_directories('.'),
 )
 
diff --git a/src/libide/gui/meson.build b/src/libide/gui/meson.build
index 9f469d2fa..94311282f 100644
--- a/src/libide/gui/meson.build
+++ b/src/libide/gui/meson.build
@@ -204,7 +204,7 @@ libide_gui = static_library('ide-gui-' + libide_api_version, libide_gui_sources,
 libide_gui_dep = declare_dependency(
               sources: libide_gui_private_headers + libide_gui_generated_headers,
          dependencies: libide_gui_deps,
-           link_whole: libide_gui,
+            link_with: libide_gui,
   include_directories: include_directories('.'),
 )
 
diff --git a/src/libide/io/meson.build b/src/libide/io/meson.build
index b5b6f4c68..f48b3bd8d 100644
--- a/src/libide/io/meson.build
+++ b/src/libide/io/meson.build
@@ -63,7 +63,7 @@ libide_io = static_library('ide-io-' + libide_api_version, libide_io_sources,
 
 libide_io_dep = declare_dependency(
          dependencies: [ libgio_dep, libide_core_dep, libide_threading_dep ],
-           link_whole: libide_io,
+            link_with: libide_io,
   include_directories: include_directories('.'),
 )
 
diff --git a/src/libide/lsp/meson.build b/src/libide/lsp/meson.build
index 23aba74fa..c8140ca03 100644
--- a/src/libide/lsp/meson.build
+++ b/src/libide/lsp/meson.build
@@ -84,7 +84,7 @@ libide_lsp = static_library('ide-lsp-' + libide_api_version, libide_lsp_sources,
 libide_lsp_dep = declare_dependency(
               sources: libide_lsp_private_headers,
          dependencies: libide_lsp_deps,
-           link_whole: libide_lsp,
+            link_with: libide_lsp,
   include_directories: include_directories('.'),
 )
 
diff --git a/src/libide/plugins/meson.build b/src/libide/plugins/meson.build
index a33c528c9..fff599db3 100644
--- a/src/libide/plugins/meson.build
+++ b/src/libide/plugins/meson.build
@@ -51,7 +51,7 @@ libide_plugins = static_library('ide-plugins-' + libide_api_version,
 libide_plugins_dep = declare_dependency(
               sources: libide_plugins_private_headers,
          dependencies: libide_plugins_deps,
-           link_whole: libide_plugins,
+            link_with: libide_plugins,
   include_directories: include_directories('.'),
 )
 
diff --git a/src/libide/projects/meson.build b/src/libide/projects/meson.build
index 463ff06bc..3cc9725c6 100644
--- a/src/libide/projects/meson.build
+++ b/src/libide/projects/meson.build
@@ -79,7 +79,7 @@ libide_projects = static_library('ide-projects-' + libide_api_version, libide_pr
 libide_projects_dep = declare_dependency(
               sources: libide_projects_private_headers,
          dependencies: libide_projects_deps,
-           link_whole: libide_projects,
+            link_with: libide_projects,
   include_directories: include_directories('.'),
 )
 
diff --git a/src/libide/search/meson.build b/src/libide/search/meson.build
index e5b3b43ab..cf73aa91d 100644
--- a/src/libide/search/meson.build
+++ b/src/libide/search/meson.build
@@ -51,7 +51,7 @@ libide_search = static_library('ide-search-' + libide_api_version, libide_search
 
 libide_search_dep = declare_dependency(
          dependencies: libide_search_deps,
-           link_whole: libide_search,
+            link_with: libide_search,
   include_directories: include_directories('.'),
 )
 
diff --git a/src/libide/sourceview/meson.build b/src/libide/sourceview/meson.build
index c4ba12d1f..99641298b 100644
--- a/src/libide/sourceview/meson.build
+++ b/src/libide/sourceview/meson.build
@@ -158,7 +158,7 @@ libide_sourceview = static_library('ide-sourceview-' + libide_api_version,
 libide_sourceview_dep = declare_dependency(
               sources: libide_sourceview_private_headers + libide_sourceview_generated_headers,
          dependencies: libide_sourceview_deps,
-           link_whole: libide_sourceview,
+            link_with: libide_sourceview,
   include_directories: include_directories('.'),
 )
 
diff --git a/src/libide/terminal/meson.build b/src/libide/terminal/meson.build
index 1d7c9f727..6affcae14 100644
--- a/src/libide/terminal/meson.build
+++ b/src/libide/terminal/meson.build
@@ -93,7 +93,7 @@ libide_terminal = static_library('ide-terminal-' + libide_api_version,
 libide_terminal_dep = declare_dependency(
               sources: libide_terminal_generated_headers,
          dependencies: libide_terminal_deps,
-           link_whole: libide_terminal,
+            link_with: libide_terminal,
   include_directories: include_directories('.'),
 )
 
diff --git a/src/libide/themes/meson.build b/src/libide/themes/meson.build
index 9d6c8e247..d883a4b86 100644
--- a/src/libide/themes/meson.build
+++ b/src/libide/themes/meson.build
@@ -46,7 +46,7 @@ libide_themes = static_library('ide-themes-' + libide_api_version,
 libide_themes_dep = declare_dependency(
               sources: libide_themes_resources[1],
          dependencies: libide_themes_deps,
-           link_whole: libide_themes,
+            link_with: libide_themes,
   include_directories: include_directories('.'),
 )
 
diff --git a/src/libide/threading/meson.build b/src/libide/threading/meson.build
index d38ddfb64..d628be2ff 100644
--- a/src/libide/threading/meson.build
+++ b/src/libide/threading/meson.build
@@ -66,7 +66,7 @@ libide_threading = static_library('ide-threading-' + libide_api_version, libide_
 libide_threading_dep = declare_dependency(
               sources: libide_threading_private_headers,
          dependencies: libide_threading_deps,
-           link_whole: libide_threading,
+            link_with: libide_threading,
   include_directories: include_directories('.'),
 )
 
diff --git a/src/libide/tree/meson.build b/src/libide/tree/meson.build
index 7b9922828..5a591106c 100644
--- a/src/libide/tree/meson.build
+++ b/src/libide/tree/meson.build
@@ -61,7 +61,7 @@ libide_tree = static_library('ide-tree-' + libide_api_version, libide_tree_sourc
 libide_tree_dep = declare_dependency(
               sources: libide_tree_private_headers,
          dependencies: libide_tree_deps,
-           link_whole: libide_tree,
+            link_with: libide_tree,
   include_directories: include_directories('.'),
 )
 
diff --git a/src/libide/vcs/meson.build b/src/libide/vcs/meson.build
index 6b0e157c4..c762afb64 100644
--- a/src/libide/vcs/meson.build
+++ b/src/libide/vcs/meson.build
@@ -84,7 +84,7 @@ libide_vcs = static_library('ide-vcs-' + libide_api_version,
 
 libide_vcs_dep = declare_dependency(
          dependencies: libide_vcs_deps,
-           link_whole: libide_vcs,
+            link_with: libide_vcs,
   include_directories: include_directories('.'),
               sources: libide_vcs_generated_headers,
 )
diff --git a/src/libide/webkit/meson.build b/src/libide/webkit/meson.build
index e1767ae46..fce477b36 100644
--- a/src/libide/webkit/meson.build
+++ b/src/libide/webkit/meson.build
@@ -39,7 +39,7 @@ libide_webkit = static_library('ide-webkit-' + libide_api_version, libide_webkit
 
 libide_webkit_dep = declare_dependency(
          dependencies: libide_webkit_deps,
-           link_whole: libide_webkit,
+            link_with: libide_webkit,
   include_directories: include_directories('.'),
               sources: libide_webkit_generated_headers,
 )
diff --git a/src/meson.build b/src/meson.build
index 3eb9ba535..113a142ad 100644
--- a/src/meson.build
+++ b/src/meson.build
@@ -48,6 +48,30 @@ gnome_builder_deps = [
   libide_tree_dep,
 ]
 
+gnome_builder_static = [
+  libide_code,
+  libide_core,
+  libide_debugger,
+  libide_editor,
+  libide_foundry,
+  libide_greeter,
+  libide_gui,
+  libide_io,
+  libide_lsp,
+  libide_plugins,
+  libide_projects,
+  libide_search,
+  libide_sourceview,
+  libide_terminal,
+  libide_themes,
+  libide_threading,
+  libide_tree,
+  libide_vcs,
+  libide_webkit,
+
+  plugins,
+]
+
 if libsysprof_capture.found()
   gnome_builder_deps += libsysprof_capture
 endif
@@ -77,7 +101,7 @@ gnome_builder = executable('gnome-builder', 'main.c', 'bug-buddy.c',
             c_args: libide_args + exe_c_args + release_args,
          link_args: exe_link_args,
                pie: true,
-        link_whole: plugins,
+        link_whole: gnome_builder_static,
      install_rpath: pkglibdir_abs,
       dependencies: gnome_builder_deps,
 )
-- 
2.24.1

