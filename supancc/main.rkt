#lang racket/gui

(require
 racket/list
 "lib/renderfarm.rkt"
 "lib/thread-utils.rkt")

;; Initialize the renderfarm
(define farm (new renderfarm%
                  [splitting-factor 10]
                  [timeout 0.4]
                  [nodes (file->lines "nodes.txt")]))

;; Centring and scaling image viewer
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

;; Input field only accepting numbers
(define number-field%
  (class text-field%
    (super-new
     [callback
      (λ (fld event)
        (let* ([chars (string->list (send this get-value))]
               [editor (send this get-editor)]
               [cursor (send editor get-start-position)])
          (unless (andmap char-numeric? chars)
            (send this set-value
                  (list->string (filter char-numeric? chars)))
            (send editor set-position (- cursor 1)))))])))

;; Main window
(define frame (new frame%
                   [label "Super-Android Control Centre"]
                   [width 600]
                   [height 400]))

;; Horizontally:
(define hpane (new horizontal-pane% [parent frame]))

;; * The image
(define image (new bitmap-canvas%
                   [parent hpane]))

;; * Vertically:
(define vpane (new vertical-panel%
                   [parent hpane]
                   [stretchable-width #f]
                   [spacing 12]
                   [border 12]
                   [vert-margin 6]
                   [horiz-margin 6]
                   [style '(border)]
                   [alignment '(center center)]))

;; ** The demo picker
(define demo-choice (new choice%
                    [parent vpane]
                    [label "Demo"]
                    [choices '("julia" "menger")]))

;; ** The width option
(define width-field (new number-field%
                         [parent vpane]
                         [label "Width"]
                         [init-value "600"]))

;; ** The height option
(define height-field (new number-field%
                          [parent vpane]
                          [label "Height"]
                          [init-value "600"]))

;; ** The render/stop button
(define worker null) ; worker thread

(define (render-click button event)
  (if (or (null? worker) (thread-dead? worker))
      (begin
        (send render-button set-label "Stop")
        (set! worker
              (thread (λ ()
                        (define farm-thread (send farm start-render-async
                                              (send demo-choice get-string-selection)
                                              (string->number (send width-field get-value))
                                              (string->number (send height-field get-value))
                                              (λ () (send image refresh))))
                        (send image set-bitmap (send farm get-buffer))
                        (thread-wait-break farm-thread)
                        (send render-button set-label "Render")
                        (if (equal? (send farm get-result) 'success)
                            (send error-message set-label "")
                            (send error-message set-label "Render failed."))))))
      (begin
        (send render-button set-label "Render")
        (break-thread worker 'terminate)
        (thread-wait worker)
        (send error-message set-label "Render stopped."))))

(define render-button
  (new button% [parent vpane]
       [label "Render"]
       [callback render-click]))

;; ** The error message
(define error-message (new message%
                   [parent vpane]
                   [label ""]
                   [auto-resize #t]))

;; Show the window
(send frame show #t)
