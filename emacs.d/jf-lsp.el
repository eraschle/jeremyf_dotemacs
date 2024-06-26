;;; jf-lsp --- LSP considerations -*- lexical-binding: t -*-

;; Copyright (C) 2024 Jeremy Friesen
;; Author: Jeremy Friesen <jeremy@jeremyfriesen.com>

;; This file is NOT part of GNU Emacs.
;;; Commentary:

;;; Code:

;; Either eglot or lsp-mode; exploring this.
(if t
  (progn
    (use-package eglot
      :straight t
      ;; :straight (:type built-in)
      ;; The Language Server Protocol (LSP) is a game changer; having access to that
      ;; tooling is very much a nice to have.
      :hook ((
               yaml-mode yaml-ts-mode
               angular-mode angular-ts-mode ;; npm install -g @angular/language-service@next typescript @angular/language-server
               css-mode css-ts-mode
               elixir-ts-mode
               go-mode go-ts-mode ;; https://github.com/golang/tools/tree/master/gopls
               html-mode html-ts-mode
               js-mode js-ts-mode
               json-mode json-ts-mode
               python-mode python-ts-mode
               ruby-mode ruby-ts-mode
               scss-mode scss-ts-mode
               typescript-ts-mode typescript-mode ;; https://github.com/typescript-language-server/typescript-language-server
               )
              . eglot-ensure)
      :config
      ;; https://github.com/elixir-lsp/elixir-ls?tab=readme-ov-file
      (add-to-list 'eglot-server-programs '(elixir-ts-mode "~/elixir-ls/v0.20.0/language_server.sh"))
      ;; https://github.com/emacs-lsp/lsp-mode/wiki/Install-Angular-Language-server
      ;; with modifications for homebrew
      (add-to-list 'eglot-servier-programs
        '(angular-mode
           "node /opt/homebrew/lib/node_modules/@angular/language-server --ngProbeLocations /opt/homebrew/lib/node_modules --tsProbeLocations /opt/homebrew/lib/node_modules --stdio"))
      (add-to-list 'eglot-servier-programs
        '(angular-ts-mode
           "node /opt/homebrew/lib/node_modules/@angular/language-server --ngProbeLocations /opt/homebrew/lib/node_modules --tsProbeLocations /opt/homebrew/lib/node_modules --stdio"))
      :hook ((eglot-managed-mode . jf/eglot-capf)))


    ;; See https://elixir-lsp.github.io/elixir-ls/getting-started/emacs/

    (use-package eglot-booster
      :straight (:host github :repo "jdtsmith/eglot-booster")
      :after eglot
      :config	(eglot-booster-mode))

    (advice-add 'eglot-completion-at-point :around #'cape-wrap-buster)

    (defun jf/eglot-capf ()
      "Ensure `eglot-completion-at-point' preceeds everything."
      ;; I don't want `eglot-completion-at-point' to trample my other
      ;; completion options.
      ;;
      ;; https://stackoverflow.com/questions/72601990/how-to-show-suggestions-for-yasnippets-when-using-eglot
      (setq-local completion-at-point-functions
        (list (cape-capf-super
                #'eglot-completion-at-point
                #'tempel-expand
                #'cape-file
                #'cape-keyword))))

    (use-package eldoc
      ;; Helps with rendering documentation
      ;; https://www.masteringemacs.org/article/seamlessly-merge-multiple-documentation-sources-eldoc
      :config
      (setq eldoc-documentation-strategy
        ;; 'eldoc-documentation-enthusiast))
        'eldoc-documentation-compose-eagerly)
      (add-to-list 'display-buffer-alist
        '("^\\*eldoc"
           (display-buffer-reuse-mode-window display-buffer-below-selected)
           (dedicated . t)
           (body-function . prot-window-select-fit-size)))
      :straight t))
  (progn
    (use-package lsp-mode
      :straight t
      :hook ((elixir-ts-mode . lsp)
              (angular-ts-mode . lsp)
              (ruby-ts-mode . lsp)
              (python-ts-mode . lsp)
              (go-ts-mode . lsp)
              (lsp-mode . lsp-enable-which-key-integration))
      :commands lsp)

    (use-package lsp-ui
      :straight t
      :commands lsp-ui-mode)

    (use-package dap-mode
      :straight t)))

  (provide 'jf-lsp)
;;; jf-lsp.el ends here
