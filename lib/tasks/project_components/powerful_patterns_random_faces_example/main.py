#!/bin/python3

from p5 import *
from random import randint

def draw_motif():
  orange = Color(191, 64, 191)
  brown = Color(200, 120, 0)
  green = Color(100, 155, 0)
  fill(orange)
  ellipse(200, 200, 200, 190)
  fill(0)
  # Eyes
  ellipse(160, 190, 30, 30)
  ellipse(240, 190, 30, 30)
  fill(255)
  ellipse(165, 200, 10, 10)
  ellipse(245, 200, 10, 10)
  # Mouth
  no_fill()
  stroke(255, 255, 255)
  ellipse(150, 250, 30, 30)
  ellipse(250, 250, 30, 30)
  fill(255, 255, 255)
  no_stroke()
  rect(150, 230, 100, 40)
  fill(108, 200, 206)
  rect(152, 235, 96, 30)
  
  
def setup():
  size(400, 400)
  background(255)
  no_stroke()


def draw():
  push_matrix()
  translate(randint(-50, 350), randint(-50, 350)) # offset by the width of the quarter-size face
  scale(0.25, 0.25) # quarter size paths
  draw_motif()
  pop_matrix()
 

run(frame_rate=10)
