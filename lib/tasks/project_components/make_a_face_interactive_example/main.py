#!/bin/python3

from p5 import *
from random import randint

def sad(x_middle, y_eye, y_mouth):
  ellipse(x_middle - 50, y_eye - 20, 60, 50) # x, y, width, height
  ellipse(x_middle + 50, y_eye - 20, 60, 50)
  ellipse(x_middle, y_mouth + 30, 100, 65)

def happy(x_middle, y_eye, y_mouth):
  ellipse(x_middle - 50, y_eye + 20, 60, 50) # x, y, width, height
  ellipse(x_middle + 50, y_eye + 20, 60, 50)
  ellipse(x_middle, y_mouth - 30, 100, 65)

def setup():
# Put code to run once here
  size(400, 400) # width and height
  background(0, 0, 0) # move under draw() to reset the drawing every frame
  rect_mode(CENTER)
  no_stroke()

def draw():
# Put code to run every frame here
  mask_width = width / 2
  x_middle = width / 2
  y_eye = 180
  y_mouth = 255
  # draw mask
  fill(255, 255, 255) # white
  rect(200, 150, mask_width, mask_width)
  ellipse(x_middle, 250, mask_width, 140)
  # eyes and mouth
  fill(0) # black
  ellipse(x_middle - 50, y_eye, 60, 50) # x, y, width, height
  ellipse(x_middle + 50 , y_eye, 60, 50)
  ellipse(x_middle, y_mouth, 100, 75)
  # partly cover eyes and mouth
  fill(255)
  if mouse_x > x_middle:
     happy(x_middle, y_eye, y_mouth)
  else:
    sad(x_middle, y_eye, y_mouth)
  # cover top of mask
  fill(0)
  ellipse(x_middle, 60, 250, 90)
  # shade half of the mask
  fill(0, 25)
  rect(300, 200, width/2, height)

def mouse_pressed():
# Put code to run when the mouse is pressed here
  print(mouse_x, mouse_y)

# Keep this to run your code
run()

