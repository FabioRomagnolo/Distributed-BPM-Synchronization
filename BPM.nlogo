extensions [sound]

;;;;;;;;;;;;;;;;;
;;; VARIABLES ;;;
;;;;;;;;;;;;;;;;;

globals [
  initial-global-mean-bpm      ;; initial global mean bpm, depends on random initialization
  global-mean-bpm
  synchronized-bpm             ;; everybody synchronized on same bpm?
  printed-synchronization      ;; variable to print only one time on bpm synchronization

  d                            ;; dimension of simulation (d * d musicians will spawn)
  bpb                          ;; beat-per-bar of simulation
  r                            ;; radius of musicians' neighborhood
  listen-delay                 ;; seconds of listen delay to perceive how the other musicians are playing
]

turtles-own
[
  bpm-in-synthony    ;; is musician in synthony with his neighborhood?

  last-time-listen
  last-time-beat

  instrument         ;; each musician's instrument as string
  instrument-code    ;; each musician's instrumetn as code

  bpm                ;; each musician's perceived bpm (beats-per-minute) as speed of playing
  beat-counter       ;; each musician's internal counter of beats.
  beat-playing       ;; each musician's beat on which play (everyone will play something different during the bar in this way!)

  my-neighbours      ;; each musician's neighborhood
  n-of-neighbours    ;; number of neighbours
]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; SETUP PROCEDURES ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  reset-timer
  reset-ticks

  ; Setting user variables not changing during simulation
  set d dimension
  set bpb beats-per-bar
  set r radius
  set listen-delay listen-delay-seconds

  let cor floor (d / 2)
  ifelse d mod 2 = 0 [
    ask patches with [ pxcor <= cor and  pycor <= cor and pxcor >= (1 - cor) and pycor >= (1 - cor)] [
      sprout 1
    ]
  ] [
    ask patches with [ pxcor <= cor and  pycor <= cor and pxcor >= (0 - cor) and pycor >= (0 - cor)] [
      sprout 1
    ]
  ]

  ask turtles [setup-turtle]

  set global-mean-bpm (mean [bpm] of turtles)
  set initial-global-mean-bpm global-mean-bpm
end


to setup-turtle
  set shape "person"
  set last-time-beat timer
  set last-time-listen timer

  ; Setting bpm randomly in a certain range.
  set bpm floor one-of (range 80 120)
  set bpm-in-synthony false

  ; Setting playing beat randomly in a bpb range.
  ; - In this way everyone will play something different!
  set beat-playing one-of (range 0 bpb)
  set beat-counter 0

  ; Setting color
  set color gray - 2

  ; Setting different instrument w.r.t own turtle ID always valid
  set instrument-code (who mod length sound:instruments)
  set instrument (get-instrument instrument-code)

  setup-neighbourhood
end

to setup-neighbourhood
  set my-neighbours (other turtles) in-radius r
  set n-of-neighbours count my-neighbours
end

; Procedure to reset timer and main global variables
; - Useful when we are perturbating the system!
to reset
  reset-timer
    ask turtles [
      set last-time-beat timer
      set last-time-listen timer
    ]
    set global-mean-bpm (mean [bpm] of turtles)
    set initial-global-mean-bpm global-mean-bpm
    set printed-synchronization false
end

;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN PROCEDURE ;;;
;;;;;;;;;;;;;;;;;;;;;;

to go
  ; Reset timer if it's the first iteration!
  if ticks = 0 [
    reset
  ]

  ; Turtles listening and playing
  ask turtles [
    listen
    play
  ]

  ; Updating global-mean-bpm
  set global-mean-bpm (mean [bpm] of turtles)

  ; Checking if musicians had synchronized their bpms
  ifelse all? turtles [bpm = global-mean-bpm] [
    set synchronized-bpm true

    if printed-synchronization != true [
      print (
        word "- N°: " count turtles "; Radius: " r "; Listen delay: " listen-delay-seconds
             "; Initial GMBPM: " precision initial-global-mean-bpm 2 "; Final GMBPM: " global-mean-bpm
             "; GMBPM GAP: " precision (global-mean-bpm - initial-global-mean-bpm) 2 "; Seconds for synchronization: " timer "."
      )
      set printed-synchronization true
    ]
  ] [
    set synchronized-bpm false
  ]
  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TURTLES' PROCEDURES ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Turtle procedure to play following own BPM
