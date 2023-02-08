#!/bin/python3

import py5
from grid import *

def setup():
  # Put code to run once here
  py5.size(400, 400) # width and py5.height

def draw():
  # Put code to run every frame here
  py5.background(255, 255, 255) # move under draw() to reset the drawing every frame
  grid() # add a # to the beginning of this line to hide the grid

# Keep this to run your code
py5.run_sketch()
