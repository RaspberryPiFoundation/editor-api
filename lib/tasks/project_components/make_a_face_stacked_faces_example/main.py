#!/bin/python3

from p5 import *

def setup():
  size(400, 600)
  background(255, 255, 255)
  no_stroke()
  

def draw():
  blue = Color(92, 204, 206)
  green = Color(149, 212, 122)
  red = Color(239, 62, 91)
  purple = Color(75, 37, 109)
  brown = Color(178, 162, 150)
  grey = Color(201, 201, 201)
  lilac = Color(160, 158, 214)
  
  # Top face background 
  fill(blue)
  rect(50, 100, 300, 200)
  fill(0)
  
  # Top face Hair
  fill(purple)
  gap = 0
  for i in range (0,5):
    triangle(100+gap, 140, 120+gap, 120, 140+gap, 140)
    gap = gap+40

  # Top face Left Eye
  fill(grey)
  rect(80, 190, 100, 50)
  fill(red)
  triangle(190, 250, 70, 150, 180, 160);
  fill(green)
  triangle(190, 250, 60, 160, 180, 170);
  fill(lilac)
  ellipse(160, 200, 30, 30)
  
  # Top face Right Eye
  fill(grey)
  rect(220, 190, 100, 50)
  fill(red)
  triangle(210, 250, 330, 150, 220, 160);
  fill(green)
  triangle(210, 250, 340, 160, 220, 170);
  fill(lilac)
  ellipse(240, 200, 30, 30)
  
  # Top face Mouth
  fill(brown)
  rect(100, 220, 200, 50)
  fill(purple)
  rect(110, 240, 180, 10)

# Bottom face background 
  fill(purple)
  rect(50, 300, 300, 200)
  fill(0)
  
  # Bottom face Hair
  fill(green)
  gap = 0
  for i in range (0,5):
    triangle(100+gap, 340, 120+gap, 320, 140+gap, 340)
    gap = gap+40

  # Bottom face Left Eye
  fill(red)
  rect(80, 390, 100, 50)
  fill(lilac)
  triangle(190, 450, 70, 350, 180, 360);
  fill(brown)
  triangle(190, 450, 60, 360, 180, 370);
  fill(purple)
  ellipse(160, 400, 30, 30)
  
  # Bottom face Right Eye
  fill(red)
  rect(220, 390, 100, 50)
  fill(lilac)
  triangle(210, 450, 330, 350, 220, 360);
  fill(brown)
  triangle(210, 450, 340, 360, 220, 370);
  fill(purple)
  ellipse(240, 400, 30, 30)
  
  # Bottom face Mouth
  fill(green)
  rect(100, 420, 200, 50)
  fill(red)
  rect(110, 440, 180, 10)

run()
