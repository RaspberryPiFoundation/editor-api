#!/bin/python3

import py5
from random import randint

def motif():
  py5.fill(randint(0, 255),randint(0, 255) ,randint(0, 255))
  py5.ellipse(0, 0, 25, 25) 
  py5.fill(0, 0, 0)
  py5.ellipse(0, 0, 15, 15) 
  py5.fill(randint(0, 255),randint(0, 255) ,randint(0, 255))
  for i in range(4): # a short row of squares
    py5.rect(i * 5, 0, 5, 5) 

def setup():
  py5.size(400, 400)
  py5.frame_rate(10)
  py5.stroke_weight(2) # thick border
  py5.background(255)
  
def draw():
  py5.translate(200, 200) # start from the centre of the screen
  if py5.frame_count < 150:
    for i in range(py5.frame_count): # animates the pattern
      motif()
      py5.rotate(5) # turns the motif
      py5.translate(i,i) # moves the motif
  
py5.run_sketch()
