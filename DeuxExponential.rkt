;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname DeuxExponential) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #t)))
(require 2htdp/image)
(require 2htdp/universe)

;; Desktop-variant of wildly popular 2048 mobile app game

;; Goal is to use arrow keys to move square tiles that randomly appear on a board over time.
;; Tiles may appear only after a move is made and have a value of 2^1.
;; 2 tiles colliding into each other will collapse into 1 if they have the same values,
;; with the resulting tile having a value of the sum of the values of the 2 tiles.
;; Game is won when any tile reaches the value of 2048 (2^11) and
;; lost if there are no possible moves left (no tiles can collapse) and the board is full.

;; Start Game with (main GSX), where X is Natural[1,5]



;; CONSTANTS ================================================================
(define BG-WIDTH 300)
(define BG-HEIGHT 350)
(define BACKGROUND (empty-scene BG-WIDTH BG-HEIGHT))
(define BOARD-SPACE 25)

(define BOARD-DIM 4) ;; Dimensions of board
(define BOARD-WIDTH 250) ;; Width of game screen
(define BOARD (square BOARD-WIDTH "solid" "whitesmoke")) ;; Background color of game screen

(define SQ-WIDTH 50) ;; Width of a square tile (and empty slot)

;; Square tiles change color as their values change. Currently in this list are 12 colors, in chromatic progression,
;; with the first color being the color of an empty slot, the next being the color for the 2^1 tile, and so on, with
;; the last color being the color for the 2^11 tile.
(define SQ-COLORS (list "gainsboro" "lightblue" "skyblue" "aqua"
                        "teal" "indigo" "thistle" "deeppink"
                        "orange" "yellow" "greenyellow" "seagreen"))

(define FONT-SIZE 20) ;; Font size of numbers on square tiles
(define FONT-COLOR "white") ;; Color of numbers on square tiles

(define SQ-SPACE 10) ;; Spacing between each square tile and edge of Board
(define WIN-NUMBER 11) ;; i.e. Game is won if any square tile has the value of 2^WIN-NUMBER

;; 16 available Positions in a 4 by 4 Board (coordinates are supposed to be the centre of each Square)
;; Order goes from left to right then down (see BOARD-POS example below).

;; First Row: 1 2 3 4
(define POS1 (make-posn 35 35)) ;; top-left corner
(define POS2 (make-posn 95 35))
(define POS3 (make-posn 155 35))
(define POS4 (make-posn 215 35)) ;; top-right-corner

;; Second Row: 5 6 7 8
(define POS5 (make-posn 35 95))
(define POS6 (make-posn 95 95))
(define POS7 (make-posn 155 95))
(define POS8 (make-posn 215 95))

;; Third Row: 9 10 11 12
(define POS9 (make-posn 35 155))
(define POS10 (make-posn 95 155))
(define POS11 (make-posn 155 155))
(define POS12 (make-posn 215 155))

;; Fourth Row: 13 14 15 16
(define POS13 (make-posn 35 215)) ;; bottom-left corner
(define POS14 (make-posn 95 215))
(define POS15 (make-posn 155 215))
(define POS16 (make-posn 215 215)) ;; bottom-right corner

;; List of available positions in the Board
(define BOARD-POS (list POS1 POS2 POS3 POS4
                        POS5 POS6 POS7 POS8
                        POS9 POS10 POS11 POS12
                        POS13 POS14 POS15 POS16))
;; 1  2  3  4
;; 5  6  7  8
;; 9  10 11 12
;; 13 14 15 16



;; DATA DEFINITIONS  ================================================================

(define-struct sq (val slot pos losl))
;; Square is (make-sq Natural[0,11] Natural[1,16] Position (listof Natural[0,16]))
;; The square tile with a power of 2 number
;; interp. val is the power value of the Square where 0 means that it currently has no value and 1-11 implies 2^1, 2^2, ... and so on.
;;         slot is space on a 4x4 slot Board where the Square is located, from 1-16 (left to right then down).
;;         pos is the x-position and y-position of the centre of the Square on the Board in screen coordinates (fixed values determined by dimensions of Board).
;;         losl is the list of 4 slots surrounding the square, in order of the slot above, below, to the left, and to the right of the square. If 0, there is no available slot in that area (i.e. there is a "wall" in that direction).

;; losl CONSTANTS    U D L R
(define LOSL-1 (list 0 5 0 2))
(define LOSL-2 (list 0 6 1 3))
(define LOSL-3 (list 0 7 2 4))
(define LOSL-4 (list 0 8 3 0))

