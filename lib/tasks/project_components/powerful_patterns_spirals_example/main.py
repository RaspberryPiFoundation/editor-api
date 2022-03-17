#!/bin/python3

from p5 import *
from math import random
from random import randint

def motif():
  fill(randint(0, 255),randint(0, 255) ,randint(0, 255))
  ellipse(0, 0, 25, 25) 
  fill(0, 0, 0)
  ellipse(0, 0, 15, 15) 
  fill(randint(0, 255),randint(0, 255) ,randint(0, 255))
  for i in range(4): # a short row of squares
    rect(i * 5, 0, 5, 5) 

def setup():
  size(400, 400) 
  frame_rate(10) # fast animation
  stroke_weight(2) # thick border
  background(255)
  
def draw():
  translate(200, 200) # start from the centre of the screen
  if frame_count < 150:
    for i in range(frame_count): # animates the pattern
      motif()
      rotate(5) # turns the motif
      translate(i,i) # moves the motif
  
run()
