#lang r6rs
(import (library (rnrs base (6)))
        (library (rnrs io simple (6)))
        (library (rnrs lists (6)))
        (library (rnrs mutable-pairs (6))))

(define (my-eval expression environment)
  (cond [(self-evaluating? expression) expression]
        [(variable? expression) (lookup-variable-value expression environment)]
        [(quoted? expression) (dequote expression)]
        [(assignment? expression) (eval-assignment expression environment)]
        [(definition? expression) (eval-definition expression environment)]
        [(if? expression) (eval-if expression environment)]
        [(λ? expression) (make-procedure (λ-parameters expression)
                                         (λ-body expression)
                                         environment)]
        [(begin? expression) (eval-sequence (begin-actions expression)
                                            environment)]
        [(cond? expression) (my-eval (cond->if expression) environment)]
        [(application? expression) (my-apply (my-eval (operator expression)
                                                      environment)
                                             (pralues (operands expression)
                                                      environment))]
        [else (display "unknown expression type!?")]))

(define (my-apply procedure arguments)
  (cond [(primitive-procedure? procedure) (apply-primitive-procedure procedure
                                                                     arguments)]
        [(compound-procedure? procedure)
         (eval-sequence (procedure-body procedure)
                        (extend-environment
                         (procedure-parameters procedure)
                         arguments
                         (procedure-environment procedure)))]
        [else (display "unknown procedure type!?")]))

