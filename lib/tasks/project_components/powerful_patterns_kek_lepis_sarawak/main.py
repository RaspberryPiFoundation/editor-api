#!/bin/python3

import py5
from time import *

# Based on the amazing Malaysian geometric cake art: Kek lapis Sarawak

def quadrant():

  # Choose some gorgeous colours for the cake layers
  turquoise = py5.color(64, 224, 208)
  gold = py5.color(255, 215, 0)
  tomato = py5.color(255, 99, 71)
  
  # Jam sticks the layers together
  jam = py5.color(255, 165, 0) 
  py5.stroke(jam)
  py5.stroke_weight(2) # Change the number to change the amount of jam

  # Nine layers of cake, repeating the 3 colours 3 times
  for i in range(3):
    start_y = i * 60 # height of 3 blocks of cake
    py5.fill(turquoise)
    py5.rect(0, start_y, 180, 20)
    py5.fill(gold)
    py5.rect(0, start_y + 20, 180, 20)
    py5.fill(tomato)
    py5.rect(0, start_y + 40, 180, 20)

  
def outer():

  # Thehe cake is wrapped in an outer layer
  yellowgreen = py5.color(154, 205, 50) 
  
  py5.no_fill() # Don't cover up the cake quadrants!
  py5.stroke(yellowgreen)
  py5.stroke_weight(20)
  py5.rect(10, 10, 380, 380, 20) 


def setup():
  py5.size(400, 400) # make the cake square
  py5.frame_rate(5)
  py5.background(255, 255, 255, 0) # transparent background


def draw():
  
  # Define a quarter turn so our code is easy to read
  quarter = py5.radians(90)

  py5.translate(200, 200) # start from the center
  
  # Make the bottom right quarter of the cake then rotate for the other quarters

  if py5.frame_count <= 4: # draw up to 4 quadrants
    for i in range(py5.frame_count): 
      quadrant()
      py5.rotate(quarter)

  if py5.frame_count == 5: # add the outer layer
    py5.translate(-200, -200) # back to the top corner
    outer() # outer layer
    

py5.run_sketch()
