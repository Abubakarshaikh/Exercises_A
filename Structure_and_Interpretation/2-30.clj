(defn square-tree [tree]
  (map (fn [subtree]
         (if (list? subtree)
           (square-tree subtree)
           (* subtree subtree)))
       tree))

; check
(println (square-tree
          (list 1
                (list 2 (list 3 4) 5)
                (list 6 7))))
; => (1 (4 (9 16) 25) (36 49))