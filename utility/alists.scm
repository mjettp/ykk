(define (list->alist lst)
  (let lp ((lst lst))
    (if (null? lst)
        '()
        (cons (cons (car lst)
                    (cadr lst))
              (lp (cddr lst))))))

(assert (list->alist '(1 2 3 4)) => '((1 . 2) (3 . 4)))
 

(define (update-alist orig update)
  (map (lambda (old)
         (or (assq (car old) update)
             old))
       orig))

(assert
 (update-alist '((a . 1) (b . 2) (c . 3)) '((b . 42) (d . 3))) =>
 '((a . 1) (b . 42) (c . 3)))

(define (update-force-alist orig update)
  (fold (lambda (x acc)
          (if (assq (car x) acc)
              acc
              (cons x acc)))
        '()
        (append (reverse update)
                (reverse orig))))

(assert
 (update-force-alist
  '((a . 1) (b . 2) (c . 3)) '((b . 42) (d . 3))) =>
  '((a . 1) (c . 3) (b . 42) (d . 3)))

(define (fold-two proc nil lst)
  (let lp ((lst lst) (acc nil))
    (if (null? lst)
        acc
        (lp (cddr lst)
            (proc (car lst)
                  (cadr lst)
                  acc)))))

(define (cons-alist key val nil)
  (cons (cons key val) nil))

(define-syntax let-foldr*
  (syntax-rules ()
    ((_ cons nil (tag val))
     (cons 'tag val nil))
    ((_ cons nil (tag val) (tag1 val1) ...)
     (letrec ((tag val))
       (cons 'tag tag
             (let-foldr* cons nil (tag1 val1) ...))))))

(define (alist? lst)
  (and (pair? lst)
       (pair? (car lst))))

(define (keylst-null keylst val)
  (fold-right
   (lambda (key tail)
     (list (cons key
                 (if (null? tail) val tail))))
   '()
   keylst))

(define (alist-tree-insert* keylst val alist)
  (let ((key (car keylst)))
    (map* (lambda (pair)
            (let ((head (car pair)) (tail (cdr pair)))
              (if (eq? key head)
                  (cons key
                        (if (alist? tail)
                            (alist-tree-insert (cdr keylst) val tail)
                            (cons val
                                  (if (atom? tail) (list tail) tail))))
                  pair)))
         alist)))

(define (alist-tree-insert keylst val alist)
  (if (null? alist)
      (keylst-null keylst val)
      (let ((merged (alist-tree-insert* keylst val alist)))
        (if (eq? merged alist)
            (cons (car (keylst-null keylst val))
                  alist)
            merged))))

(assert
 (alist-tree-insert
  '(zup) 4
  (alist-tree-insert
   '(foo bar) 3 '((baz . 4) (foo . ((bar . 3) (b . 5) (a . 6))) (zup . 5))))
 => '((baz . 4) (foo (bar 3 3) (b . 5) (a . 6)) (zup 4 5)))

(assert
 (cdr (assq 'foo (alist-tree-insert '(foo bar) 3 '())))
 => '((bar . 3)))

(assert
 (alist-tree-insert '(foo bar) 3 '((baz . 4)))
 => '((foo . ((bar . 3))) (baz . 4)))

;; (assert
;;  (let ((entry rest (alist-remove 'one '((one 1)
;;                                         (two 2)
;;                                         (three 3)))))
;;    (list entry rest))
;;  => '((one 1) ((two 2) (three 3))))
