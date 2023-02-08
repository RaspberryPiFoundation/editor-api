#!/bin/python3

import py5

def setup():
  py5.size(400, 400)
  py5.no_stroke()
  

def draw():
  py5.background(255)
  orange = py5.color(255, 165, 0)
  brown = py5.color(200, 120, 0)
  green = py5.color(100, 155, 0)
  py5.fill(orange)
  py5.ellipse(200, 200, 200, 190)
  py5.fill(0)
  # Eyes
  py5.ellipse(160, 220, 30, 30)
  py5.ellipse(240, 220, 30, 30)
  py5.fill(255)
  py5.ellipse(165, 215, 10, 10)
  py5.ellipse(245, 215, 10, 10)
  # Mouth
  py5.fill(0)
  py5.ellipse(200, 240, 15, 15)
  py5.fill(orange)
  py5.ellipse(200, 235, 15, 15)
  # Highlights
  py5.fill(255, 70)
  py5.ellipse(170, 150, 35, 35)
  py5.ellipse(150, 160, 25, 25)
  # stalk
  py5.fill(brown)
  py5.triangle(200, 130, 220, 60, 240, 60);
  py5.fill(green)
  py5.translate(180, 85)
  py5.rotate(py5.radians(45))
  py5.ellipse(0, 0, 75, 35)

py5.run_sketch()

