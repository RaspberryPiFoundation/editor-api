#!/bin/python3

import py5
from random import randint

def setup():
# Put code to run once here
  py5.size(400, 400)
  py5.background(255, 255, 255)


def draw():
# Put code to run every frame here
  py5.fill(255, 0, 255) 
  py5.rect(50, 50, 120, 100) 

  
# Keep this to run your code
py5.run_sketch()
