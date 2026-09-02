;;; post-early-init.el --- DESCRIPTION -*- no-byte-compile: t; lexical-binding: t; -*-

;; Obtain the latest packages from MELPA to access new features and
;; improvements. While MELPA packages are generally regarded as less stable,
;; actual breakages are uncommon; over the past year, only a single package
;; (package-lint) out of 146 packages in the minimal-emacs.d author's
;; configuration experienced a brief disruption, which was quickly resolved.
(setq package-archive-priorities '(("melpa"        . 90)
                                   ("gnu"          . 70)
                                   ("nongnu"       . 60)
                                   ("melpa-stable" . 50)))
