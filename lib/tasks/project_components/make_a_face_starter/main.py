#!/bin/python3

from p5 import *
from grid import *

def setup():
  # Put code to run once here
  size(400, 400) # width and height

def draw():
  # Put code to run every frame here
  background(255, 255, 255) # move under draw() to reset the drawing every frame
  grid() # add a # to the beginning of this line to hide the grid

# Keep this to run your code
run()
