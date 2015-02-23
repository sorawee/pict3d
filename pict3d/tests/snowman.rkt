#lang racket

(require pict3d
         pict3d/universe)

(current-material (make-material 0.25 0.25 0.5 0.4))

(define coal-color '(0.5 0.5 0.5))
(define coal-material (make-material 0.0 0.2 0.8 0.1))

(define torso
  (let ([torso  (scale (sphere '(0 0 0) 1/2) '(0.7 0.7 0.6))])
    (move-z
     (combine
      (basis 'neck (point-at #:from '(0 0 0.3) #:dir '(0 0 1)))
      (basis 'right-arm (point-at #:from '(0 -0.3 0.1) #:dir '(0.2 -0.3 0.3)))
      (basis 'left-arm (point-at #:from '(0 0.3 0.1) #:dir '(0.2 0.3 0.3)))
      (freeze
       (combine
        torso
        (move-x
         (with-color coal-color
           (with-material coal-material
             (combine*
              (for/list ([y  (in-list '(-0.01 0.0 -0.02 0.01))]
                         [z  (in-list '(0.2 0.1 0 -0.1))])
                (sphere (trace torso #:from (list 1 y z) #:dir '(-1 0 0 ))
                        0.035)))))
         0.01))))
     0.1)))

(define base
  (let ([base  (ellipsoid '(-0.5 -0.5 -0.15) '(0.5 0.5 0.7))])
    (combine
     (basis 'hips (point-at #:from '(0 0 0.7) #:dir '(0 0 1)))
     (freeze
      (combine
       base
       (move-x
        (with-color coal-color
          (with-material coal-material
            (combine*
             (for/list ([y  (in-list '(-0.01 0.0 -0.02))]
                        [z  (in-list '(0.58 0.5 0.4))])
               (sphere (trace base #:from (list 1 y z) #:dir '(-1 0 0)) 0.035)))))
        0.01))))))

(define nose
  (with-color "orange"
    (with-material (make-material 0.2 0.8 0.0 0.1)
      (cone '(-0.04 -0.05 0.0) '(0.04 0.05 0.25) #:segments 12 #:smooth? #t))))

(define head
  (let ([head  (sphere '(0 0 0.1) 0.25)])
    (combine
     (basis 'crown (point-at #:from '(0.05 0.02 0.3) #:dir '(0.3 0.05 1)))
     (freeze
      (combine
       head
       ;;Nose
       (move-x (move (rotate-y nose 80) (trace head #:from '(1 0 0.08) #:dir '(-1 0 0))) -0.01)
       ;; Eyes
       (let ([cr  (trace head #:from '(1 -0.1 0.14) #:dir '(-1 0 0))]
             [cl  (trace head #:from '(1 0.1 0.16) #:dir '(-1 0 0))])
         (move-x
          (combine
           ;; Creepy red eye
           (with-color '(1 0.25 0.0 0.75)
             (sphere cr 0.05))
           (with-emitted '(1 0.25 0.0 10.0)
             (sphere cr 0.035))
           (light cr '(1 0.25 0.0) 0.02)
           ;; Creepy green eye
           (with-color '(0 1 0.25 0.75)
             (sphere cl 0.04))
           (with-emitted '(0 1 0.25 10.0)
             (sphere cl 0.025))
           (light cl '(0 1 0.25) 0.02))
          0.01))
       ;; Mouth
       (with-color coal-color
         (with-material coal-material
           (combine*
            (for/list ([y  '(-0.13 -0.06 -0.01 0.07 0.12)]
                       [z  '(0.01 0.005 0.02 0.005 0.004)])
              (move-x (sphere (trace head #:from (list 1 y z) #:dir '(-1 0 0))
                              0.025)
                      0.01))))))))))

(define hat
  (freeze
   (with-color '(1 1 1)
     (with-material (make-material 0.01 0.01 0.98 0.1)
       (combine
        (cylinder '(-0.2 -0.2 0.0) '(0.2 0.2 0.4) #:segments 16)
        (cylinder '(-0.3 -0.3 -0.01) '(0.3 0.3 0.01) #:segments 16))))))

(define snowman-bottom
  (pin base 'hips torso))

(define snowman-top
  (pin head 'crown hat))

(define arm-segment
  (combine
   (move-z (scale (basis 'top (point-at #:from origin #:dir '(0.25 0 1) #:angle 30)) 0.5) 0.35)
   (move-z (scale (basis 'top (point-at #:from origin #:dir '(-0.1 0 1) #:angle 14)) 0.4) 0.3)
   (with-color "orange"
     (with-material (make-material 0.1 0.4 0.5 0.2)
       (cone '(-0.03 -0.03 0.0) '(0.03 0.03 0.5) #:segments 32 #:smooth? #t)))))

(define arm
  (freeze (weld arm-segment 'top arm-segment)))

(define (snowman t)
  (let* ([snowman  (scale-z snowman-bottom (+ 1.0 (* 0.01 (sin (/ t 100.0)))))]
         [snowman  (replace-group snowman 'neck
                                  (λ (p) (rotate-z p (* 10 (sin (/ (+ t 500.0) 1000.0))))))]
         [snowman  (pin snowman 'neck snowman-top)]
         [snowman  (pin snowman 'left-arm arm)]
         [snowman  (pin snowman 'right-arm arm)]
         [snowman  (replace-group snowman 'hips
                                  (λ (p) (rotate-z p (* 5 (sin (/ t 1000.0))))))])
    snowman))

(big-bang3d
 0.0
 #:on-frame
 (λ (p n t)
   t)
 #:on-draw
 (λ (t)
   (combine
    (basis 'camera (point-at #:from '(0.6 -1 1.25) #:to '(0 0 1)))
    (sunlight '(0 0 -1) "azure" 1)
    (light (list -0.5 -4.0 2.0) "gold" 5)
    (snowman t))))