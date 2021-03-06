(import [functools [reduce]])

(import [3_streams [*]])
(require 3_streams)

(require pairs)

(defn divisible? [x y]
  (= (% x y) 0))

(def no-sevens
  (stream-filter (λ [k] (not (divisible? k 7))) ℕ+))

(assert (= (stream-nth no-sevens 100) 117))

(defn fibgen [a b]
  (cons-stream a (fibgen b (+ a b))))

(def fibs (fibgen 0 1))

(assert-stream-begins! fibs [0 1 1 2 3 5 8])

(defn sieve [stream]
  (cons-stream
   (stream-car stream)
   (sieve (stream-filter
           (λ [k] (not (divisible? k (stream-car stream))))
           (stream-cdr stream)))))

(def primes (sieve (integers-from 2)))

(assert-stream-begins! primes [2 3 5 7 11 13 17 19 23 29 31 37
                               41 43 47 53 59 61 67 71])

(def ones (cons-stream 1 ones))
(def alternatively-defined-integers
  (cons-stream 1
               (add-streams ones
                            alternatively-defined-integers)))

;; Exercise 3.54
(def factorials (cons-stream 1 (multiply-streams ℕ+ factorials)))



(def just-twos-and-fives (merge (scale-stream ℕ 2) (scale-stream ℕ 5)))
(assert-stream-begins! just-twos-and-fives [0 2 4 5 6 8 10 12])

;; Exercise 3.56
(def S (cons-stream 1
                    (reduce merge
                            (map (λ [factor] (scale-stream S factor))
                                 [2 3 5]))))

;; Exercise 3.58
(defn expand [numerator denominator radix]
  "This _adorable_ function gives us successively longer expansions of
the place-value representation (in radix `radix`) of the rational
number `numerator`/`denominator`!"
  (let [[palue (* numerator radix)]]
    (setv [quotient remainder] (divmod palue denominator))
    (cons-stream quotient (expand palue denominator radix))))

(assert-stream-begins! (expand 1 7 10) [1 14 142 1428 14285 142857 1428571])

;; confirmation of exercise 3.60
(def derived-unity (add-streams (square-series cos-series)
                                (square-series sin-series)))
(assert-stream-begins!
 derived-unity
 [1 0 0 0]) ; next term is 5.55e-17 due to floating-point error

;; (printstream-until cos-series 10)
;; (printstream-until sin-series 10)
;; (printstream-until tan-series 10)

(assert-stream-begins! (partial-sums ℕ) [0 1 3 6 10 15 21 28 36 45])

;; Exercise 3.65
(def ln2-summands
  (multiply-streams (multitone-stream [1 -1])
                    (exponentiate-stream ℕ+ -1)))

(def ln2-stream (partial-sums ln2-summands))
;; => (stream-limit ln2-stream 0.0082645)
;; {'\ufdd0:steps': 119, '\ufdd0:result': 0.6972623372115745}

(def ln2-superstream (euler-transform ln2-stream))
;; => (stream-limit (euler-transform ln2-stream) 0.00000015)
;; {'\ufdd0:steps': 116, '\ufdd0:result': 0.6931471073165805}

(def ln2-ultrastream (accelerando euler-transform ln2-stream))
;; => (stream-limit (accelerando euler-transform ln2-stream) 0.00000015)
;; {'\ufdd0:steps': 4, '\ufdd0:result': 0.6931471806635636}

;; Exercise 3.66
;; "Can you make any general comments about the order in which pairs
;; are placed into [`(nondecreasing-pairs ℕ ℕ)`]? For example, how
;; many pairs precede the pair (1, 100)? the pair (99, 100)? (100,
;; 100)?"
;;
;; It's notable that the lack of tail-recursion-optimization prevents
;; us from getting empirics for the specific pairs named as
;; examples (sys.setrecursionlimit can help, not indefinitely)---
;; => (stream-search un2 [1 100])
;; 396
;; => (stream-search un2 [99 100])
;; [very long stack trace omitted]
;; RuntimeError: maximum recursion depth exceeded in comparison
;;
;; => (list-comp (stream-search un2 [i 10]) [i (range 8)])
;; [19, 36, 66, 118, 206, 350, 574, 894]
