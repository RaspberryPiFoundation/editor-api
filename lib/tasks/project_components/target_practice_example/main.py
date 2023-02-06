# Import library code
import py5
from random import randint

# The mouse_pressed function goes here
def mouse_pressed():
    if hit_color == py5.color('blue'): # Like functions, 'if' statements are indented
        print('You hit the outer circle, 50 points!') 
    elif hit_color == py5.color('red'):
        print('You hit the inner circle, 200 points!')
    elif hit_color == py5.color('yellow'):
        print('You hit the middle, 500 points!')
    else:
        print('You missed! No points!')
    
# The shoot_arrow function goes here
def shoot_arrow():
    global hit_color # Can be used in other functions 
    arrow_x = randint(100, 300) # Store a random number between 100 and 300
    arrow_y = randint(100, 300) # Store a random number between 100 and 300
    hit_color = py5.get(arrow_x, arrow_y) # Get the hit colour
    py5.fill('sienna') # Set the arrow fill colour to brown
    py5.circle(arrow_x, arrow_y, 15) # Draw a small circle at random coordinates

def setup():
# Setup your game here
    py5.size(400, 400) # width and height
    py5.frame_rate(2)
    py5.no_stroke()

def draw():
# Things to do in every frame
    py5.fill('cyan')
    py5.rect(0, 0, 400, 250) # Sky
    py5.fill('lightgreen')
    py5.rect(0, 250, 400, 150) # Grass
    py5.fill('sienna')
    py5.triangle(150, 350, 200, 150, 250, 350) # Stand
    py5.fill('blue')
    py5.circle(200, 200, 170) # Outer circle
    py5.fill('red')
    py5.circle(200, 200, 110) # Inner circle
    py5.fill('yellow')
    py5.circle(200, 200, 30) # Middle
    shoot_arrow()
  
# Keep this to run your code
py5.run_sketch()
