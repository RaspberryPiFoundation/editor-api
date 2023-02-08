#!/bin/python3

import py5
import random

def setup():
  py5.size(400, 400)
  py5.frame_rate(5)
  py5.no_stroke()

def draw():
  py5.background(255)
  
  # Hair and face
  py5.fill(0)
  py5.ellipse(200, 220, 220, 230)
  py5.fill(251, 233, 201)
  py5.ellipse(200, 245, 200, 200)
  py5.fill(0)
  py5.ellipse(245, 185, 120, 130)
  py5.ellipse(155, 185, 120, 130)
  py5.fill(230 , 108, 129)
  for i in range (0, 30):
    py5.fill(random.randint(100, 230) , random.randint(90, 110), random.randint(100, 130))
    py5.ellipse(random.randint(100,300), random.randint(150,210), 20, 20)
  
  # Eyes
  py5.fill(0)
  py5.ellipse(160, 270, 85, 30)
  py5.ellipse(240, 270, 85, 30)
  py5.fill(251, 233, 201)
  py5.ellipse(160, 280, 80, 30)
  py5.ellipse(240, 280, 80, 30)
  py5.fill(0)
  py5.ellipse(160, 290, 30, 30)
  py5.ellipse(240, 290, 30, 30)
  py5.fill(255)
  py5.ellipse(165, 285, 10, 10)
  py5.ellipse(245, 285, 10, 10)
  
  # Mouth
  py5.fill(0)
  py5.rect(185, 320, 30, 5)
  
py5.run_sketch()
