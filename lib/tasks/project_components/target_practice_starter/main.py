# Import library code
import py5
from random import randint

# The mouse_pressed function goes here
    
# The shoot_arrow function goes here

def setup():
# Setup your game here
    py5.size(400, 400) # width and height
    py5.frame_rate(2)

def draw():
# Things to do in every frame
    py5.fill('cyan')
    py5.rect(0, 0, 400, 250) # Sky    
  
# Keep this to run your code
py5.run_sketch()
