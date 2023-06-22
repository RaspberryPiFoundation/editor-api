#!/bin/python3

import py5
from random import randint

def motif():
  global circle_size
  for i in range(5):
    py5.ellipse(0, 0, circle_size / 5 * (5 - i), circle_size / 5 * (5  - i))

def setup():
  py5.size(400, 400)
  py5.frame_rate(3)
  print('🖌 This art uses lots of circles!')
  
  global circle_size
  
  circle_size = 50
  
def draw():
  
  # Pattern colours
  py5.stroke(40, 35, 100) # blue
  py5.stroke_weight(2) # thick border
  py5.fill(200, 180, 128) # gold
  
  py5.translate(0,0) # start from the top left of the screen
  
  if py5.frame_count <= 16: # creates 16 rows then stops
    for row in range (py5.frame_count): # animates 1 row at a time
      for shape in range (16): # create a row of motifs
        motif()
        py5.translate(circle_size / 2, 0)
      py5.translate(-py5.width, circle_size / 2) # move down to start next row
  
py5.run_sketch()
