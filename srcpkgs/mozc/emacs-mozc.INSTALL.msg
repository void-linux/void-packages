To enable Mozc mode, add this to your ~/.emacs.d/init.el file:

(set-language-environment "Japanese")
(require 'mozc)  ; or (load-file "/path/to/mozc.el")
(setq default-input-method "japanese-mozc")

C-\ is bound to `toggle-input-method' by default.
