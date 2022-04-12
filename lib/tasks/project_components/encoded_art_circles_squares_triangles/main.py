#!/bin/python3

from p5 import *
from random import randint, seed

def shape_1(size, colour): # Each shape can have a different size and colour based on the parameters
  
  # Draws a circle with a thick outline
  
  x = randint(0, 400)
  y = randint(0, 400)
  fill(colour)   
  ellipse(x, y, size, size)
  fill(Color(251, 168, 57))
  ellipse(x, y, size - 20, size - 20)
  
def shape_2(size, colour):
  
  # Draws a rectangle
  
  x = randint(0, 400)
  y = randint(0, 400)
  fill(colour)   
  rect(x, y, size, size)

def shape_3(size, colour): # Size isn't used for this function but two parameters must be passed

  # Draws a triangle
  
  x = randint(0, 400)
  y = randint(0, 400)
  fill(colour)   
  triangle(x, y, x+50, y-100, x+100, y)

# Set up the background
def draw_background():
  
  # Background colour
  fill(Color(5, 55, 93))
  rect(0, 0, 400, 400)

def setup():

  size(400, 400)

  
def draw():
  
  ## -- My colour palette -- ## Using primary, secondary and complementary colours
  
  # Primary colours
  
  primary_1 = Color(14, 92, 151)
  primary_2 = Color(77, 135, 179)
  primary_3 = Color(45,111, 161)
  primary_4 = Color(8, 71, 120)
  primary_5 = Color(5, 55, 93)
  
  # Secondary colours
  
  secondary_1 = Color(29, 29, 164)
  secondary_2 = Color(92, 92, 191)
  secondary_3 = Color(60, 60, 176)
  
  # Complementary colours
  
  complementary_1 = Color(234, 137, 8)
  complementary_2 = Color(255, 188, 99)
  complementary_3 = Color(251, 168, 57)
  
  # Dictionary of letters and their encoded shape with size and colour options
  
  code = {
    'a': ['shape 1', 150, primary_1],
    'b': ['shape 3', 50, complementary_3],
    'c': ['shape 3', 75, secondary_1],
    'd': ['shape 2', 80, secondary_1],
    'e': ['shape 1', 20, primary_2],
    'f': ['shape 2', 80, secondary_2],
    'g': ['shape 1', 10, secondary_2],
    'h': ['shape 2', 300, secondary_3],
    'i': ['shape 1', 200, primary_3],
    'j': ['shape 3', 90, secondary_3],
    'k': ['shape 1', 12, complementary_1],
    'l': ['shape 2', 43, complementary_1],
    'm': ['shape 1', 93, complementary_2],
    'n': ['shape 2', 64, complementary_2],
    'o': ['shape 1', 85, primary_4],
    'p': ['shape 2', 10, primary_3],
    'q': ['shape 1', 45, primary_3],
    'r': ['shape 1', 70, primary_4],
    's': ['shape 1', 36, primary_4],
    't': ['shape 3', 74, primary_1],
    'u': ['shape 1', 58, primary_3],
    'v': ['shape 2', 78, primary_1],
    'w': ['shape 1', 24, primary_4],
    'x': ['shape 2', 14, primary_4],
    'y': ['shape 3', 67, secondary_2],
    'z': ['shape 2', 70, complementary_2],
    ' ': ['shape 1', 25, complementary_1],
      
  }
  
  global name
  
  seed(10) # Generate the same random numbers each time
  no_stroke()
  draw_background()
  
  name = name.lower() # Change the input to lowercase
  
  message = [] # Initialise the message list

  for letter in name:
    message.append(code[letter]) # Encode each letter with a shape and add it to a list
  
  for item in message: # For each letter, draw the chosen shape
    if item[0] == 'shape 1':
      shape_1(item[1], item[2])
    elif item[0] == 'shape 2':
      shape_2(item[1], item[2])
    elif item[0] == 'shape 3':
      shape_3(item[1], item[2])

print('Enter your name to make some encoded artwork:')
name = input()

run(frame_rate=10)
