#lang racket/base

(require
  racket/class
  racket/draw
  racket/math
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

    (init-field (splitting-factor 2))

    (init-field (timeout 1))

    (field (passive-nodes null))

    (field (buffer (make-bitmap 1 1)))

    (field (status 'idle))

    (field (result 'fail))

    (super-new)

    (define/public (get-buffer)
      buffer)

    (define/public (get-result)
      result)

    (define/public (render command width height)
      (thread-wait-break (start-render-async command width height))
      (send this get-buffer))

    (define/private (collect-nodes)
      (define number 0)
      (unless (equal? status 'busy)
        (set! passive-nodes (make-async-channel))
          (threads-wait-break
            (threads-timeout
              (for/list ([node (shuffle nodes)])
                (thread
                  (λ ()
                    (let ([cores (etp/processors node)])
                      (unless (void? cores)
                        (for ([i (in-range cores)])
                          (async-channel-put passive-nodes node)
                          (set! number (add1 number))))))))
              timeout)))
      number)

    (define/private (split-image width height n)
      (if (or (zero? n) (zero? width) (zero? height))
        '()
        (begin
          (let* ([f (/ height width)]
                 [2sn (* 2 (exact-ceiling (sqrt n)))]
                 [nx (min (exact-ceiling (sqrt (/ n f))) 2sn)]
                 [ny (min (exact-ceiling (* f nx)) 2sn)]
                 [dx (exact-ceiling (/ width nx))]
                 [dy (exact-ceiling (/ height ny))])
            (for*/list ([i (in-range nx)]
                        [j (in-range ny)])
              (list (* i dx) (min (* (add1 i) dx) width)
                    (* j dy) (min (* (add1 j) dy) height)))))))

    (define/public (start-render-async command width height [segment-callback (λ () '())])
      (if (equal? status 'busy)
          (begin
            (displayln "WARNING: already rendering, returning.")
            (thread (λ () (void))))
          (begin
            ;; buffer needs to exist on return
            (set! buffer (make-bitmap (max 1 width) (max 1 height)))
            (set! result 'pending)
            (thread (λ ()
              (define num-nodes (collect-nodes))
              (if (zero? num-nodes)
                (set! result 'fail)
                (begin
                  (set! status 'busy)
                  (threads-wait-break
                    (for/list ([segment (shuffle (split-image width height (* splitting-factor num-nodes)))])
                      (let ([xmin (list-ref segment 0)]
                            [xmax (list-ref segment 1)]
                            [ymin (list-ref segment 2)]
                            [ymax (list-ref segment 3)])
                         (start-segment-render-async command width height
                                                     xmin xmax ymin ymax
                                                     segment-callback))))
                  (set! status 'idle)))
              (unless (equal? result 'fail) (set! result 'success)))))))

    (define/private (start-segment-render-async command xres yres
                                                xmin xmax ymin ymax
                                                [segment-callback (λ () '())])
      (thread (unbreaking (λ ()
        (let* ([node (async-channel-get passive-nodes)]
               [res (etp/cli node
                      (format "~a ~a ~a ~a ~a ~a ~a"
                              command xres yres xmin xmax ymin ymax))])
          (if (void? res) ; render failed
              (set! result 'fail)
              (begin
                (async-channel-put passive-nodes node)
                (send (send buffer make-dc)
                      draw-bitmap (netpbm/parse res) xmin ymin)
                (segment-callback))))))))))
