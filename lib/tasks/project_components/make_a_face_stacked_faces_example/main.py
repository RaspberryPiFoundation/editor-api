#!/bin/python3

import py5

def setup():
  py5.size(400, 600)
  py5.background(255, 255, 255)
  py5.no_stroke()
  

def draw():
  blue = py5.color(92, 204, 206)
  green = py5.color(149, 212, 122)
  red = py5.color(239, 62, 91)
  purple = py5.color(75, 37, 109)
  brown = py5.color(178, 162, 150)
  grey = py5.color(201, 201, 201)
  lilac = py5.color(160, 158, 214)
  
  # Top face background 
  py5.fill(blue)
  py5.rect(50, 100, 300, 200)
  py5.fill(0)
  
  # Top face Hair
  py5.fill(purple)
  gap = 0
  for i in range (0,5):
    py5.triangle(100+gap, 140, 120+gap, 120, 140+gap, 140)
    gap = gap+40

  # Top face Left Eye
  py5.fill(grey)
  py5.rect(80, 190, 100, 50)
  py5.fill(red)
  py5.triangle(190, 250, 70, 150, 180, 160);
  py5.fill(green)
  py5.triangle(190, 250, 60, 160, 180, 170);
  py5.fill(lilac)
  py5.ellipse(160, 200, 30, 30)
  
  # Top face Right Eye
  py5.fill(grey)
  py5.rect(220, 190, 100, 50)
  py5.fill(red)
  py5.triangle(210, 250, 330, 150, 220, 160);
  py5.fill(green)
  py5.triangle(210, 250, 340, 160, 220, 170);
  py5.fill(lilac)
  py5.ellipse(240, 200, 30, 30)
  
  # Top face Mouth
  py5.fill(brown)
  py5.rect(100, 220, 200, 50)
  py5.fill(purple)
  py5.rect(110, 240, 180, 10)

# Bottom face background 
  py5.fill(purple)
  py5.rect(50, 300, 300, 200)
  py5.fill(0)
  
  # Bottom face Hair
  py5.fill(green)
  gap = 0
  for i in range (0,5):
    py5.triangle(100+gap, 340, 120+gap, 320, 140+gap, 340)
    gap = gap+40

  # Bottom face Left Eye
  py5.fill(red)
  py5.rect(80, 390, 100, 50)
  py5.fill(lilac)
  py5.triangle(190, 450, 70, 350, 180, 360);
  py5.fill(brown)
  py5.triangle(190, 450, 60, 360, 180, 370);
  py5.fill(purple)
  py5.ellipse(160, 400, 30, 30)
  
  # Bottom face Right Eye
  py5.fill(red)
  py5.rect(220, 390, 100, 50)
  py5.fill(lilac)
  py5.triangle(210, 450, 330, 350, 220, 360);
  py5.fill(brown)
  py5.triangle(210, 450, 340, 360, 220, 370);
  py5.fill(purple)
  py5.ellipse(240, 400, 30, 30)
  
  # Bottom face Mouth
  py5.fill(green)
  py5.rect(100, 420, 200, 50)
  py5.fill(red)
  py5.rect(110, 440, 180, 10)

py5.run_sketch()