to play
  ; Checking always bpm to have a positive value
  if bpm <= 0 [
    set bpm (0 - bpm)
  ]

  let sleep (60.0 / bpm)
  if timer - last-time-beat > sleep [
    set last-time-beat timer

    ifelse beat-counter = beat-playing [
      play-note
    ] [
      mute
    ]
    increase-beat-counter
  ]

end


to play-note ; turtle procedure to play single note
  show-turtle
  if enable-audio? [
    sound!
  ]
  set color yellow ;
end


to mute ; turtle procedure to mute
  ifelse show-mute-musicians? = false [
    hide-turtle
  ] [ show-turtle ]
  set color grey - 2
end


; Turtle procedure to increase the beat-counter.
; - if it becomes equal to bpb (beats-per-bar) we reset it.
to increase-beat-counter
  set beat-counter (beat-counter + 1)
  if beat-counter = bpb [
    set beat-counter 0
  ]
end


; Turtle procedure to listen what other musicians are playing.
; - if he listens the others playing slower or faster he increases or decreases his own bpm.
to listen
  if timer - last-time-listen > listen-delay [
    set last-time-listen timer

    let neighborhood-bpm bpm
    if n-of-neighbours > 0 [
      ifelse bpm-mean-approximation = "ceiling" [
          set neighborhood-bpm ceiling mean [bpm] of my-neighbours
        ] [
          set neighborhood-bpm floor mean [bpm] of my-neighbours
        ]
    ]

    let speed-gap neighborhood-bpm - bpm

    ifelse speed-gap > 0 [
      set bpm (bpm + 1)
    ] [
      set bpm (bpm - 1)
    ]
    let synthony-range 1
    ; If the speed-gap is really low musician is able to adeguate to the speed easily!
    if speed-gap < synthony-range and speed-gap > 0 - synthony-range [
      set bpm neighborhood-bpm
      set bpm-in-synthony true
    ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;
;;; SOUND PROCEDURES ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

; Turtle procedure to play a sound
to sound!
  ;Paramaters explaining of sound:play-note -> instrument note (middle C: 60) velocity (standard value: 64) seconds
  sound:play-note instrument 60 64 0.15
end

; Turtle procedure to get melodic instrument from code (1-128)
to-report get-instrument [code]
  report item code sound:instruments
end


;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PERTURB PROCEDURES ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

; Procedure to perturbe randomly the bpm faster or slower.
; - Entity of perturbation depends on the number of confused musicians involved!
to perturb
  if n-of-confused-musicians > 0 [
    reset

    print (
      word "WARNING! " n-of-confused-musicians " random selected musicians have been confused, so they're playing now faster or slower."
    )

    ask n-of n-of-confused-musicians turtles [
      let random-choice one-of ["faster" "slower"]
      let confusion one-of (range 2 31)

      ifelse random-choice = "faster" [
        set bpm bpm + confusion
      ] [
        set bpm bpm - confusion
      ]
      set bpm-in-synthony false
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
300
10
1048
759
-1
-1
20.0
1
10
1
1
1
0
0
0
1
-18
18
-18
18
0
0
1
ticks
30.0

SLIDER
15
120
190
153
dimension
dimension
1
32
10.0
1
1
NIL
HORIZONTAL

BUTTON
120
320
200
353
SETUP
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
1060
580
1220
613
show-mute-musicians?
show-mute-musicians?
0
1
-1000

BUTTON
210
320
290
353
GO
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
15
495
290
620
Musicians playing
Time
Number
0.0
100.0
0.0
1500.0
true
false
"set-plot-y-range 0 (dimension * dimension)" ""
PENS
"playing" 1.0 0 -2674135 true "" "plot count turtles with [color = yellow]"

SLIDER
15
160
187
193
radius
radius
0
20
2.0
1
1
NIL
HORIZONTAL

MONITOR
200
135
292
176
N° of musicians
dimension * dimension
0
1
10

SLIDER
1060
125
1210
158
beats-per-bar
beats-per-bar
2
6
3.0
1
1
NIL
HORIZONTAL

TEXTBOX
1065
165
1215
246
Beats-per-bar, known to everyone at the beginning, like a music sheet. For instance, when playing in 4/4, musicians set metronome's bpb to 4.
11
0.0
1

MONITOR
15
315
110
360
Global bpm mean
global-mean-bpm
2
1
11

MONITOR
15
260
290
305
N° of musicians synchronized at same bpm
count turtles with [bpm-in-synthony = true]
0
1
11

SLIDER
1060
240
1210
273
listen-delay-seconds
listen-delay-seconds
0
2
1.0
0.5
1
NIL
HORIZONTAL

TEXTBOX
1065
280
1220
340
Generally, a musician takes up to 0.5 second to listen the others and to perceive playing's speed around him.
11
0.0
1

MONITOR
15
205
140
250
Min n° of neighbours
min [n-of-neighbours] of turtles
17
1
11

MONITOR
152
205
292
250
Max n° of neighbours
max [n-of-neighbours] of turtles
17
1
11

SWITCH
1060
535
1220
568
enable-audio?
enable-audio?
0
1
-1000

CHOOSER
1060
485
1222
530
bpm-mean-approximation
bpm-mean-approximation
"ceiling" "floor"
1

BUTTON
1060
345
1220
378
CONFUSE MUSICIANS!
perturb
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
1060
445
1220
478
n-of-confused-musicians
n-of-confused-musicians
0
d * d
10.0
10
1
NIL
HORIZONTAL

TEXTBOX
1065
380
1225
435
Push above to confuse the musicians! They will start playing randomly faster of slower by a value between 2 and 30 bpms.
11
0.0
1

PLOT
15
365
290
485
Musicians synchronized
NIL
NIL
0.0
100.0
0.0
1500.0
true
false
"set-plot-y-range 0 (dimension * dimension)" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles with [bpm-in-synthony = true]"

@#$#@#$#@
## WHAT IS IT?

This model demonstrates a group of musicians synchronizing their perception of time in terms of BPM (beats-per-minute). Musicians play but also listen to what the others are playing and try to adapt their speed of playing to what they perceive. It is a good example of how a distributed system can coordinate itself without any central coordinator.

## HOW IT WORKS

Each musician follows its own musical sheet. For simplicity, the sheet is in this case one single note played during only one of the beats in the bar. To make everybody playing different patterns, the beat on which they play is randomly chosen at the beginning of simulation. 

Even if the note is equal for everybody (_middle C_), the instruments are instead chosen randomly in the setup procedure. This allows music to be etherogeneus, but also armonic.

A metronome increases its own beat counter every 60.0 / BPM seconds and so the musicians mentally do when they're playing in real contexts. A musician needs at least half second to estimate the BPM he's perceiving: if these are perceived smaller w.r.t. his own then he decelerates, otherwise he accelerates, in any case by 1 BPM. 
This is exactly what happens when two or more people play, sing, dance or clap hands together without agreeing before on same timing. Musicians are intelligent enough to adapt perfectly their speed when this difference perceived is small: in the model this gap is considered equal to 1.

At the start of the simulation all musicians begin playing following random BPM between 80 and 120: a difference greater then 40 BPM is quite impossible to find in the real world because it's too easy to recognize. 

Depending on the parameters of the simulation, the group synchronize more or less efficiently, especially depending on the seconds of listen delay.

## HOW TO USE IT

**GO**: starts and stops the simulation.

**SETUP**: resets the simulation according to the parameters set by the sliders.

**DIMENSION**: sets the dimension of the simulation. D * D musicians will spawn in a squared formation.

**RADIUS**: sets the radius of listening for each musician. For instance, if the radius is equal to 1, the musician will listen to maximum 4 neighbours.

**BEATS-PER-BAR**: sets the beats-per-bar, known to everyone at the beginning of simulation. It affects only how many musicians are playing on different beats, so it changes the rhythm of music.

**LISTEN-DELAY-SECONDS**: sets the seconds of listen delay for each musician. It makes the convergence faster or slower w.r.t. to the musician's ability to listen efficiently the others while playing. If this parameter is equal to 0, they will be able to synchronize istantly like robots, but this is certainly unreal: the normal values should be equal to 0.5 or 1.

**CONFUSE MUSICIANS!**: triggers the procedure to confuse musicians making them accelerating or decelerating randomly by a BPM value which ranges from 2 to 30.

**N-OF-CONFUSED-MUSICIANS**: sets the number of musicians to be confused. The higher is, the more perturbation we will have in the system.

**BPM-MEAN-APPROXIMATION**: sets the method of approximation for the estimation of mean bpm around each musician.

- _"floor"_: the musician takes the floor value of BPM mean perceived in neighborhood. This will ensure global BPM mean decreasing during the simulation.

- _"ceiling"_: the musician takes the ceiling value of BPM mean perceived in neighborhood. This will ensure global BPM mean increasing during the simulation.

**ENABLE-AUDIO?**: if switch set to on, the audio of simulation will be turned on, letting user to listen to the music played by musicians.

**SHOW-MUTE-MUSICIANS?**: if switch set to on, mute musicians are displayed in gray. If switch set to off, they are invisible until they play again.

Some settings need to be set before pressing the SETUP button. Changes to the DIMENSION, RADIUS, BEATS-PER-BAR and LISTEN-DELAY-SECONDS sliders will have no effect on a simulation in progress.
BPM-MEAN-APPROXIMATION, N-OF-CONFUSED-MUSICIANS, ENABLE-AUDIO and SHOW-MUTE-MUSICIANS?, on the other hand, can be modified and will have effect while the simulation is running.

## THINGS TO NOTICE

Independently from initial conditions, the system will converge always to an overall periodic behavior. As the simulation proceeds it's possible to listen how slowly the music will have no more random timing.

## THINGS TO TRY

Try perturbating the system with different n-of-confused-musicians after the BPM synchronized. Will they be synchronized again? Will the final BPM be greater or smaller?
Try changing the bpm-mean-approximation and see if this affects the outcome of these experiments.

Changing the listen-delay-seconds affects the velocity of convergence of system dynamics. What effect does this have on simulation?

Changing beats-per-bar value at beginning of simulation affects the rhythm of music, but how exactly?

## EXTENDING THE MODEL

This model explores the BPM synchronization problem in case of musicians playing all different instruments and musical sheets. 
But what about the beats synchronization we have between musicians playing the same instrument as in an orchestra? Can it be solved in a distributed manner by providing classes of musicians playing same musical sheets?

Introduce some deaf musicians. How do the distributed system deal with this addition?

Assign to each musician different listen delays to differentiate skills. What impact do we have on system's dynamics?

## NETLOGO FEATURES

Note the use of:

- Agentsets to intialize the neighborhood for each musician:

	```  
	set my-neighbours (other turtles) in-radius r 	
	set n-of-neighbours count my-neighbours
	```

- Metronome's code to update the beat-counter w.r.t. to current musician's BPM:
	
	```
	let sleep (60.0 / bpm)
  	if timer - last-time-beat > sleep [
    	set last-time-beat timer

    	ifelse beat-counter = beat-playing [
      		play-note
    	] [
      		mute
    	]	
    	increase-beat-counter
  	]
	```
  
  	When the beat-counter becomes equal to the value of beats-per-bar, it's resetted to 0.

- Netlogo's [sound extension](https://ccl.northwestern.edu/netlogo/docs/sound.html) is used in order to make musicians effectively play:

	```
	to sound!
  		sound:play-note instrument 60 64 0.1
	end
	```

	**sound:play-note**'s paramaters explaining:
	
	- *instrument*: unique string to identify an instrument (one of 128 melodic instruments) 
        
	- *note*: unique number to identify a note (from 0 to 127). In this case, 60 is the code for _middle C_.
         
	- *velocity*: represents the force with which the keyboard key is depressed. It ranges from 0 to 127, where 64 is the standard velocity. An higher velocity results in a louder sound.

	- *seconds*: time of playing. In this case, 0.1 is recommended.

	```
	to-report get-instrument [code]
  		report item code sound:instruments
	end
	```

- Code to assing to musicians different instruments w.r.t. to their own turtle ID:

	```
	set instrument-code (who mod length sound:instruments)
  	set instrument (get-instrument instrument-code)
	```

## CREDITS AND REFERENCES

This work was done by Fabio Romagnolo in quality of project for the Franco Zambonelli's _Distributed Artificial Intelligence_ course (A.Y. 2021/2022) at the University of Modena and Reggio Emilia.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
