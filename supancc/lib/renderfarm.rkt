#lang racket/base

(require
  racket/class
  racket/draw
  racket/list
  "etp.rkt"
  "netpbm.rkt"
  "thread-utils.rkt")

(provide
  renderfarm%)

(define renderfarm%
  (class object%
    (init-field nodes)

    (field (passive-nodes '()))

    (field (buffer (make-bitmap 1 1)))

    (field (status 'success))

    (super-new)

    (define/public (get-buffer)
      buffer)

    (define/public (get-status)
      status)

    (define/public (ping-nodes)
      (unless (equal? status 'busy)
	     (set! passive-nodes
            (shuffle
              (apply append
                (map
                  (λ (node)
                    (let ([cores (etp/processors node)])
                      (if (void? cores)
                          '()
                          (for/list ([i (in-range cores)]) node))))
                  nodes))))))

    (define/public (render command width height)
      (thread-wait-break (start-render-async command width height))
      (send this get-buffer))

    (define/public (start-render-async command width height [segment-callback (λ () '())])
      (if (equal? status 'busy)
          (displayln "WARNING: already rendering, returning.")
          (begin
            ;; buffer needs to exist on return
            (set! buffer (make-bitmap width height))
            (thread (λ ()
              (when (empty? passive-nodes)
                (send this ping-nodes))
              (unless (empty? passive-nodes)
                (set! status 'busy)
                ;; TODO: break render into segments, about double the number of virtual nodes
                (thread-wait-break (start-segment-render-async command width height 0 width 0 height segment-callback))
                (unless (equal? status 'fail) (set! status 'success))))))))

    (define (start-segment-render-async command xres yres
                                        xmin xmax ymin ymax
                                        [segment-callback (λ () '())])
      (thread (λ ()
        ;; TODO: scheduling logic here...
        ;; remove from passive nodes, etc.
        (let ([res (etp/cli (car passive-nodes)
                     (format "~a ~a ~a ~a ~a ~a ~a"
	                         command xres yres xmin xmax ymin ymax))])
          (if (void? res)
              (set! status 'fail)
              (begin
               (send (send buffer make-dc)
                     draw-bitmap (netpbm/parse res) xmin ymin)
               (segment-callback)))))))))
