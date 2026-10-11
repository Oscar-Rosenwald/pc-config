(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(go-ts-indent-offset 4 nil nil "Customized with use-package go-ts-mode")
 '(package-selected-packages
   '(ace-isearch ace-jump-mode all auto-complete bash-completion company
				 diff-hl evil-visual-mark-mode expand-region
				 flycheck-mode fountain-mode go-eldoc hide-lines
				 highlight-indent-guides hl-todo impatient-mode lsp-ui
				 magit mermaid-ts-mode minions multiple-cursors
				 nix-ts-mode nushell-ts-mode olivetti org-contrib
				 org-roam org-transclusion orgalist ox-gfm ox-typst
				 paredit protobuf-ts-mode rotate selectrum-prescient
				 swiper transpose-frame undo-tree yasnippet)))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(require 'package)
(require 'org)
;;(toggle-debug-on-error)
(org-babel-load-file (expand-file-name "~/pc-config/emacs/emacs-settings.org"))
