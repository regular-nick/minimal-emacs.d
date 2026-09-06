;;; post-init.el --- DESCRIPTION -*- no-byte-compile: t; lexical-binding: t; -*-

;; This makes sure that when this file is compiled, all bindings of use-package
;; are available.
(eval-when-compile (require 'use-package))

(setq use-package-always-ensure t)

;;; UI & APPEARANCE
;; ================

(setq inhibit-startup-message t
      visible-bell t)

(tool-bar-mode -1)
(scroll-bar-mode -1)

;; (unless (package-installed-p
(let ((inhibit-redisplay t)
      (theme 'modus-vivendi-tinted))
  ;; Disable all active themes
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme theme t))

;; Tab bar — show only when multiple tabs exist
(setopt tab-bar-show 1)

;; Mode line
(setq line-number-mode t
      column-number-mode t
      mode-line-position-column-line-format '("%l:%C")
      mode-line-compact 'long)

;; Display the time in the modeline
(setq display-time-24hr-format t)
(display-time-mode 1)

;; Line wrapping / truncation
(setq-default truncate-lines nil
              word-wrap nil)
(setq visual-line-fringe-indicators '(nil right-curly-arrow)
      line-move-visual nil)

;; Set the fringes to match the pixel height of a character. This ensures the
;; fringe is wide enough, scaling dynamically with the current font size.
(fringe-mode (frame-char-width))

;; Uncomment to replace char for wrapping to unicode arrow
;; (set-terminal-coding-system 'utf-8)
;; (set-display-table-slot standard-display-table
;;                         'wrap
;;                         (make-glyph-code ?\N{LEFTWARDS ARROW WITH HOOK}))


;; Display of line numbers in the buffer:
(setq-default display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)

(setq-default show-trailing-whitespace t)

(show-paren-mode 1)

;; Make lines dividing windows (movable with mouse). No effect on -nw.
(window-divider-mode 1)


;;; PACKAGE MANAGEMENT
;; ================

(use-package compile-angel
  :demand t
  :config
  (setq package-native-compile nil
        compile-angel-verbose nil)

  ;; Exclude init files from compilation
  (dolist (suffix '("/init.el"
                    "/early-init.el"
                    "/pre-init.el"
                    "/post-init.el"
                    "/pre-early-init.el"
                    "/post-early-init.el"
                    "/custom.el"))
    (push suffix compile-angel-excluded-path-suffixes))

  ;; Compile .el files when you save them — this is the useful part
  :hook (emacs-lisp-mode . compile-angel-on-save-local-mode)

  ;; DON'T enable this on Termux — it scans all loaded files at startup
  ;; ? Can there be a workaround?
  ;; (compile-angel-on-load-mode 1)
  )

;; This automates the process of updating installed packages
(use-package auto-package-update
  :defer 1
  :custom
  (auto-package-update-interval 30)
  ;; Suppress display of the *auto-package-update results* buffer.
  (auto-package-update-hide-results t)
  (auto-package-update-delete-old-versions t)
  ;; (auto-package-update-prompt-before-update t)

  :config
  ;; Updates automatically at startup, but only if the configured interval has
  ;; elapsed.
  (auto-package-update-maybe)

  ;; Schedule a background update attempt daily at 10:00 AM. This uses Emacs'
  ;; internal timer system.
  (auto-package-update-at-time "10:00"))


;;; SERVER AND SESSION PERSISTENCE
;; ================

(use-package server
  :ensure nil
  :if (not (daemonp))
  :preface
  (defun my/server-start ()
    "Start the Emacs server if no server process is currently active."
    (unless (server-running-p)
      (server-start)))
  :config (my/server-start))

;; Updates the contents of a buffer to reflect changes made to the underlying
;; file on disk.
(use-package autorevert
  :ensure nil
  :init
  (setq auto-revert-interval 3
        auto-revert-remote-files nil
        auto-revert-use-notify t
        auto-revert-avoid-polling nil
        ;; auto-revert-verbose t
        )
  :config
  (global-auto-revert-mode 1))

;; Preserve the minibuffer history between sessions.
(use-package savehist
  :ensure nil
  :init
  (setq history-length 300
        savehist-autosave-interval 600)
  :config
  (savehist-mode 1))

;; Enable `auto-save-mode' to prevent data loss. Use `recover-file' or
;; `recover-session' to restore unsaved changes. Trigger auto-save after 300
;; keystrokes or 30 sec of idle time.
(setq auto-save-default t
      auto-save-interval 300
      auto-save-timeout 30)

;; Direnv
(use-package direnv
  :ensure t
  :hook after-init
  ;; Super-lazy option:
  ;; :hook (find-file . (lambda () (unless direnv-mode (direnv-mode))))
  :custom
  (direnv-always-show-summary nil)
  (direnv-show-paths-in-summary nil))


;;; COMPLETION
;; ================
;; In-buffer completion popup with Corfu
(use-package corfu
  :custom
  (tab-always-indent 'complete)

  ;; Corfu behavior
  (corfu-auto t)
  (corfu-auto-prefix 2)
  (corfu-auto-delay 0.2)
  (corfu-cycle t)
  (corfu-count 10)
  (corfu-preview-current nil)
  (corfu-min-width 20)
  
  ;; Terminal-friendly: no popupinfo (needs child frames), no margins
  (corfu-popupinfo-mode nil)
  
  ;; Hide commands in M-x that don't apply to current mode
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Disable ispell completion in text modes
  (text-mode-ispell-word-completion nil)
  
  :bind (:map corfu-map
              ("TAB" . corfu-complete)
              ("RET" . corfu-insert)
              ("C-n" . corfu-next)
              ("C-p" . corfu-previous)
              ("C-s" . corfu-insert-separator))
  
  ;; :config runs AFTER the package is loaded (preserves lazy loading)
  :config
  (global-corfu-mode 1)
  ;; In terminal, popupinfo-mode won't work well (needs child frames).
  ;; If you want docs, use `corfu-doc' package instead, or just skip it.
  )

;; Completion At Point Extensions
(use-package cape
  :commands (cape-dabbrev cape-file cape-elisp-block)
  :bind ("C-c p" . cape-prefix-map)

  :init
  ;; These hooks run when modes activate — they don't load cape immediately.
  ;; The `cape-*' functions are autoloaded, so this is fine in :init.
  (defun my/cape-prog-setup ()
    (setq-local completion-at-point-functions
                (list (cape-capf-super
                       #'cape-dabbrev
                       #'cape-file
                       #'cape-keyword)
                      #'cape-elisp-block
                      t)))
  
  (defun my/cape-text-setup ()
    (setq-local completion-at-point-functions
                (list (cape-capf-super
                       #'cape-dict
                       #'cape-dabbrev
                       #'cape-emoji)
                      #'cape-file
                      t)))

  :hook ((prog-mode . my/cape-prog-setup)
         (text-mode . my/cape-text-setup))

  :config
  ;; Global defaults (low priority, applied everywhere)
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))


;; Minibuffer completion
(use-package vertico
  :bind (:map vertico-map
              ("C-j" . vertico-next)
              ("C-k" . vertico-previous)
              ("C-l" . vertico-exit)
              ("C-h" . vertico-directory-up)
              ("RET" . vertico-directory-enter)
              ("DEL" . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word)
              ("M-TAB" . minibuffer-complete))
  
  :custom
  (vertico-cycle t)
  (vertico-resize t)
  (vertico-count 10)
  
  ;; ;; Flat mode settings for terminal / small screens
  ;; (vertico-flat-format '(:multiple " { " " | " " } "
  ;;                                  :single " { " " } "
  ;;                                  :prompt " { " " } "))
  :config
  ;; Enable flat mode instead of vertical mode (saves vertical space in Termux)
  (vertico-mode 1)
  (vertico-flat-mode 1)
  
  ;; Recursive minibuffers
  (setq enable-recursive-minibuffers t)
  
  ;; Don't allow cursor in minibuffer prompt
  (setq minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt)))


;;; ============================================================================
;;; OPTIONAL COMPLEMENTS
;;; ============================================================================

;; (use-package orderless
;;   :custom
;;   (completion-styles '(orderless basic))
;;   (completion-category-overrides '((file (styles partial-completion))))
;;   (completion-category-defaults nil))
;; 
;; (use-package marginalia
;;   :after vertico
;;   :config (marginalia-mode 1))
;; 
;; (use-package consult
;;   :bind (("C-x b" . consult-buffer)
;;          ("M-s l" . consult-line)
;;          ("M-s g" . consult-grep)
;;          ("M-s f" . consult-find)))


;;; NAVIGATION
;; ================

(keymap-global-set "C-x C-b" 'ibuffer)

;; Avy navigation framework
(use-package avy
  :commands (avy-goto-char
             avy-goto-char-2
             avy-next)
  :init
  (keymap-global-set "C-'" 'avy-goto-char-2)
  (keymap-global-set "M-'" 'avy-goto-char-2)) ; doesn't work on Termux

;;; HELP
;; ================

;; Which-key
(use-package which-key
  :defer 1
  :custom
  (which-key-show-early-on-C-h t)
  (which-key-idle-delay 0.8)
  (which-key-idle-secondary-delay 0.05)
  (which-key-add-column-padding 1)
  (which-key-max-display-columns 4)
  (which-key-max-description-length 40)
  ;; Popup location: 'bottom, 'right, 'frame, or 'minibuffer
  (which-key-popup-type 'side-window)
  (which-key-side-window-location 'bottom)
  (which-key-sort-order 'which-key-key-order-alpha)
  ;; Make it look nicer
  (which-key-use-C-h-commands t)
  (which-key-show-operator-state-maps t)
  :config
  (which-key-mode 1))

;; Better Emacs Help with Helpful
(use-package helpful
  :commands (helpful-callable
             helpful-variable
             helpful-key
             helpful-command
             helpful-at-point
             helpful-function)
  :bind
  ([remap describe-command] . helpful-command)
  ([remap describe-function] . helpful-callable)
  ([remap describe-key] . helpful-key)
  ([remap describe-symbol] . helpful-symbol)
  ([remap describe-variable] . helpful-variable)
  :custom
  (helpful-max-buffers 7))


;;; EDITING
;; ================

;; Typed text replaces acticve selection.
(delete-selection-mode 1)

;; When yanking text between modes, don't yank face
;; Prevents i.e. "Org Bleeding"
(add-to-list 'yank-excluded-properties 'face)

;; Affecting buffer also affects file it points to
(use-package bufferfile
  :commands (bufferfile-copy
             bufferfile-rename
             bufferfile-delete)
  :custom
  (bufferfile-verbose nil)
  ;; If non-nil, enable using version control (VC) when available
  (bufferfile-use-vc nil)
  ;; Specifies the action taken after deleting a file and killing its buffer.
  (bufferfile-delete-switch-to 'parent-directory))

;;; Uncomment to enable automatic insertion and management of matching pairs of characters
;;; (e.g., (), {}, "") globally using `electric-pair-mode'.
;; (use-package elec-pair
;;   :ensure nil
;;   :config
;;   (electric-pair-mode 1))

;;; TERMINALS
;; ================

;; EAT terminal emulator
(use-package eat
  :preface
  (defun my/eat-setup ()
    (setq-local show-trailing-whitespace nil))
  :commands eat
  :hook (eat-mode . my/eat-setup))

;;; LANGUAGES & MAJOR MODES
;; ================

(use-package markdown-mode
  :commands (gfm-mode
             gfm-view-mode
             markdown-mode
             markdown-view-mode)
  :mode (("\\.markdown\\'" . markdown-mode)
         ("\\.md\\'" . markdown-mode)
         ("README\\.md\\'" . gfm-mode))
  :bind
  (:map markdown-mode-map
                ("C-c C-e" . markdown-do)))

(use-package org
  :ensure nil
  :commands (org-mode org-version)
  :mode
  ("\\.org\\'" . org-mode)
  :custom
  (org-hide-leading-stars t)
  (org-startup-indented t)
  (org-adapt-indentation nil)
  (org-edit-src-content-indentation 0)
  (org-fontify-done-headline t)
  (org-fontify-todo-headline t)
  ;; (org-fontify-whole-heading-line t)
  ;; (org-fontify-quote-and-verse-blocks t)
  (org-startup-truncated t))

;; Configure built-in sgml-mode to automatically enable
;; `sgml-electric-tag-pair-mode' in `html-mode' and `mhtml-mode', providing
;; automatic insertion of matching closing tags.
(use-package sgml-mode
  :ensure nil
  :commands (sgml-mode sgml-electric-tag-pair-mode)
  :hook ((html-mode mhtml-mode) . sgml-electric-tag-pair-mode))

;; Major mode for Nix expression language files
(use-package nix-mode
  :ensure t
  :commands (nix-mode)
  :mode ("\\.nix\\'" . nix-mode))

(use-package clojure-mode
  :ensure t
  :mode (("\\.clj\\'" . clojure-mode)
         ("\\.cljs\\'" . clojurescript-mode)
         ("\\.cljc\\'" . clojurec-mode)
         ("\\.edn\\'" . edn-mode)))

(use-package cider
  :ensure t
  :commands (cider-jack-in
             cider-jack-in-clj
             cider-jack-in-cljs
             cider-connect
             cider-eval-buffer)
  :hook (clojure-mode clojurescript-mode clojurec-mode)
  :custom
  ;; Don't show the startup banner in the REPL
  (cider-repl-display-help-banner nil)
  ;; Show REPL but don't steal focus
  (cider-repl-pop-to-buffer-on-connect 'display-only)
  ;; Error buffer behavior
  (cider-show-error-buffer t)
  (cider-auto-select-error-buffer nil)
  ;; Persist REPL history
  (cider-repl-history-file (expand-file-name "cider-history" user-emacs-directory))
  (cider-repl-wrap-history t)
  ;; Don't auto-inject dependencies unless you explicitly want cider-nrepl
  ;; (cider-inject-dependencies-at-jack-in t) ;; default is t
  )


;;; DIRED
;; ================

;; dired: Group directories first
(with-eval-after-load 'dired
  (let ((args "--group-directories-first -ahlv"))
    (when (or (eq system-type 'darwin) (eq system-type 'berkeley-unix))
      (if-let* ((gls (executable-find "gls")))
          (setq insert-directory-program gls)
        (setq args nil)))
    (when args
      (setq dired-listing-switches args))))

;; Constrain vertical cursor movement to lines within the buffer
(setq dired-movement-style 'bounded-files)




;; Load custom-file quietly at the end if it exists
(when custom-file
  (load custom-file 'noerror 'nomessage))
