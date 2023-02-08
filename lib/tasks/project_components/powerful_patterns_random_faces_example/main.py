#!/bin/python3

import py5
from random import randint

def draw_motif():
  orange = py5.color(191, 64, 191)
  brown = py5.color(200, 120, 0)
  green = py5.color(100, 155, 0)
  py5.fill(orange)
  py5.ellipse(200, 200, 200, 190)
  py5.fill(0)
  # Eyes
  py5.ellipse(160, 190, 30, 30)
  py5.ellipse(240, 190, 30, 30)
  py5.fill(255)
  py5.ellipse(165, 200, 10, 10)
  py5.ellipse(245, 200, 10, 10)
  # Mouth
  py5.no_fill()
  py5.stroke(255, 255, 255)
  py5.ellipse(150, 250, 30, 30)
  py5.ellipse(250, 250, 30, 30)
  py5.fill(255, 255, 255)
  py5.no_stroke()
  py5.rect(150, 230, 100, 40)
  py5.fill(108, 200, 206)
  py5.rect(152, 235, 96, 30)
  
  
def setup():
  py5.size(400, 400)
  py5.frame_rate(10)
  py5.background(255)
  py5.no_stroke()


def draw():
  py5.push_matrix()
  py5.translate(randint(-50, 350), randint(-50, 350)) # offset by the width of the quarter-size face
  py5.scale(0.25, 0.25) # quarter size paths
  draw_motif()
  py5.pop_matrix()
 

py5.run_sketch()
