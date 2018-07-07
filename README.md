# maze-game
Lego Game controlled by DE1-Soc

# Introduction
To demonstrate the knowledge learned through ECE241’s lectures and labs, we built upon
existing lab modules such as the ram block, FSM and datapath to create a maze game. The
user will input the desired direction (left, right, up, or down) with the DE1-Soc key buttons to
move the character through the maze to find the exit. 

# The Design
###  Maze Module
The Maze module is our top level module and it instantiates the VGA Adapter and the control
module. The VGA Adapter displays our graphics to the VGA Display (monitor). The top module
also connects the correct switches and keys on the DE1-Soc board as inputs to our game.

###  Control Module
The Control Module instantiates and connects the counter, multiple RAM blocks, and finite state
machine (FSM).

### Counter
The counter module is used to access and display the images stored inside the RAM blocks. It
counts from (0,0) to (159,119), the aspect ratio of our VGA display. When the FSM wants to call
a certain image, it enables the counter and the counter starts from x=0 y=0 and increments x by
1 until the edge of the screen is reached at x=159. The counter then resets x and increments y
by 1. This process is repeated until x=159 and y=119. At the same time the counter increments,
we used the relationship: RAM Address = (y*160) +x to to convert the x y coordinates to
reference the memory address for the correct RAM with the desired image. The colour of the
pixel at the certain address is received and is then used as inputs to the VGA adapter along with
the x , y locations of the pixel on the screen. The counter ensures that all the pixels inside the
RAM block are properly plotted to the VGA display.

### RAM
There are three RAM blocks as we used three different images for our game: start screen,
maze, and end screen (“Play Again” screen). The images are stored inside the RAM blocks and
counter is used to display the images on the VGA Display. The RAM for the Maze is also used
to set the boundaries for the user. The FSM checks the RAM of the maze image if the user is
beside a wall and ensures that the user cannot move forward through a wall after the user
direction input.

### FSM
The FSM Module consisted of 19 states used to delete, move and colour pixels as well as
shifting between the screens. We divided the state table into four functionality sections; waiting
state, player deletion, player movement and update/redraw player. The waiting states consisted
of start, play and end screens which waited for the user’s key input, otherwise, it looped in the
current state. Once a key is pressed, the game will switch from the start screen to “play” mode
called the A_START state. Inside the A_START state, the game will wait again for a positive
edge trigger from one of the keys which indicated player movement in a certain direction. The
game will then loop in DEL_WAIT state and react on the negative edge trigger of the pressed
key before moving on to its first deletion state. The deletion states will start from a reference
point of the pixel and return to the reference point after it looped throughout the entire player
image and colored every pixel black. After deletion, the player will be redrawn on the screen
with the updated x or y coordinate corresponding to the specific key pressed at the A_START
state. Once the player reaches the end of the maze, the “play again” screen will be displayed on
the VGA until KEY[3] is pressed to return to the “play” mode.

# Report on Success

## Accomplishments
In the end, we successfully completed our 241 project with a fully functioning maze game. Our
player pixel can move left, right, up or down based on the key input from the DE1_soc board.
We first begin with a start screen which asked the user for a KEY[3] input before moving on to
the maze. When the player reaches the end of the maze, the user will be asked to play again
with a positive KEY[3] edge trigger to return to the maze screen. At last, we achieved all of our
milestones and completed our maze game project.

## Problems​ ​and​ ​Resolutions

### Incorrect​ ​VGA​ ​Display
During Milestone 1, we encountered a glitch where multiple pixels would fly across the screen
when one key was pressed by the user. The solution was to add an additional waiting state in
between the A_START state and the DEL state in the FSM. This problem occurred because of
human reaction time in comparison to machine reaction time. The clock we used for this project
was CLOCK_50 which meant 50 million clock cycles per second. While the A_START state
waited only for a single positive edge of one of the four keys during one clock cycle, humans are
not fast enough to generate a single key edge in the duration of a single clock cycle. Instead,
this translated to multiple movements upon one key trigger which showed up on the monitor as
the flying pixel. To resolve this problem, we added an additional DEL_WAIT state right after
A_START to wait for the negative edge of the pressed key before continuing to the next logic
state. In the end, our player object would only shift 1 bit in the x or y direction with each key
trigger which is our desired output.

### Redundant​ ​FSM​ ​States
After completing our milestone 2, we decided to reduce the number of FSM states. Errors arose
due to excessive trigger of the VGA module. At the time, the FSM we had was lengthy with 45
states in total and 10 states each for up, down, left and right movement. Since most of the
states had redundant functionalities, we decided to optimize our finite state machine by
combining logic. In the end, we were left with 19 essential states; five states for deletion, nine
for drawing and five more used for transition purposes. After fixing our FSM, the original glitches
disappeared and in addition, we were able to add other states such as reset, Start and finish
screens that improved the overall design of our project.

### Flickering​ ​Images
In order to display the images stored inside the RAM blocks, we initially decided to instantiate a
counter that counts from 0 to 19199 to access the address of the RAM. Since the RAM blocks
do not reference the pixel locations as x and y coordinates like the VGA Adapter does, we had
to determine a method to convert the memory address into x,y coordinates. This was important
as the VGA adapter took x and y locations of the pixel as its input. Thus, we derived a
relationship where x = (Address of RAM) % 160 and y = (Address of RAM) / 160. For example,
address 161 of the RAM block would be (1,1) as coordinates on the VGA display screen.
Although this worked and correctly displayed the images that were stored in the RAM blocks to
the monitor, it was very glitchy and the images continuously flickered aggressively. However, we
were able to fix this glitch as I have remembered from the lectures that the division and
remainder operators are very complex in hardware, requiring many clock cycles. Therefore, we
changed the counter so that it would count from (0,0) to (160,120) for the inputs of the VGA
adapter. Since the multiplication and addition operators are much simpler than division and
remainder operator, we decided to access the RAM addresses with the relationship:
Address of RAM = (y*160)+x. After this modification, the images displayed on the VGA became
stable.

# Improvements​ ​for​ ​Next​ ​time

### Bigger​ ​pixel/user
If we were given the opportunity to redo the project, we would modify the FSM to create a bigger
player character with different shapes to make it more aesthetically pleasing. In addition, it
would require less time to move around the maze with a bigger character because of the maze
and character size comparison.

### Optimize​ ​FSM
One of the major modifications we had to make before completing the project was to combine
different logic states inside the FSM. If we could start all over again, we would have researched
FSM structures online before attempted to write our own. We spent a lot of time rewriting the
FSM towards the end because it was hard to write a fully functional FSM on the first try without
experience and practice.

# Conclusion
In conclusion, we designed a fully functioning maze game for our ECE241 final project. Through
communication and task division, we ensured our deadlines were met for each milestone. We
each worked individually on certain aspects of the design and made sure our parts were fully
functional before bringing it together on the final copy. Through this final project, we were able
to learn more about the applications of hardware and fully experience the design aspect of an
electrical and computer engineer. At last, we were able to finish our maze game because of our
time management, organizational and collaborative skills which resulted in the successful
completion of our project.