(define LOSL-5 (list 1 9 0 6))
(define LOSL-6 (list 2 10 5 7))
(define LOSL-7 (list 3 11 6 8))
(define LOSL-8 (list 4 12 7 0))

(define LOSL-9 (list 5 13 0 10))
(define LOSL-10 (list 6 14 9 11))
(define LOSL-11 (list 7 15 10 12))
(define LOSL-12 (list 8 16 11 0))

(define LOSL-13 (list 9 0 0 14))
(define LOSL-14 (list 10 0 13 15))
(define LOSL-15 (list 11 0 14 16))
(define LOSL-16 (list 12 0 15 0))

;; EXAMPLES
(define WALL (make-sq 0 0 (make-posn 0 0) empty))

;; Empty Squares
(define SQ1-0 (make-sq 0 1 POS1 LOSL-1))
(define SQ2-0 (make-sq 0 2 POS2 LOSL-2))
(define SQ3-0 (make-sq 0 3 POS3 LOSL-3))
(define SQ4-0 (make-sq 0 4 POS4 LOSL-4))
(define SQ5-0 (make-sq 0 5 POS5 LOSL-5))
(define SQ6-0 (make-sq 0 6 POS6 LOSL-6))
(define SQ7-0 (make-sq 0 7 POS7 LOSL-7))
(define SQ8-0 (make-sq 0 8 POS8 LOSL-8))
(define SQ9-0 (make-sq 0 9 POS9 LOSL-9))
(define SQ10-0 (make-sq 0 10 POS10 LOSL-10))
(define SQ11-0 (make-sq 0 11 POS11 LOSL-11))
(define SQ12-0 (make-sq 0 12 POS12 LOSL-12))
(define SQ13-0 (make-sq 0 13 POS13 LOSL-13))
(define SQ14-0 (make-sq 0 14 POS14 LOSL-14))
(define SQ15-0 (make-sq 0 15 POS15 LOSL-15))
(define SQ16-0 (make-sq 0 16 POS16 LOSL-16))

;; New Tiles
(define SQ1-1 (make-sq 1 1 POS1 LOSL-1))
(define SQ2-1 (make-sq 1 2 POS2 LOSL-2))
(define SQ3-1 (make-sq 1 3 POS3 LOSL-3))
(define SQ4-1 (make-sq 1 4 POS4 LOSL-4))
(define SQ5-1 (make-sq 1 5 POS5 LOSL-5))
(define SQ6-1 (make-sq 1 6 POS6 LOSL-6))
(define SQ7-1 (make-sq 1 7 POS7 LOSL-7))
(define SQ8-1 (make-sq 1 8 POS8 LOSL-8))
(define SQ9-1 (make-sq 1 9 POS9 LOSL-9))
(define SQ10-1 (make-sq 1 10 POS10 LOSL-10))
(define SQ11-1 (make-sq 1 11 POS11 LOSL-11))
(define SQ12-1 (make-sq 1 12 POS12 LOSL-12))
(define SQ13-1 (make-sq 1 13 POS13 LOSL-13))
(define SQ14-1 (make-sq 1 14 POS14 LOSL-14))
(define SQ15-1 (make-sq 1 15 POS15 LOSL-15))
(define SQ16-1 (make-sq 1 16 POS16 LOSL-16))

(define NEW-TILES (list SQ1-1 SQ2-1 SQ3-1 SQ4-1
                        SQ5-1 SQ6-1 SQ7-1 SQ8-1
                        SQ9-1 SQ10-1 SQ11-1 SQ12-1
                        SQ13-1 SQ14-1 SQ15-1 SQ16-1))

(define SQ14-5 (make-sq 5 14 POS14 LOSL-14))

;; TEMPLATE
#;
(define (fn-for-sq sq)
  (... (sq-val sq)
       (sq-slot sq)
       (fn-for-posn (sq-pos sq))
       (sq-losl sq)))



;; Board is (listof Square)
;; A 4x4 board with square tiles

;; EXAMPLES

(define BD0 (list ;; empty board
             SQ1-0 SQ2-0 SQ3-0 SQ4-0
             SQ5-0 SQ6-0 SQ7-0 SQ8-0
             SQ9-0 SQ10-0 SQ11-0 SQ12-0
             SQ13-0 SQ14-0 SQ15-0 SQ16-0))
;; 0 0 0 0
;; 0 0 0 0
;; 0 0 0 0
;; 0 0 0 0

