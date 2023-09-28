#!/bin/python3

# PROTOTYPE THREE - DRAWING COMPLEX SHAPES TO APPEAR AT RANDOM

from p5 import *
from random import randint, seed

def shape_1(fruit_colour): # Draws a Kawaii fruit at a random position in the chosen colour

    # Randomly generate the x and y positions

    x = randint(0, 400) 
    y = randint(0, 400)

    brown = Color(200, 120, 0)
    green = Color(100, 155, 0)  

    # Instructions to draw the fruit, some maths required to make each object appear where it should

    # Body
    fill(fruit_colour)
    ellipse(x, y, 100, 95)
    fill(0)
    # Eyes
    ellipse(x-20, y+10, 15, 15)
    ellipse(x+20, y+10, 15, 15)
    fill(255)
    ellipse(x-18, y+8, 5, 5)
    ellipse(x+22, y+8, 5, 5)
    # Mouth
    fill(0)
    ellipse(x, y+20, 10, 10)
    fill(fruit_colour)
    ellipse(x, y+18, 10, 10)
    # Highlights
    fill(255, 70)
    ellipse(x-10, y-20, 20, 20)
    ellipse(x-20, y-15, 15, 15)
    # Stalk
    fill(brown)
    triangle(x-5, y-35, x+5, y-75, x+20, y-75);
    fill(green)
    push_matrix()
    translate(x-20, y-55)
    rotate(radians(45))
    ellipse(0, 0, 40, 15)
    pop_matrix()
 
def shape_2(fruit_colour): # Draws a lime fruit in a chosen colour at a random position

    x = randint(0, 400)
    y = randint(0, 400)

    brown = Color(200, 120, 0)
    green = Color(100, 155, 0)

    # Instructions for drawing the lime

    # Body
    fill(fruit_colour)
    ellipse(x, y, 110, 150)
    ellipse(x, y+70, 30, 30)
    ellipse(x, y-70, 30, 30)
    fill(0)
    # Eyes
    ellipse(x-20, y, 15, 15)
    ellipse(x+20, y, 15, 15)
    fill(255)
    ellipse(x-18, y-3, 5, 5)
    ellipse(x+22, y-3, 5, 5)
    # Mouth
    fill(0)
    ellipse(x, y+12, 10, 10)
    fill(fruit_colour)
    ellipse(x, y+10, 10, 10)
    # Highlights
    fill(255, 70)
    ellipse(x-10, y-40, 20, 20)
    ellipse(x-20, y-35, 15, 15)
    # Stalk
    fill(brown)
    triangle(x-15, y-65, x-5, y-100, x+10, y-100);
    fill(green)
    push_matrix()
    translate(x-30, y-80)
    rotate(radians(45))
    ellipse(0, 0, 40, 15)
    pop_matrix()

def shape_3(fruit_colour): # Draws a cherry fruit in a chosen colour and a random position
  
    x = randint(0, 400)
    y = randint(0, 400)

    brown = Color(200, 120, 0)
    green = Color(100, 155, 0)

    # Instructions for drawing the cherry

    # Body
    fill(fruit_colour)
    ellipse(x, y, 70, 70)
    # Highlights
    fill(255, 70)
    ellipse(x, y, 60, 60)
    fill(fruit_colour)
    ellipse(x+3, y+3, 60, 60)
    # Eyes
    fill(0)
    ellipse(x-15, y, 15, 15)
    ellipse(x+15, y, 15, 15)
    fill(255)
    ellipse(x-13, y-3, 5, 5)
    ellipse(x+18, y-3, 5, 5)
    # Mouth
    fill(0)
    ellipse(x, y+12, 10, 10)
    fill(fruit_colour)
    ellipse(x, y+10, 10, 10)
    # Stalk
    fill(brown)
    triangle(x-5, y-20, x+5, y-80, x+10, y-80);
    # Leaves
    fill(green)
    push_matrix()
    translate(x-10, y-35)
    rotate(radians(45))
    ellipse(0, 0, 30, 15)
    pop_matrix()
    fill(Color(15, 140, 12))
    push_matrix()
    translate(x-10, y-35)
    rotate(radians(110))
    ellipse(-10, -15, 30, 15)
    pop_matrix()

# Adds a background colour
def draw_background():
  
  # Background colour
  fill(Color(255, 255, 255))
  rect(0, 0, 400, 400)

def setup():

    size(400, 400)

  
def draw():
  
    # Colour palette for fruit drawings

    orange = Color(255, 165, 0)
    lime = Color(134, 229, 77)
    cherry = Color(213, 17, 70)
    red = Color(229, 86, 77)
    blue = Color(85, 182, 225)
    purple = Color(165, 131, 245)
    yellow = Color(243, 247, 32)
    r = randint(0,255)
    g = randint(0,255)
    b = randint(0,255)
    suprise_me = Color(r, g, b) # Generates a random colour

  
  # Dictionary of letters and their encoded shape, a colour is selected from the palette
  
    code = {
    'a': ['shape 3', cherry],
    'b': ['shape 1', orange],
    'c': ['shape 1', lime],
    'd': ['shape 1', blue],
    'e': ['shape 3', red],
    'f': ['shape 1', suprise_me],
    'g': ['shape 1', purple],
    'h': ['shape 1', purple],
    'i': ['shape 3', purple],
    'j': ['shape 1', red],
    'k': ['shape 2', purple],
    'l': ['shape 1', red],
    'm': ['shape 1', purple],
    'n': ['shape 1', purple],
    'o': ['shape 1', red],
    'p': ['shape 2', lime],
    'q': ['shape 1', blue],
    'r': ['shape 3', suprise_me],
    's': ['shape 1', orange],
    't': ['shape 2', yellow],
    'u': ['shape 1', yellow],
    'v': ['shape 1', yellow],
    'w': ['shape 1', red],
    'x': ['shape 2', suprise_me],
    'y': ['shape 1', blue],
    'z': ['shape 1', lime],
    ' ': ['shape 2', cherry],
    }

    global name

    seed(10) # Generate the same random numbers each time
    no_stroke()
    draw_background()

    name = name.lower() # Change the input to lowercase

    message = [] # Initialise the message list

    for letter in name:
        message.append(code[letter]) # Encode each letter with a shape and add it to a list

    for item in message:  # Draw either shape 1, 2 or 3 with the selected colour option
        if item[0] == 'shape 1':
            shape_1(item[1])
        elif item[0] == 'shape 2':
            shape_2(item[1])
        elif item[0] == 'shape 3':
            shape_3(item[1])

print('Enter your name to make some encoded artwork:')
name = input()

run(frame_rate=10)
