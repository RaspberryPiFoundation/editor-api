#!/bin/python3

# Import library code
from p5 import *
from math import *
from random import randint

# The mouse_pressed function goes here
def mouse_pressed():
  if hit_color == outer:  
    print('You hit the outer circle, 50 points!') #Like functions, 'if' statements are indented
  elif hit_color == inner:    
    print('You hit the inner circle, 200 points!')   
  elif hit_color == bullseye:    
    print('You hit the bullseye, 500 points!')   
  else:   
    print('You missed! No points!')    
    
# The shoot_arrow function goes here
def shoot_arrow():
  global hit_color 
  arrow_x = randint(100, 300)
  arrow_y = randint(100, 300)
  hit_color = get(arrow_x, arrow_y)
  ellipse(arrow_x, arrow_y, 15, 15)

def setup():
# Setup your game here
  size(400, 400) # width and height
  frame_rate(2)


def draw():
# Things to do in every frame
  global outer, inner, bullseye
  sky = color(92, 204, 206) # Red = 92, Green = 204, Blue = 206
  grass = color(149, 212, 122)
  wood = color(145, 96, 51)
  outer = color(0, 120, 180) 
  inner = color(210, 60, 60)
  bullseye = color(220, 200, 0)

  no_stroke()
  fill(sky)
  rect(0, 0, 400, 250)
  fill(grass)
  rect(0, 250, 400, 150)
  
  fill(wood)
  triangle(150, 350, 200, 150, 250, 350)
  fill(outer)
  ellipse(200, 200, 170, 170)
  fill(inner)   
  ellipse(200, 200, 110, 110) #Inner circle   
  fill(bullseye)   
  ellipse(200, 200, 30, 30) #Bullseye 
  
  fill(wood)
  shoot_arrow()
# Keep this to run your code
run()
