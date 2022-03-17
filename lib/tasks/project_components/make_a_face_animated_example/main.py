#!/bin/python3

from processing import *
import random

def setup():
  size(400, 400)
  noStroke()
  frameRate(5)
  

def draw():
  background(255)
  
  # Hair and face
  fill(0)
  ellipse(200, 220, 220, 230)
  fill(251, 233, 201)
  ellipse(200, 245, 200, 200)
  fill(0)
  ellipse(245, 185, 120, 130)
  ellipse(155, 185, 120, 130)
  fill(230 , 108, 129)
  for i in range (0, 30):
    fill(random.randint(100, 230) , random.randint(90, 110), random.randint(100, 130))
    ellipse(random.randint(100,300), random.randint(150,210), 20, 20)
  
  # Eyes
  fill(0)
  ellipse(160, 270, 85, 30)
  ellipse(240, 270, 85, 30)
  fill(251, 233, 201)
  ellipse(160, 280, 80, 30)
  ellipse(240, 280, 80, 30)
  fill(0)
  ellipse(160, 290, 30, 30)
  ellipse(240, 290, 30, 30)
  fill(255)
  ellipse(165, 285, 10, 10)
  ellipse(245, 285, 10, 10)
  
  # Mouth
  fill(0)
  rect(185, 320, 30, 5)
  
run()
