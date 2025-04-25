#lang racket/base

(require
  racket/tcp
  racket/udp
  racket/port
  racket/string)

(provide
  etp/autodiscover
  etp/command
  etp/cli
  etp/info
  etp/processors)

(define (etp/command-unsafe-port ip command)
  (define-values
    (in out) (tcp-connect/enable-break ip 31337))
  (display (string-append command "\0") out)
  (flush-output out)
  (tcp-abandon-port out)
  (with-handlers
      ([exn:break? (λ (err)
                     (close-input-port in)
                     (raise err))])
    (await-heartbeats in)
    in))

(define (await-heartbeats in-port)
  ;; at least two per second, so waiting one second is plenty safe
  ;; also check whether port is at all open
  (if (and (sync/timeout/enable-break 1 in-port)
           (not (eof-object? (peek-byte in-port))))
    (when (equal? 0 (peek-byte in-port))
      (read-byte in-port)
      (await-heartbeats in-port))
    (raise (make-exn:break))))

(define (etp/command ip command)
  (with-handlers ([exn? (λ (err) #f)])
    (define in (etp/command-unsafe-port ip command))
    (define res (port->bytes in))
    (close-input-port in)
    res))

(define (etp/cli ip cli)
  (with-handlers ([exn? (λ (err) #f)])
    (define in (etp/command-unsafe-port ip (string-append "D" cli)))
    (discard-prefix in)
    (define res (port->bytes in))
    (close-input-port in)
    res))

(define (discard-prefix in-port)
  (unless (equal? (read-byte in-port) 0)
    (discard-prefix in-port)))

(define (etp/info ip)
  (define info (etp/command ip "INFO"))
  (and info
    (string-split
      (bytes->string/latin-1
        (subbytes info 0 (sub1 (bytes-length info)))) ";")))

(define (etp/processors ip)
  (define fields (etp/info ip))
  (and fields
       (string->number
        (substring
         (car
          (filter (λ (f) (equal? #\N (string-ref f 0))) fields))
         1))))

(define (etp/collect-ad-replies socket time-out)
  (let ([reply (bytes 0)]
        [start-milliseconds (current-inexact-milliseconds)])
    (if (sync/timeout/enable-break (/ time-out 1e3) (udp-receive-ready-evt socket))
      (let-values ([(amt src srcp) (udp-receive!/enable-break socket reply)]
                   [(new-time-out) (- time-out (- (current-inexact-milliseconds)
                                                  start-milliseconds))])
        (if (and (bytes=? reply #"P") (= amt 1))
          (cons src (etp/collect-ad-replies socket new-time-out))
          (etp/collect-ad-replies socket new-time-out)))
      '())))

(define (etp/autodiscover baddr (time-out 500))
  (let ([socket (udp-open-socket)])
    (udp-bind! socket #f 0)
    (udp-send-to/enable-break socket baddr 31337 #"P")
    (let ([servers (etp/collect-ad-replies socket time-out)])
      (udp-close socket)
      servers)))