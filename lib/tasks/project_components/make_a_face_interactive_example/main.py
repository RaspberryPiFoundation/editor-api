#!/bin/python3

import py5
from random import randint

def sad(x_middle, y_eye, y_mouth):
  py5.ellipse(x_middle - 50, y_eye - 20, 60, 50) # x, y, width, height
  py5.ellipse(x_middle + 50, y_eye - 20, 60, 50)
  py5.ellipse(x_middle, y_mouth + 30, 100, 65)

def happy(x_middle, y_eye, y_mouth):
  py5.ellipse(x_middle - 50, y_eye + 20, 60, 50) # x, y, width, height
  py5.ellipse(x_middle + 50, y_eye + 20, 60, 50)
  py5.ellipse(x_middle, y_mouth - 30, 100, 65)

def setup():
# Put code to run once here
  py5.size(400, 400) # width and height
  py5.background(0, 0, 0) # move under draw() to reset the drawing every frame
  py5.rect_mode(py5.CENTER)
  py5.no_stroke()

def draw():
# Put code to run every frame here
  mask_width = py5.width / 2
  x_middle = py5.width / 2
  y_eye = 180
  y_mouth = 255
  # draw mask
  py5.fill(255, 255, 255) # white
  py5.rect(200, 150, mask_width, mask_width)
  py5.ellipse(x_middle, 250, mask_width, 140)
  # eyes and mouth
  py5.fill(0) # black
  py5.ellipse(x_middle - 50, y_eye, 60, 50) # x, y, width, height
  py5.ellipse(x_middle + 50 , y_eye, 60, 50)
  py5.ellipse(x_middle, y_mouth, 100, 75)
  # partly cover eyes and mouth
  py5.fill(255)
  if py5.mouse_x > x_middle:
     happy(x_middle, y_eye, y_mouth)
  else:
    sad(x_middle, y_eye, y_mouth)
  # cover top of mask
  py5.fill(0)
  py5.ellipse(x_middle, 60, 250, 90)
  # shade half of the mask
  py5.fill(0, 25)
  py5.rect(300, 200, py5.width/2, py5.height)

def mouse_pressed():
# Put code to run when the mouse is pressed here
  print(py5.mouse_x, py5.mouse_y)

# Keep this to run your code
py5.run_sketch()

