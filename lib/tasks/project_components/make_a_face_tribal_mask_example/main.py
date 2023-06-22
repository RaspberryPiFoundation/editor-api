#!/bin/python3

import py5

def setup():
  py5.size(400, 400)
  py5.no_stroke()
  

def draw():
  py5.background(255)
  py5.fill(74, 50, 47)
  py5.ellipse(200, 200, 200, 190)
  py5.fill(0)
  
  # Eyes
  py5.fill(175, 65, 0)
  py5.ellipse(160, 180, 60, 60)
  py5.ellipse(240, 180, 60, 60)
  py5.fill(0)
  py5.ellipse(160, 180, 30, 30)
  py5.ellipse(240, 180, 30, 30)
  py5.fill(255)
  py5.ellipse(165, 175, 10, 10)
  py5.ellipse(245, 175, 10, 10)
  
  # Nose
  py5.fill(108, 75, 73)
  py5.triangle(185, 240, 200, 160, 215, 240)
  
  # Face markings
  gap = 0
  for i in range (0,6):
    py5.fill(0, 240, 209)
    py5.ellipse(150+gap, 140, 10, 10)
    py5.fill(108, 75, 73)
    py5.ellipse(150+gap, 220, 10, 10)
    gap = gap+20
    
  # Mouth
  py5.fill(185, 85, 0)
  py5.ellipse(190, 260, 30, 30)
  py5.ellipse(210, 260, 30, 30)
  py5.ellipse(195, 275, 20, 20)
  py5.ellipse(205, 275, 20, 20)
  py5.fill(0)
  py5.rect(185, 265, 30, 3)

  # Hair
  py5.fill(246, 170, 19)
  py5.triangle(200, 130, 220, 60, 240, 60)
  py5.triangle(200, 130, 180, 60, 160, 60)

py5.run_sketch()

