#lang racket/base

(require
  racket/tcp
  racket/port)

(provide
  etp/command
  etp/cli
  etp/ping
  etp/processors)

(define (etp/command-unsafe-port ip command)
  (define-values
    (in out) (tcp-connect/enable-break ip 31337))
  (display (string-append command "\0") out)
  (flush-output out)
  (close-output-port out)
  (with-handlers
      ([exn:break? (λ (err)
                     (close-input-port in)
                     (raise err))])
    (discard-nulls in)
    in))

(define (discard-nulls in-port)
  (when (equal? (peek-byte in-port) 0)
    (read-byte in-port)
    (discard-nulls in-port)))

(define (etp/command ip command)
  (with-handlers ([exn? (λ (err) (void))])
    (define in (etp/command-unsafe-port ip command))
    (define res (port->bytes in))
    (close-input-port in)
    res))

(define (etp/cli ip cli)
  (with-handlers ([exn? (λ (err) (void))])
    (define in (etp/command-unsafe-port ip (string-append "D" cli)))
    (discard-prefix in)
    (define res (port->bytes in))
    (close-input-port in)
    res))

(define (discard-prefix in-port)
  (unless (equal? (read-byte in-port) 0)
    (discard-prefix in-port)))

(define (etp/processors ip)
  (define info (etp/command ip "INFO"))
  (unless (void? info)
    (string->number
      (bytes->string/latin-1
        (subbytes info 1 (- (bytes-length info) 1))))))

(define (etp/ping ip)
  (not (void? (etp/command ip "INFO"))))
