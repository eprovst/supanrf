#lang racket/gui

(require
  "lib/etp.rkt"
  "lib/netpbm.rkt")

(define (render command)
  (define res (etp/cli "localhost" command))
  (unless (void? res)
    (netpbm/parse res)))

(define (main)
  (define frame (new frame%
                     [label "Super-Android Control Centre"]
                     [width 600]
                     [height 400]))

  (define hpane (new horizontal-pane% [parent frame]))

  (define ipane (new pane%
                     [parent hpane]
                     [alignment '(center center)]))

  (define image (new message%
                     [parent ipane]
                     [label (make-bitmap 10 10)]
                     [auto-resize #t]))

  (define vpane (new vertical-pane%
                     [parent hpane]
                     [alignment '(center center)]))

  (define choice (new choice%
                      [parent vpane]
                      [label "Demo"]
                      [choices (list "julia 600 600 0 600 0 600"
                                     "menger 200 200 0 200 0 200")]))

  (define worker null)

  (define render-button
    (new button% [parent vpane]
         [label "Render"]
         [callback (λ (button event)
                     (if (or (null? worker) (thread-dead? worker))
                         (begin
                           (send render-button set-label "Stop")
                           (set! worker
                                 (thread (λ ()
                                           (define outp (render (send choice get-string-selection)))
                                           (send render-button set-label "Render")
                                           (send message set-label "")
                                           (if (void? outp)
                                               (send message set-label "Render failed.")
                                               (send image set-label outp))))))
                         (begin
                           (send render-button set-label "Render")
                           (break-thread worker 'terminate)
                           (thread-wait worker)
                           (send message set-label "Render stopped."))))]))

  (define message (new message%
                     [parent vpane]
                     [label ""]
                     [auto-resize #t]))

  (send frame show #t)
  (void))

(main)

