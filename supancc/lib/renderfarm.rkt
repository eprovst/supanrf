#lang racket/base

(require
  racket/class
  racket/draw
  racket/list
  racket/async-channel
  "etp.rkt"
  "netpbm.rkt"
  "thread-utils.rkt")

(provide
  renderfarm%)

(define renderfarm%
  (class object%
    (init-field nodes)

    (field (passive-nodes null))

    (field (buffer (make-bitmap 1 1)))

    (field (status 'success))

    (super-new)

    (define/public (get-buffer)
      buffer)

    (define/public (get-status)
      status)

    (define/public (render command width height)
      (thread-wait-break (start-render-async command width height))
      (send this get-buffer))

    (define/private (collect-nodes)
      (define number 0)
      (unless (equal? status 'busy)
        (set! passive-nodes (make-async-channel))
        (for ([node (shuffle nodes)])
          (let ([cores (etp/processors node)])
            (unless (void? cores)
              (for ([i (in-range cores)])
                (async-channel-put passive-nodes node)
                (set! number (add1 number)))))))
      number)

    (define/private (split-image width height n)
      (define sn (inexact->exact (ceiling (sqrt n))))
      (define dx (/ width sn))
      (define dy (/ height sn))
      (for*/list ([i (in-range sn)]
                 [j (in-range sn)])
        (list (* i dx) (min (* (add1 i) dx) width)
              (* j dy) (min (* (add1 j) dy) height))))

    (define/public (start-render-async command width height [segment-callback (λ () '())])
      (if (equal? status 'busy)
          (displayln "WARNING: already rendering, returning.")
          (begin
            ;; buffer needs to exist on return
            (set! buffer (make-bitmap width height))
            (thread (λ ()
              (define num-nodes (collect-nodes))
              (set! status 'busy)
              (threads-wait-break
                (for/list ([segment (shuffle (split-image width height (* 2 num-nodes)))])
                  (let ([xmin (list-ref segment 0)]
                        [xmax (list-ref segment 1)]
                        [ymin (list-ref segment 2)]
                        [ymax (list-ref segment 3)])
                     (start-segment-render-async command width height
                                                 xmin xmax ymin ymax
                                                 segment-callback))))
              (unless (equal? status 'fail) (set! status 'success)))))))

    (define/private (start-segment-render-async command xres yres
                                                xmin xmax ymin ymax
                                                [segment-callback (λ () '())])
      (thread (unbreaking (λ ()
        (let* ([node (async-channel-get passive-nodes)]
               [res (etp/cli node
                      (format "~a ~a ~a ~a ~a ~a ~a"
	                          command xres yres xmin xmax ymin ymax))])
          (if (void? res) ; render failed, remove this node from list
              (set! status 'fail)
              (begin
                (async-channel-put passive-nodes node)
                (send (send buffer make-dc)
                      draw-bitmap (netpbm/parse res) xmin ymin)
                (segment-callback))))))))))