(define BD1 (list ;; partially full board with possible moves to change values of current square tiles
             SQ1-0 SQ2-0 SQ3-0 SQ4-0
             SQ5-0 SQ6-0 SQ7-0 SQ8-0
             (make-sq 2 9 POS9 LOSL-9) SQ10-1 SQ11-0 SQ12-0
             (make-sq 2 13 POS13 LOSL-13) SQ14-1 SQ15-1 SQ16-0))

;; 0 0 0 0
;; 0 0 0 0
;; 2 1 0 0
;; 2 1 1 0

(define BD1-D (list ;; result of moving BD1 tiles down (assuming no new tile appeared)
               SQ1-0 SQ2-0 SQ3-0 SQ4-0
               SQ5-0 SQ6-0 SQ7-0 SQ8-0
               SQ9-0 SQ10-0 SQ11-0 SQ12-0
               (make-sq 3 13 POS13 LOSL-13) (make-sq 2 14 POS14 LOSL-14) SQ15-1 SQ16-0))
;; 0 0 0 0
;; 0 0 0 0
;; 0 0 0 0
;; 3 2 1 0

(define BD1-U (list ;; result of moving BD1 tiles up (assuming no new tile appeared)
               (make-sq 3 1 POS1 LOSL-1) (make-sq 2 2 POS2 LOSL-2) SQ3-1 SQ4-0
               SQ5-0 SQ6-0 SQ7-0 SQ8-0
               SQ9-0 SQ10-0 SQ11-0 SQ12-0
               SQ13-0 SQ14-0 SQ15-0 SQ16-0))

;; 3 2 1 0
;; 0 0 0 0
;; 0 0 0 0
;; 0 0 0 0

(define BD1-L (list ;; result of moving BD1 tiles left (assuming no new tile appeared)
               SQ1-0 SQ2-0 SQ3-0 SQ4-0
               SQ5-0 SQ6-0 SQ7-0 SQ8-0
               (make-sq 2 9 POS9 LOSL-9) SQ10-1 SQ11-0 SQ12-0
               (make-sq 2 13 POS13 LOSL-13) (make-sq 2 14 POS14 LOSL-14) SQ15-0 SQ16-0))

;; 0 0 0 0
;; 0 0 0 0
;; 2 1 0 0
;; 2 2 0 0

(define BD1-R (list ;; result of moving BD1 tiles right (assuming no new tile appeared)
               SQ1-0 SQ2-0 SQ3-0 SQ4-0
               SQ5-0 SQ6-0 SQ7-0 SQ8-0
               SQ9-0 SQ10-0 (make-sq 2 11 POS11 LOSL-11) SQ12-1
               SQ13-0 SQ14-0 (make-sq 2 15 POS15 LOSL-15) (make-sq 2 16 POS16 LOSL-16)))

;; 0 0 0 0
;; 0 0 0 0
;; 0 0 2 1
;; 0 0 2 2

(define BD-SAME (list ;; partially full board with possible moves (L or D) that would not change the values of current non-blank square tiles
                 SQ1-0 SQ2-0 SQ3-0 SQ4-0
                 (make-sq 3 5 POS5 LOSL-5) SQ6-0 SQ7-0 SQ8-0
                 (make-sq 4 9 POS9 LOSL-9) (make-sq 3 10 POS10 LOSL-10) SQ11-0 SQ12-0
                 (make-sq 5 13 POS13 LOSL-13) (make-sq 4 14 POS14 LOSL-14) (make-sq 3 15 POS15 LOSL-15)  SQ16-0))

;; 0 0 0 0
;; 3 0 0 0
;; 4 3 0 0
;; 5 4 3 0

(define BD-FULL (list ;; full board with possible moves left (in all directions)
                 (make-sq 2 1 POS1 LOSL-1) (make-sq 8 2 POS2 LOSL-2) (make-sq 6 3 POS3 LOSL-3) SQ4-1
                 (make-sq 2 5 POS5 LOSL-5) (make-sq 4 6 POS6 LOSL-6) (make-sq 7 7 POS7 LOSL-7) (make-sq 7 8 POS8 LOSL-8)
                 SQ9-1 (make-sq 8 10 POS10 LOSL-10) (make-sq 2 11 POS11 LOSL-11) (make-sq 3 12 POS12 LOSL-12)
                 SQ13-1 (make-sq 4 14 POS14 LOSL-14) (make-sq 9 15 POS15 LOSL-15) (make-sq 9 16 POS16 LOSL-16)))

;; 2 8 6 1
;; 2 4 7 7
;; 1 8 2 3
;; 1 4 9 9

