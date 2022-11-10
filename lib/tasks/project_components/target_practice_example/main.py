# Import library code
from p5 import *
from random import randint

# The mouse_pressed function goes here
def mouse_pressed():
    if hit_color == Color('blue'): # Like functions, 'if' statements are indented 
        print('You hit the outer circle, 50 points!') 
    elif hit_color == Color('red'):    
        print('You hit the inner circle, 200 points!')   
    elif hit_color == Color('yellow'):    
        print('You hit the middle, 500 points!')   
    else:   
        print('You missed! No points!')    
    
# The shoot_arrow function goes here
def shoot_arrow():
    global hit_color # Can be used in other functions 
    arrow_x = randint(100, 300) # Store a random number between 100 and 300
    arrow_y = randint(100, 300) # Store a random number between 100 and 300
    hit_color = get(arrow_x, arrow_y) # Get the hit colour 
    fill('sienna') # Set the arrow to fill colour to brown   
    circle(arrow_x, arrow_y, 15) # Draw a small circle at random coordinates 

def setup():
# Setup your game here
    size(400, 400) # width and height
    no_stroke()

def draw():
# Things to do in every frame
  fill('cyan')
  rect(0, 0, 400, 250) # Sky
  fill('lightgreen')
  rect(0, 250, 400, 150) # Grass
  fill('sienna') 
  triangle(150, 350, 200, 150, 250, 350) # Stand 
  fill('blue')
  circle(200, 200, 170) # Outer circle 
  fill('red')   
  circle(200, 200, 110) # Inner circle   
  fill('yellow')   
  circle(200, 200, 30) # Middle  
  shoot_arrow()
  
# Keep this to run your code
run(frame_rate=2)
