#!/bin/python3

from p5 import *

def setup():
    size(400, 400)
    no_stroke()
  

def draw():
    background(255)
    orange = Color(255, 165, 0)
    brown = Color(200, 120, 0)
    green = Color(100, 155, 0)
    fill(orange)
    ellipse(200, 200, 200, 190)
    fill(0)
    # Eyes
    ellipse(160, 220, 30, 30)
    ellipse(240, 220, 30, 30)
    fill(255)
    ellipse(165, 215, 10, 10)
    ellipse(245, 215, 10, 10)
    # Mouth
    fill(0)
    ellipse(200, 240, 15, 15)
    fill(orange)
    ellipse(200, 235, 15, 15)
    # Highlights
    fill(255, 70)
    ellipse(170, 150, 35, 35)
    ellipse(150, 160, 25, 25)
    # stalk
    fill(brown)
    triangle(200, 130, 220, 60, 240, 60)
    fill(green)
    translate(180, 85)
    rotate(radians(45))
    ellipse(0, 0, 75, 35)

run()
