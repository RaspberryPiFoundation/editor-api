#!/bin/python3
from p5 import *
from regions import get_region_coords

# Put code to run once here
def setup():
    pass

# Put code to run every frame here
def draw():
    pass

# Put code to run when the mouse is pressed here
def mouse_pressed():
    pixel_colour = Color(get(mouse_x, mouse_y)).hex
  

run()
