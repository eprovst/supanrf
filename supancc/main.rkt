#lang racket/gui

(require
  "lib/etp.rkt"
  "lib/netpbm.rkt")

(define (render command width height)
  (define res
    (etp/cli "localhost"
             (format "~a ~a ~a 0 ~a 0 ~a"
                     command width height width height)))
  (unless (void? res)
    (netpbm/parse res)))

(define bitmap-canvas%
  (class canvas%
    (define bmp (make-bitmap 1 1))
    (super-new
     [paint-callback
      (λ (canvas dc)
        (send canvas set-canvas-background (make-color 124 124 124))
        (send dc set-smoothing 'aligned)
        (define scale
          (min 2
               (/ (send canvas get-width) (send bmp get-width))
               (/ (send canvas get-height) (send bmp get-height))))
        (send dc set-scale scale scale)
        (define x-offset
          (/ (- (/ (send canvas get-width) scale) (send bmp get-width)) 2))
        (define y-offset
          (/ (- (/ (send canvas get-height) scale) (send bmp get-height)) 2))
        (send dc draw-bitmap bmp x-offset y-offset))])
    (define/public (get-bitmap)
      bmp)
    (define/public (set-bitmap bitmap)
      (set! bmp bitmap)
      (send this refresh))))

(define (main)
  (define frame (new frame%
                     [label "Super-Android Control Centre"]
                     [width 600]
                     [height 400]))

  (define hpane (new horizontal-pane% [parent frame]))

  (define image (new bitmap-canvas%
                     [parent hpane]))

  (define vpane (new vertical-panel%
                     [parent hpane]
                     [stretchable-width #f]
                     [spacing 12]
                     [border 12]
                     [vert-margin 6]
                     [horiz-margin 6]
                     [style '(border)]
                     [alignment '(center center)]))

  (define choice (new choice%
                      [parent vpane]
                      [label "Demo"]
                      [choices (list "julia"
                                     "menger")]))

  (define width-field (new text-field%
                           [parent vpane]
                           [label "Width"]
                           [init-value "600"]))

  (define height-field (new text-field%
                            [parent vpane]
                            [label "Height"]
                            [init-value "600"]))

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
                                           (define outp (render
                                                         (send choice get-string-selection)
                                                         (send width-field get-value)
                                                         (send height-field get-value)))
                                           (send render-button set-label "Render")
                                           (send message set-label "")
                                           (if (void? outp)
                                               (send message set-label "Render failed.")
                                               (send image set-bitmap outp))))))
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

