#lang racket/base

(require
  racket/class
  racket/draw
  racket/math
  racket/list
  racket/string
  racket/format
  racket/async-channel
  "etp.rkt"
  "netpbm.rkt"
  "thread-utils.rkt")

(provide
  job%
  renderfarm%)

(define job%
  (class object%
    (init-field command)

    (init-field width)

    (init-field height)

    (init-field (options '()))

    (super-new)

    (define/public (get-width) width)

    (define/public (get-height) height)

    (define/public (get-command-string xmin xmax ymin ymax)
      (string-join (map ~a
                        (append (list command width height xmin xmax ymin ymax)
                                options))
                   " "))))

(define renderfarm%
  (class object%
    (init-field nodes)

    (init-field (splitting-factor 2))

    (init-field (timeout 1))

    (field (passive-nodes null))

    (field (number-of-nodes 0))

    (field (buffer (make-bitmap 1 1)))

    (field (status 'idle))

    (field (result 'fail))

    (super-new)

    (define/public (get-buffer) buffer)

    (define/private (new-buffer width height)
      (set! buffer (make-bitmap (max 1 width) (max 1 height)))
      (let ([dc (send buffer make-dc)])
        (send dc set-background (make-color 245 202 123))
        (send dc clear)))

    (define/public (get-result) result)

    (define/public (get-nodes) nodes)

    (define/public (set-nodes! new-nodes) (set! nodes new-nodes))

    (define/public (render job)
      (thread-wait-break (start-render-async job))
      (send this get-buffer))

    (define/private (collect-nodes)
      (unless (equal? status 'busy)
        (set! number-of-nodes 0)
        (set! passive-nodes (make-async-channel))
          (threads-wait-break
            (threads-timeout
              (for/list ([node (shuffle nodes)])
                (thread
                  (λ ()
                    (let ([cores (etp/processors node)])
                      (when cores
                        (for ([i (in-range cores)])
                          (async-channel-put passive-nodes node)
                          (set! number-of-nodes
                                (add1 number-of-nodes))))))))
              timeout))))

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

    (define/public (start-render-async job [segment-callback (λ () '())])
      (if (equal? status 'busy)
          (begin
            (displayln "WARNING: already rendering, returning.")
            (thread (λ () #f)))
          (begin
            ;; buffer needs to exist on return
            (new-buffer (send job get-width) (send job get-height))
            (set! result 'pending)
            (thread (λ ()
              (collect-nodes)
              (if (zero? number-of-nodes)
                (set! result 'fail)
                (begin
                  (set! status 'busy)
                  (threads-wait-break
                   (for/list ([segment (shuffle (split-image (send job get-width)
                                                             (send job get-height)
                                                             (* splitting-factor number-of-nodes)))])
                      (let ([xmin (list-ref segment 0)]
                            [xmax (list-ref segment 1)]
                            [ymin (list-ref segment 2)]
                            [ymax (list-ref segment 3)])
                         (start-segment-render-async job
                                                     xmin xmax ymin ymax
                                                     segment-callback))))
                  (set! status 'idle)))
              (unless (equal? result 'fail) (set! result 'success)))))))

    (define/private (start-segment-render job
                                          xmin xmax ymin ymax
                                          [segment-callback (λ () '())])
      (let ([node (async-channel-get passive-nodes)])
        (if (null? node)
            ;; no more nodes, inform the others and quit
            (async-channel-put passive-nodes null)
            ;; else do try to render
            (let ([res (etp/cli node (send job get-command-string
                                               xmin xmax ymin ymax))])
              (if res
                  ;; render succeeded
                  (begin
                    (async-channel-put passive-nodes node)
                    (send (send buffer make-dc)
                          draw-bitmap (netpbm/parse res) xmin ymin)
                    (segment-callback))
                  ;; render failed, try again on other node
                  (begin
                    (set! number-of-nodes (sub1 number-of-nodes))
                    (if (< number-of-nodes 1)
                        (begin
                          (set! result 'fail)
                          ;; inform waiting threads of failure
                          (async-channel-put passive-nodes null))
                        (start-segment-render job
                                              xmin xmax ymin ymax
                                              segment-callback))))))))

    (define/private (start-segment-render-async job
                                                xmin xmax ymin ymax
                                                [segment-callback (λ () '())])
      (thread (unbreaking (λ ()
                (start-segment-render job
                                      xmin xmax ymin ymax
                                      segment-callback)))))))
