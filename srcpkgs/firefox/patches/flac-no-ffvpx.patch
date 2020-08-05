Enable FLAC on platforms without ffvpx like powerpc*

diff --git dom/media/flac/FlacDecoder.cpp dom/media/flac/FlacDecoder.cpp
index 53fc3c9937f7..b23771ab80fa 100644
--- dom/media/flac/FlacDecoder.cpp
+++ dom/media/flac/FlacDecoder.cpp
@@ -7,6 +7,7 @@
 #include "FlacDecoder.h"
 #include "MediaContainerType.h"
 #include "mozilla/StaticPrefs_media.h"
+#include "PDMFactory.h"
 
 namespace mozilla {
 
@@ -14,6 +15,11 @@ namespace mozilla {
 bool FlacDecoder::IsEnabled() {
 #ifdef MOZ_FFVPX
   return StaticPrefs::media_flac_enabled();
+#elif defined(MOZ_FFMPEG)
+  RefPtr<PDMFactory> platform = new PDMFactory();
+  return StaticPrefs::media_flac_enabled() &&
+         platform->SupportsMimeType(NS_LITERAL_CSTRING("audio/flac"),
+                                    /* DecoderDoctorDiagnostics* */ nullptr);
 #else
   // Until bug 1295886 is fixed.
   return false;
