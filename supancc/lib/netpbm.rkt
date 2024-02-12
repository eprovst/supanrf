#lang racket/base

(require
  racket/draw
  racket/list
  racket/string
  racket/bytes
  racket/port
  racket/class)

(provide
  netpbm/parse
  netpbm/parse-binary-pgm
  netpbm/parse-binary-ppm)

(define (netpbm/parse img)
  (cond [(equal? (subbytes img 0 3) #"P5\n")
         (netpbm/parse-binary-pgm img)]
        [(equal? (subbytes img 0 3) #"P6\n")
         (netpbm/parse-binary-ppm img)]
        [else (error "unsupported image type")]))

(define (netpbm/parse-binary-pgm img)
  (define img-in (open-input-bytes img))
  (unless (equal? (read-bytes 3 img-in) #"P5\n")
    (error "not a binary pgm image"))
  (define header (collect-header img-in 3))
  (define width (first header))
  (define height (second header))
  (unless (equal? (third header) 255)
    (error "range header not equal to 255"))
  (define bmp (make-bitmap width height))
  (send bmp set-argb-pixels
        0 0 width height
        (g->argb (port->bytes img-in)))
  bmp)

(define (netpbm/parse-binary-ppm img)
  (define img-in (open-input-bytes img))
  (unless (equal? (read-bytes 3 img-in) #"P6\n")
    (error "not a binary pbm image"))
  (define header (collect-header img-in 3))
  (define width (first header))
  (define height (second header))
  (unless (equal? (third header) 255)
    (error "range header not equal to 255"))
  (define bmp (make-bitmap width height))
  (send bmp set-argb-pixels
        0 0 width height
        (rgb->argb (port->bytes img-in)))
  bmp)

(define (collect-header img-in fields)
  (define header (map string->number
                      (string-split (read-line img-in))))
  (define lheader (length header))
  (if (equal? lheader fields)
      header
      (append header
              (collect-header img-in (- fields lheader)))))

(define (g->argb gs)
  (bytes-append*
   (map (λ (g) (bytes 255 g g g))
        (bytes->list gs))))

(define (rgb->argb gs)
  (bytes-append*
   (map (λ (rgb) (bytes-append (bytes 255) rgb))
        (group-3-bytes gs))))

(define (group-3-bytes bytes)
  (define length (bytes-length bytes))
  (unless (equal? (modulo length 3) 0)
    (error "bytes not groupable by 3"))
  (for/list ([i (in-range (/ length 3))])
     (subbytes bytes (* 3 i) (* 3 (+ i 1)))))