#lang racket/base

(provide
  threads-wait-break
  thread-wait-break
  unbreaking)

(define (threads-wait-break trds)
  (with-handlers ([exn:break:hang-up?
                   (λ (e) (map (λ (t) (break-thread t 'hang-up)) trds))]
                  [exn:break:terminate?
                   (λ (e) (map (λ (t) (break-thread t 'terminate)) trds))]
                  [exn:break?
                   (λ (e) (map (λ (t) (break-thread t)) trds))])
    (map (λ (t) (thread-wait t)) trds)))

(define (thread-wait-break trd)
  (threads-wait-break (list trd)))

(define (unbreaking tnk)
  (λ ()
    (with-handlers ([exn:break? (λ (e) e)])
      (tnk))))
