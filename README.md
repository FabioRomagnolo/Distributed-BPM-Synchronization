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