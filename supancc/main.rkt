#lang racket/base

(require
  "lib/etp.rkt"
  "lib/netpbm.rkt"
  racket/gui)

(define outp (netpbm/parse (etp/cli "localhost" "julia 600 600 0 600 0 600")))

(define frame (new frame% [label "Super-Android Control Centre"]))
(send frame show #t)
(void (new message% [parent frame] [label outp]))