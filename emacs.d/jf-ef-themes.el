(use-package ef-themes
  :straight t
  :init
  (defvar jf/themes-plist '()
    "The named themes by pallette.")
  :config
  (setq ef-themes-headings ; read the manual's entry or the doc string
    '((0 . (bold 1.4))
       (1 . (variable-pitch bold 1.7))
       (2 . (overline semibold 1.5))
       (3 . (monochrome overline 1.4 background))
       (4 . (overline 1.3))
       (5 . (rainbow 1.2))
       (6 . (rainbow 1.15))
       (t . (rainbow 1.1))))
  ;; When these are non-nil, the mode line uses the proportional font
  (setq ef-themes-mixed-fonts t
    ef-themes-variable-pitch-ui t)

  (defun jf/theme-custom-faces ()
    "Set the various custom faces for both `treesit' and `tree-sitter'."
    (ef-themes-with-colors
      (setq hl-todo-keyword-faces
        `(("HOLD" . ,yellow)
           ("TODO" . ,red)
           ("BLOCKED" . ,yellow)
           ("NEXT" . ,blue)
           ("THEM" . ,magenta)
           ("PROG" . ,cyan-warmer)
           ("OKAY" . ,green-warmer)
           ("DONT" . ,yellow-warmer)
           ("FAIL" . ,red-warmer)
           ("BUG" . ,red-warmer)
           ("DONE" . ,green)
           ("NOTE" . ,blue-warmer)
           ("KLUDGE" . ,cyan)
           ("HACK" . ,cyan)
           ("TEMP" . ,red)
           ("FIXME" . ,red-warmer)
           ("XXX+" . ,red-warmer)
           ("REVIEW" . ,red)
           ("DEPRECATED" . ,yellow)))
      (custom-set-faces
        `(denote-faces-link
           ((,c (:inherit link
                  :box (:line-width (1 . 1)
                         :color ,border
                         :style released-button)))))
        `(ef-themes-fixed-pitch
           ((,c (:family "IntoneMono Nerd Font Mono"))))
        `(olivetti-fringe
           ((,c (:inherit fringe :background ,bg-dim))))
        `(jf/bom-face
           ((,c (:width ultra-expanded
                  :box (:line-width (2 . 2)
                         :color ,underline-err
                         :style released-button)))))
        `(jf/mode-line-format/face-shadow
           ((,c :foreground ,fg-mode-line)))
        `(jf/tabs-face
           ((,c :underline (:style wave :color ,bg-blue-intense))))
        `(jf/org-faces-date
           ((,c :underline nil :foreground ,cyan-faint)))
        `(jf/org-faces-epigraph
           ((,c :underline nil :slant oblique :foreground ,fg-alt)))
        `(jf/org-faces-abbr
           ((,c :underline t :slant oblique :foreground ,fg-dim)))
        `(org-list-dt
           ((,c :bold t :slant italic :foreground ,fg-alt)))
        `(font-lock-misc-punctuation-face
           ((,c :foreground ,green-warmer)))
        `(elixir-ts-comment-doc-identifier
           ((,c :foreground ,comment)))
        `(elixir-ts-comment-doc-attribute
           ((,c :foreground ,comment)))
        ;; `(mode-line
        ;;    ((,c :foreground ,cyan :background ,bg-cyan-subtle)))
        `(org-block
           ;; ((,c :background ,bg-yellow-subtle)))
           ((,c :background ,bg-added-faint)))
        `(org-block-begin-line
           ((,c :background ,bg-added-refine)))
        `(org-block-end-line
           ((,c :background ,bg-added-refine)))
        `(org-modern-priority
           ((,c :foreground ,fg-term-red-bright
              :box (:color ,fg-term-red-bright :line-width (-1 . -1)))))
        `(fill-column-indicator
           ((,c :width ultra-condensed
              :background ,bg-dim
              :foreground ,bg-dim)))
        `(font-lock-regexp-face
           ((,c :foreground ,red))))))
  (setq jf/themes-plist '(:dark ef-bio :light ef-cyprus)))