(define BD-LOSE (list ;; full board with no possible moves left
                 SQ1-1 (make-sq 3 2 POS2 LOSL-2) SQ3-1 (make-sq 3 4 POS4 LOSL-4)
                 (make-sq 3 5 POS5 LOSL-5) SQ6-1 (make-sq 3 7 POS7 LOSL-7) SQ8-1
                 SQ9-1 (make-sq 3 10 POS10 LOSL-10) SQ11-1 (make-sq 3 12 POS12 LOSL-12)
                 (make-sq 3 13 POS13 LOSL-13) SQ14-1 (make-sq 3 15 POS15 LOSL-15) SQ16-1))

;; 1 3 1 3
;; 3 1 3 1
;; 1 3 1 3
;; 3 1 3 1

(define BD-WIN (list ;; board with WIN-NUMBER value on it
                SQ1-0 SQ2-0 SQ3-0 SQ4-0
                SQ5-0 SQ6-0 SQ7-0 SQ8-0
                SQ9-0 (make-sq 2 10 POS10 LOSL-10) (make-sq 8 11 POS11 LOSL-11) (make-sq 9 12 POS12 LOSL-12)
                SQ13-1 (make-sq 4 14 POS14 LOSL-14) (make-sq 8 15 POS15 LOSL-15) (make-sq 11 16 POS16 LOSL-16)))

;; 0 0 0 0
;; 0 0 0 0
;; 0 2 8 9
;; 1 4 8 11

(define BD-GS1 (list
                SQ1-0 SQ2-0 SQ3-0 SQ4-0
                SQ5-0 SQ6-0 SQ7-0 SQ8-0
                SQ9-1 SQ10-0 SQ11-0 SQ12-0
                SQ13-1 SQ14-0 SQ15-0 SQ16-0))

;; 0 0 0 0
;; 0 0 0 0
;; 1 0 0 0
;; 1 0 0 0

(define BD-GS2 (list
                SQ1-0 SQ2-0 SQ3-0 SQ4-0
                SQ5-0 SQ6-0 SQ7-1 SQ8-0
                SQ9-0 SQ10-0 SQ11-0 SQ12-0
                SQ13-0 SQ14-0 SQ15-1 SQ16-0))
;; 0 0 0 0
;; 0 0 1 0
;; 0 0 0 0
;; 0 0 1 0

(define BD-GS3 (list
                SQ1-0 SQ2-0 SQ3-0 SQ4-1
                SQ5-0 SQ6-0 SQ7-0 SQ8-0
                SQ9-0 SQ10-0 SQ11-0 SQ12-0
                SQ13-0 SQ14-1 SQ15-1 SQ16-0))

;; 0 0 0 1
;; 0 0 0 0
;; 0 0 0 0
;; 0 1 1 0

(define BD-GS4 (list
                SQ1-0 SQ2-0 SQ3-0 SQ4-0
                SQ5-0 SQ6-0 SQ7-0 SQ8-0
                SQ9-0 SQ10-0 SQ11-0 SQ12-1
                SQ13-1 SQ14-0 SQ15-1 (make-sq 2 16 POS16 LOSL-16)))

;; 0 0 0 0
;; 0 0 0 0
;; 0 0 0 1
;; 1 0 1 2

(define BD-GS5 (list
                SQ1-0 SQ2-0 SQ3-0 SQ4-0
                SQ5-0 SQ6-1 SQ7-0 SQ8-0
                SQ9-0 SQ10-0 SQ11-0 SQ12-0
                SQ13-0 SQ14-1 SQ15-0 (make-sq 2 16 POS16 LOSL-16)))

;; 0 0 0 0
;; 0 1 0 0
;; 0 0 0 0
;; 0 1 0 2



;; TEMPLATE
#;
(define (fn-for-board bd)
  (cond [(empty? bd) (...)]
        [else
         (... (fn-for-sq (first bd))
              (fn-for-board (rest bd)))]))