(define (primitive-procedure? procedure)
  (tagged-list? procedure 'primitive))

;; TO BE CONTINUED ...

;; (define primitive-procedures
;;   (list (list 'car car))

;; (define (apply-primitive-procedure procedure)
;;   (apply
;;    ()

(define (pralues expressions environment)
  (if (no-operands? expressions)
      '()
      (cons (my-eval (first-operand expressions) environment)
            (pralues (rest-operands expressions) environment))))

(define (eval-if expression environment)
  (if (true? (my-eval (if-predicate expression) environment))
      (my-eval (if-consequent expression) environment)
      (my-eval (if-alternative expression) environment)))

(define (eval-sequence expression environment)
  (cond [(last-expression? expressions) (my-eval (first-expression expressions)
                                                 environment)]
        [else (my-eval (first-expression expressions) environment)
              (eval-sequence (rest-expressions expressions) environment)]))

(define (eval-assignment expression environment)
  (set-variable-value! (assignment-variable expression)
                       (my-eval (assignment-variable expression) environment)
                       environment)
  'OK)

(define (eval-definition expression environment)
  (define-variable!
    (definition-variable expression)
    (my-eval (definition-value expression) environment)
    environment)
  'OK)

(define (self-evaluating? expression)
  (cond [(number? expression) true]
        [(string? expression) true]
        [else false]))

(define (variable? expression)
  (symbol? expression))

(define (quoted? expression)
  (tagged-list? expression 'quote))

(define (dequote expression)
  (cadr expression))

(define (tagged-list? expression tag)
  (if (pair? expression)
      (eq? (car expression) tag)
      false))

(define (assignment? expression)
  (tagged-list? expression 'set!))

(define (assignment-variable expression)
  (cadr expression))

(define (assignment-value expression)
  (caadr expression))

(define (definition? expression)
  (tagged-list? expression 'define))

(define (defintion-variable expression)
  (if (symbol? expression)
      (cadr expression)
      (caadr expression)))

(define (definition-value expression)
  (if symbol? (cadr expression)
      (caddr expression)
      (make-λ (cdadr expression) (cddr expression))))

(define (λ? expression)
  (tagged-list? expression 'λ))

(define (λ-parameters expression)
  (cadr expression))

(define (λ-body expression)
  (cddr expression))

(define (make-λ parameters body)
  (cons 'λ (cons parameters body)))

(define (if? expression) (tagged-list?))

(define (if-predicate expression) (cadr expression))

(define (if-consequent expression) (caddr expression))

(define (if-alternative expression)
  (if (not (null? (cddr expression)))
      (cadddr expression)
      'false))

(define (make-if predicate consequent alternative)
  (list 'if predicate consequent alternative))

(define (begin? expression) (tagged-list? expression 'begin))

(define (begin-actions expression) (cdr expression))

(define (last-expression? sequence) (null? (cdr sequence)))

(define (first-expression sequence) (car sequence))

(define (rest-expressions sequence) (cdr sequence))

(define (sequence->expression sequence)
  (cond [(null? sequence) sequence]
        [(last-expression? sequence) (first-expression sequence)]
        [else (make-begin sequence)]))

(define (application? expression) (pair? expression))

(define (operator expression) (car expression))

(define (operands expression) (cdr expression))

(define (no-operands? operands) (null? operands))

(define (first-operand operands) (car operands))

(define (rest-operands operands) (cdr operands))

(define (cond? expression) (tagged-list? expression 'cond))

(define (cond-clauses expression) (cdr expression))

(define (cond-predicate clause) (car clause))

(define (cond-actions clause) (cdr clause))

(define (cond-else-clause? clause)
  (eq? (cond-predicate caluse) 'else))

(define (cond->if expression)
  (expand-clauses (cond-clauses expression)))

(define (expand-clauses clauses)
  (if (null? clauses)
      'false
      (let ([the-first (car clauses)]
            [the-rest (cdr clauses)])
        (if (cond-else-clause? the-first)
            (if (null? the-rest)
                (sequence->expression (cond-actions the-first))
                (error "else clause needs to be last, dummy"))
            (make-if (cond-predicate the-first)
                     (sequence->expression (cond-actions first))
                     (expand-clauses the-rest))))))

(define (true? x)
  (not (eq? x false)))

(define (false? x)
  (not (eq? x true)))

(define (make-procedure parameters body environment)
  (list 'procedure parameters body environment))

(define (compound-procedure? procedure)
  (tagged-list? procedure 'procedure))

(define (procedure-parameters procedure)
  (cadr procedure))

(define (procedure-body procedure)
  (caddr procedure))

(define (procedure-environment procedure)
  (cadddr procedure))

(define (enclosing-environment env) (cdr env))

(define (first-frame env) (car env))

(define the-empty-environment '())

(define (make-frame variables values)
  (cons variables values))

(define (frame-variables frame) (car frame))

(define (frame-values frame) (cdr frame))

(define (add-binding-to-frame! variable value frame)
  (set-car! frame (cons variable (car frame)))
  (set-cdr! frame (cons value (cdr frame))))

(define (extend-environment variables values base-environment)
  (if (= (length variables) (length values))
      (cons (make-from variables values) base-environment)
      (if (< (length variables) (length values)
             (display "Too many arguments!!")
             (display "Too few arguments!!")))))

(define (lookup-variable-value variable environment)
  (define (environment-loop environment)
    (define (scan variables values)
      (cond [(null? variables)
             (environment-loop (enclosing-environment environment))]
            [(eq? variable (car variables))
             (car values)]
            [else (scan (cdr variables) (cdr values))]))
    (if (eq? environment the-empty-environment)
        (display "Unbound variables!!" variable)
        (let ([frame (first-frame environment)])
          (scan (frame-variables frame)
                (frame-values frame)))))
  (environment-loop environment))

(define (set-variable-value! variable value environment)
  (define (environment-loop environment)
    (define (scan variables values)
      (cond [(null? variables)
             (environment-loop (enclosing-environment environment))]
            [(eq? variable (car variables))
             (set-car! values value)]
            [else (scan (cdr variables) (cdr values))]))
    (if (eq? environment the-empty-environment)
        (display "unbound variable!!!")
        (let ([frame (first-frame environment)])
          (scan (frame-variables frame)
                (frame-values frame)))))
  (environment-loop environment))

(define (define-variable! variable value environment)
  (let ([frame (first-frame environment)])
    (define (scan variables values)
      (cond [(null? variables)
             (add-binding-to-frame! variable value frame)]
            [(eq? variable (car variables))
             (set-car! values value)]
            [else (scan (cdr variables) (cdr values))]))
    (scan (frame-variables frame)
          (frame-values frame))))
