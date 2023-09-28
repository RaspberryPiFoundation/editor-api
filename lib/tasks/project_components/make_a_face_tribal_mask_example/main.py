#!/bin/python3

from p5 import *

def setup():
    size(400, 400)
    no_stroke()
  

def draw():
    background(255)
    fill(74, 50, 47)
    ellipse(200, 200, 200, 190)
    fill(0)
    
    # Eyes
    fill(175, 65, 0)
    ellipse(160, 180, 60, 60)
    ellipse(240, 180, 60, 60)
    fill(0)
    ellipse(160, 180, 30, 30)
    ellipse(240, 180, 30, 30)
    fill(255)
    ellipse(165, 175, 10, 10)
    ellipse(245, 175, 10, 10)
    
    # Nose
    fill(108, 75, 73)
    triangle(185, 240, 200, 160, 215, 240)
    
    # Face markings
    gap = 0
    for i in range (0,6):
        fill(0, 240, 209)
        ellipse(150+gap, 140, 10, 10)
        fill(108, 75, 73)
        ellipse(150+gap, 220, 10, 10)
        gap = gap+20
      
    # Mouth
    fill(185, 85, 0)
    ellipse(190, 260, 30, 30)
    ellipse(210, 260, 30, 30)
    ellipse(195, 275, 20, 20)
    ellipse(205, 275, 20, 20)
    fill(0)
    rect(185, 265, 30, 3)
  
    # Hair
    fill(246, 170, 19)
    triangle(200, 130, 220, 60, 240, 60)
    triangle(200, 130, 180, 60, 160, 60)

run()

