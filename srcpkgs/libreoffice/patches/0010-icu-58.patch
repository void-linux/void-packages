Minimal exceprt from upstream fix only to unbreak build

https://cgit.freedesktop.org/libreoffice/core/commit/?id=3e42714c76b1347babfdea0564009d8d82a83af4

--- i18npool/source/breakiterator/breakiterator_unicode.cxx.orig	2016-05-04 21:28:24 UTC
+++ i18npool/source/breakiterator/breakiterator_unicode.cxx
@@ -64,10 +64,13 @@ BreakIterator_Unicode::~BreakIterator_Un
 class OOoRuleBasedBreakIterator : public RuleBasedBreakIterator
 {
     public:
+#if (U_ICU_VERSION_MAJOR_NUM < 58)
+    // RuleBasedBreakIterator::setBreakType() is private as of ICU 58.
     inline void publicSetBreakType(int32_t type)
         {
             setBreakType(type);
         };
+#endif
     OOoRuleBasedBreakIterator(UDataMemory* image,
                               UErrorCode &status)
         : RuleBasedBreakIterator(image, status)
@@ -143,12 +146,21 @@ void SAL_CALL BreakIterator_Unicode::loa
                 }
             }
             if (rbi) {
+#if (U_ICU_VERSION_MAJOR_NUM < 58)
+                // ICU 58 made RuleBasedBreakIterator::setBreakType() private
+                // instead of protected, so the old workaround of
+                // https://ssl.icu-project.org/trac/ticket/5498
+                // doesn't work anymore. However, they also claim to have fixed
+                // the cause that an initial fBreakType==-1 would lead to an
+                // endless loop under some circumstances.
+                // Let's see ...
                 switch (rBreakType) {
                     case LOAD_CHARACTER_BREAKITERATOR: rbi->publicSetBreakType(UBRK_CHARACTER); break;
                     case LOAD_WORD_BREAKITERATOR: rbi->publicSetBreakType(UBRK_WORD); break;
                     case LOAD_SENTENCE_BREAKITERATOR: rbi->publicSetBreakType(UBRK_SENTENCE); break;
                     case LOAD_LINE_BREAKITERATOR: rbi->publicSetBreakType(UBRK_LINE); break;
                 }
+#endif
                 icuBI->aBreakIterator = rbi;
             }
         }