;; GameCondition is one of:
;; - false
;; - "WIN"
;; - "LOSE"
;; interp. the condition of the current GameState. If false, the player has neither lost nor won the game.
;;         If "WIN" the player has won the game (i.e. at least one of the Squares on the Board has the power of 2 value equal to the WIN-NUMBER.
;;         If "LOSE" the player has lost the game (i.e. the Board is full AND there are no possible moves left).

;; TEMPLATE
(define (fn-for-gc gc)
  (... gc))



(define-struct gs (board score cond next))
;; GameState is (make-gs Board Natural GameCondition Natural[0,16])
;; interp. the current state of the game.
;;   - board is the current Board with Squares of the game
;;   - score is the total score of the current gameplay
;;   - cond is the condition of the game i.e. whether it's been won, lost, or is still in progress
;;   - next is the empty slot in the board where a new tile will be placed on the next KeyEvent, 0 if the board is full

;; EXAMPLES
(define GS-EMPTY (make-gs BD0 0 false 1))
(define GS-BD1 (make-gs BD1 14 false 0))
(define GS-BD1-U (make-gs BD1-U 14 false 0))
(define GS-BD1-D (make-gs BD1-D 14 false 0))
(define GS-BD1-L (make-gs BD1-L 14 false 0))
(define GS-BD1-R (make-gs BD1-R 14 false 0))
(define GS-SAME (make-gs BD-SAME 94 false 0))
(define GS-WIN (make-gs BD-WIN 3094 "WIN" 0))
(define GS-LOSE (make-gs BD-LOSE 80 "LOSE" 0))

;; GAMES
(define GS1 (make-gs BD-GS1 4 false 0))
(define GS2 (make-gs BD-GS2 4 false 0))
(define GS3 (make-gs BD-GS3 6 false 0))
(define GS4 (make-gs BD-GS4 10 false 0))
(define GS5 (make-gs BD-GS5 8 false 0))

;; TEMPLATE
(define (fn-for-gs gs)
  (... (fn-for-board (gs-board gs))
       (gs-score gs)
       (fn-for-gc (gs-cond gs))
       (gs-next gs)))



;; FUNCTIONS ================================================================

;; GameState -> GameState
;; Puts everything together to create the game
(define (main gs)
  (big-bang gs                       ;; GameState
    (on-tick tick-gs)        ;; GameState -> GameState
    (to-draw render-gs)      ;; GameState -> Image
    (stop-when game-over?)   ;; GameState -> Boolean
    (on-key handle-key)))    ;; GameState KeyEvent -> GameState



;; GameState -> GameState
;; Progresses the GameState by determining if a new tile will appear, calculating the total score, and if the game is won, lost, or still in progress
(define (tick-gs gs)
  (make-gs (tick-board gs)
           (total-score gs)
           (update-game-cond gs)
           (tick-next gs)))



;; GameState -> Board
;; If gs-next is 0, just returns Board. gs-next is 0 if there are no empty slots left (stop-when will terminate on this condition),
;; or if a KeyEvent just occured that resulted in a change in the values on the Board. Otherwise, generate board with new tile
(check-expect (tick-board GS-WIN) (gs-board GS-WIN))
(check-expect (tick-board GS-EMPTY) (cons SQ1-1 (rest BD0)))
(check-expect (tick-board (make-gs BD-GS1 4 false 4)) (list SQ1-0 SQ2-0 SQ3-0 SQ4-1
                                                            SQ5-0 SQ6-0 SQ7-0 SQ8-0
                                                            SQ9-1 SQ10-0 SQ11-0 SQ12-0
                                                            SQ13-1 SQ14-0 SQ15-0 SQ16-0)) 

(define (tick-board gs)
  (local [(define (generate-board bd n tiles acc)
            (cond [(zero? n) bd]
                  [(= 1 n) (append (reverse acc) (list (first tiles)) (rest bd))]
                  [else
                   (generate-board (rest bd) (- n 1) (rest tiles) (cons (first bd) acc))]))]
    (generate-board (gs-board gs) (gs-next gs) NEW-TILES empty)))



;; GameState -> Natural[0,16]
;; If gs-next is 0, randomly generate the next (empty) position where a new tile will be placed. Otherwise, just returns gs-next.
(check-expect (tick-next GS-LOSE) 0)
(check-expect (tick-next GS-EMPTY) 1)
(check-expect (tick-next (make-gs (cons SQ1-0 (rest NEW-TILES)) 30 false 0)) 1)

(define (tick-next gs)
  (local [(define MT-SPOTS
            (filter (lambda (x) (= 0 (sq-val x))) (gs-board gs)))

          (define (get-next gs)
            (generate-next MT-SPOTS MT-SPOTS (random 17)))
          
          (define (generate-next x mt n)
            (cond [(empty? mt) 0]
                  [(empty? x) (generate-next mt mt (random 17))]
                  [(= (sq-slot (first x)) n) n]
                  [else
                   (generate-next (rest x) mt n)]))]
    (if (not (zero? (gs-next gs))) (gs-next gs) (get-next gs))))



;; GameState -> Natural
;; Sums the total score on the board (in powers of 2)
(check-expect (total-score GS-EMPTY) 0)
(check-expect (total-score GS-BD1) 14)
(check-expect (total-score GS-WIN) 3094)
(check-expect (total-score GS-LOSE) 80)

(define (total-score gs)
  (local [(define (sum-board bd)
            (cond [(empty? bd) 0]
                  [(zero? (sq-val (first bd))) (sum-board (rest bd))]
                  [else
                   (+ (expt 2 (sq-val (first bd)))
                      (sum-board (rest bd)))]))]
    (sum-board (gs-board gs))))



;; GameState -> GameState
;; Checks if any of the square tiles has a value of 2^WIN-NUMBER and returns "TRUE" in that case,
;; Checks if there are no possible moves left on a full board and returns "LOSE" in that case,
;; else returns false
(check-expect (update-game-cond GS-EMPTY) false)
(check-expect (update-game-cond (make-gs NEW-TILES 32 false 0)) false)
(check-expect (update-game-cond GS-LOSE) "LOSE")
(check-expect (update-game-cond GS-WIN) "WIN")

(define (update-game-cond gs)
  (local [(define (check-board b)
            (cond [(won? (gs-board gs)) "WIN"]
                  [(has-moves? (gs-board gs)) false]
                  [else "LOSE"]))

          (define (won? b)
            (cond [(empty? b) false]
                  [(= WIN-NUMBER (sq-val (first b))) true]
                  [else
                   (won? (rest b))]))

          (define (has-moves? b)
            (or (any-empty? b)
                (collapsible? b b)))

          (define (any-empty? b)
            (cond [(empty? b) false]
                  [(zero? (sq-val (first b))) true]
                  [else
                   (any-empty? (rest b))]))

          (define (collapsible? b bd)
            (cond [(empty? b) false]
                  [(eq-neighbours? (sq-val (first b)) (sq-losl (first b)) bd) true]
                  [else
                   (collapsible? (rest b) bd)]))

          (define (eq-neighbours? v l b)
            (cond [(empty? l) false]
                  [(zero? (first l)) (eq-neighbours? v (rest l) b)]
                  [(= v (sq-val (list-ref b (- (first l) 1)))) true]
                  [else
                   (eq-neighbours? v (rest l) b)]))]
    (check-board (gs-board gs))))



;; GameState -> Image
;; Renders the entire game, including score, tiles, and board
(check-expect (render-gs GS-SAME) (place-image/align (above (render-score GS-SAME)
                                                            (rectangle BOARD-WIDTH BOARD-SPACE "solid" "white")
                                                            (render-board (gs-board GS-SAME)))
                                                     (/ BG-WIDTH 2)
                                                     (/ BG-HEIGHT 2)
                                                     "center"
                                                     "center"
                                                     BACKGROUND))
(check-expect (render-gs GS-WIN) (place-image/align (above (render-score GS-WIN)
                                                           (rectangle BOARD-WIDTH BOARD-SPACE "solid" "white")
                                                           (render-board (gs-board GS-WIN)))
                                                    (/ BG-WIDTH 2)
                                                    (/ BG-HEIGHT 2)
                                                    "center"
                                                    "center"
                                                    BACKGROUND))
(check-expect (render-gs GS-LOSE) (place-image/align (above (render-score GS-LOSE)
                                                            (rectangle BOARD-WIDTH BOARD-SPACE "solid" "white")
                                                            (render-board (gs-board GS-LOSE)))
                                                     (/ BG-WIDTH 2)
                                                     (/ BG-HEIGHT 2)
                                                     "center"
                                                     "center"
                                                     BACKGROUND))

(define (render-gs gs)
  (place-image/align (above (render-score gs)
                            (rectangle BOARD-WIDTH BOARD-SPACE "solid" "white")
                            (render-board (gs-board gs)))
                     (/ BG-WIDTH 2)
                     (/ BG-HEIGHT 2)
                     "center"
                     "center"
                     BACKGROUND))



;; GameState -> Image
;; Renders the score and win/lose condition in the game
(check-expect (render-score GS-SAME) (text (string-append "Score: " (number->string (gs-score GS-SAME))) 20 "black"))
(check-expect (render-score GS-WIN) (text (string-append "You reached " (number->string (expt 2 WIN-NUMBER)) "! You won!") 20 "black"))
(check-expect (render-score GS-LOSE) (text "No moves left! Game over!" 20 "black"))

(define (render-score gs)
  (cond [(boolean? (gs-cond gs)) (text (string-append "Score: " (number->string (gs-score gs))) 20 "black")]
        [(string=? "WIN" (gs-cond gs)) (text (string-append "You reached " (number->string (expt 2 WIN-NUMBER)) "! You won!") 20 "black")]
        [(string=? "LOSE" (gs-cond gs)) (text "No moves left! Game over!" 20 "black")]))



;; Board -> Image
;; Renders all the tiles in their respective slots on a square board
(check-expect (render-board BD-SAME) (render-board BD-SAME))

(define (render-board bd)
  (cond [(empty? bd) BOARD]
        [else
         (place-image (render-sq (first bd))
                      (posn-x (sq-pos (first bd)))
                      (posn-y (sq-pos (first bd)))
                      (render-board (rest bd)))]))



;; Square -> Image
;; Converts Square data definition into image i.e. renders its score (in powers of 2) on top of a square tile of the right color based on its score
(check-expect (render-sq SQ1-0)  (place-image
                                  (text "" FONT-SIZE FONT-COLOR)
                                  (/ SQ-WIDTH 2) (/ SQ-WIDTH 2)
                                  (square SQ-WIDTH "solid" "gainsboro")))
(check-expect (render-sq SQ1-1) (place-image
                                 (text "2" FONT-SIZE FONT-COLOR)
                                 (/ SQ-WIDTH 2) (/ SQ-WIDTH 2)
                                 (square SQ-WIDTH "solid" "lightblue")))

(define (render-sq sq)
  (local [(define (render s)
            (place-image
             (text check-empty FONT-SIZE FONT-COLOR)
             (/ SQ-WIDTH 2) (/ SQ-WIDTH 2)
             (square SQ-WIDTH "solid" (list-ref SQ-COLORS (sq-val s)))))
          (define check-empty
            (if (zero? (sq-val sq))
                ""
                (number->string (expt 2 (sq-val sq)))))
          ]
    (render sq)))



;; GameState -> Boolean
;; Determines if the game is over i.e. if "WIN"/"LOSE" or not
(check-expect (game-over? GS-EMPTY) false)
(check-expect (game-over? GS-BD1) false)
(check-expect (game-over? GS-WIN) true)
(check-expect (game-over? GS-LOSE) true)

(define (game-over? gs)
  (string? (gs-cond gs)))



;; GameState KeyEvent -> GameState
;; Produces the appropriate GameState based on which arrow key is pressed and the current GameState
(check-expect (handle-key GS-EMPTY "1") GS1)
(check-expect (handle-key GS-EMPTY "2") GS2)
(check-expect (handle-key GS-EMPTY "3") GS3)
(check-expect (handle-key GS-EMPTY "4") GS4)
(check-expect (handle-key GS-EMPTY "5") GS5)
(check-expect (handle-key GS-EMPTY "up") GS-EMPTY)
(check-expect (handle-key GS-SAME "down") GS-SAME)
(check-expect (handle-key GS-BD1 "up") GS-BD1-U)
(check-expect (handle-key GS-BD1 "down") GS-BD1-D)
;(check-expect (handle-key GS-BD1 "left") GS-BD1-L)
(check-expect (handle-key GS-BD1 "right") GS-BD1-R)

(define (handle-key gs ke)
  (local [(define (move k g)
            (cond [(key=? ke "up") (update-gs gs (ret-U (unlist (map move-tiles (map collapse-tiles (map move-tiles (get-U (gs-board gs))))))))]
                  [(key=? ke "down") (update-gs gs (ret-D (unlist (map move-tiles (map collapse-tiles (map move-tiles (get-D (gs-board gs))))))))]
                  [(key=? ke "left") (update-gs gs (unlist (map move-tiles (map collapse-tiles (map move-tiles (get-L (gs-board gs)))))))]
                  [(key=? ke "right") (update-gs gs (ret-R (unlist (map move-tiles (map collapse-tiles (map move-tiles (get-R (gs-board gs))))))))]
                  [(key=? ke "1") GS1]
                  [(key=? ke "2") GS2]
                  [(key=? ke "3") GS3]
                  [(key=? ke "4") GS4]
                  [(key=? ke "5") GS5]))

          (define (get-U b)
            (list (map sq-val (list (list-ref b 0) (list-ref b 4) (list-ref b 8) (list-ref b 12)))
                  (map sq-val (list (list-ref b 1) (list-ref b 5) (list-ref b 9) (list-ref b 13)))
                  (map sq-val (list (list-ref b 2) (list-ref b 6) (list-ref b 10) (list-ref b 14)))
                  (map sq-val (list (list-ref b 3) (list-ref b 7) (list-ref b 11) (list-ref b 15)))))
          (define (ret-U b)
            (list (list-ref b 0) (list-ref b 4) (list-ref b 8) (list-ref b 12)
                  (list-ref b 1) (list-ref b 5) (list-ref b 9) (list-ref b 13)
                  (list-ref b 2) (list-ref b 6) (list-ref b 10) (list-ref b 14)
                  (list-ref b 3) (list-ref b 7) (list-ref b 11) (list-ref b 15)))
          (define (get-D b)
            (list (map sq-val (list (list-ref b 12) (list-ref b 8) (list-ref b 4) (list-ref b 0)))
                  (map sq-val (list (list-ref b 13) (list-ref b 9) (list-ref b 5) (list-ref b 1)))
                  (map sq-val (list (list-ref b 14) (list-ref b 10) (list-ref b 6) (list-ref b 2)))
                  (map sq-val (list (list-ref b 15) (list-ref b 11) (list-ref b 7) (list-ref b 3)))))
          (define (ret-D b)
            (list (list-ref b 3) (list-ref b 7) (list-ref b 11) (list-ref b 15)
                  (list-ref b 2) (list-ref b 6) (list-ref b 10) (list-ref b 14)
                  (list-ref b 1) (list-ref b 5) (list-ref b 9) (list-ref b 13)
                  (list-ref b 0) (list-ref b 4) (list-ref b 8) (list-ref b 12)))
          (define (get-L b)
            (list (map sq-val (list (list-ref b 0) (list-ref b 1) (list-ref b 2) (list-ref b 3)))
                  (map sq-val (list (list-ref b 4) (list-ref b 5) (list-ref b 6) (list-ref b 7)))
                  (map sq-val (list (list-ref b 8) (list-ref b 9) (list-ref b 10) (list-ref b 11)))
                  (map sq-val (list (list-ref b 12) (list-ref b 13) (list-ref b 14) (list-ref b 15)))))
          ;(define (ret-L b)) not needed, already in right order
          (define (get-R b)
            (list (map sq-val (list (list-ref b 3) (list-ref b 2) (list-ref b 1) (list-ref b 0)))
                  (map sq-val (list (list-ref b 7) (list-ref b 6) (list-ref b 5) (list-ref b 4)))
                  (map sq-val (list (list-ref b 11) (list-ref b 10) (list-ref b 9) (list-ref b 8)))
                  (map sq-val (list (list-ref b 15) (list-ref b 14) (list-ref b 13) (list-ref b 12)))))
          (define (ret-R b)
            (list (list-ref b 3) (list-ref b 2) (list-ref b 1) (list-ref b 0)
                  (list-ref b 7) (list-ref b 6) (list-ref b 5) (list-ref b 4)
                  (list-ref b 11) (list-ref b 10) (list-ref b 9) (list-ref b 8)
                  (list-ref b 15) (list-ref b 14) (list-ref b 13) (list-ref b 12)))

          (define (move-tiles rc)
            (cond [(empty? rc) empty]
                  [else
                   (move-tile (first rc) (move-tiles (rest rc)))]))

          (define (move-tile t tiles)
            (cond [(empty? tiles) (cons t empty)]
                  [(zero? t) (cons (first tiles) (move-tile t (rest tiles)))]
                  [else
                   (cons t tiles)]))

          (define (collapse-tiles rc)
            (cond [(empty? rc) empty]
                  [else
                   (collapse-tile (first rc) (collapse-tiles (rest rc)))]))

          (define (collapse-tile t tiles)
            (cond [(empty? tiles) (cons t empty)]
                  [(and (not (zero? t)) (= t (first tiles))) (cons (+ 1 t) (cons 0 (rest tiles)))]
                  [else
                   (cons t tiles)]))
                   
          (define (unlist ls)
            (cond [(empty? ls) empty]
                  [else
                   (append (first ls) (unlist (rest ls)))]))
          
          (define (update-gs gs bd)
            (if (no-change? (gs-board gs) bd)
                gs
                (make-gs (reconstruct (gs-board gs) bd) (gs-score gs) (gs-cond gs) 0)))

          (define (no-change? o n)
            (cond [(empty? o) true]
                  [(empty? n) true]
                  [(not (= (sq-val (first o)) (first n))) false]
                  [else
                   (no-change? (rest o) (rest n))]))

          (define (reconstruct o n)
            (cond [(empty? o) empty]
                  [(empty? n) empty]
                  [else
                   (cons (make-sq (first n) (sq-slot (first o)) (sq-pos (first o)) (sq-losl (first o)))
                         (reconstruct (rest o) (rest n)))]))]
    (move ke gs)))




