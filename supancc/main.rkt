#lang racket/gui

(require
  "lib/etp.rkt"
  "lib/netpbm.rkt")

(define (render command)
  (netpbm/parse (etp/cli "localhost" command)))

(define (main)
  (define frame (new frame% [label "Super-Android Control Centre"]))

  (define hpane (new horizontal-pane% [parent frame]))

  (define image (new message%
                     [parent hpane]
                     [label (make-bitmap 100 100)]
                     [auto-resize #t]))

  (define vpane (new vertical-pane%
                     [parent hpane]
                     [alignment '(center center)]))

  (define choice (new choice%
                      [parent vpane]
                      [label "Demo"]
                      [choices (list "julia 600 600 0 600 0 600"
                                     "menger 200 200 0 200 0 200")]))

  (new button% [parent vpane]
       [label "Render"]
       [callback (λ (button event)
                   (send image set-label
                         (render (send choice get-string-selection))))])

  (send frame show #t)
  (void))

(main)