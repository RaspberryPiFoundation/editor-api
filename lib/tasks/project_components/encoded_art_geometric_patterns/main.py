#!/bin/python3

# PROTOTYPE FOUR

from p5 import *


def size_check(): # Check to see if you've gone off the side of the window

    global startx
    global starty
    if startx >= 400:
        startx = 0
        starty +=80


def shape_1(size, colour): # Draw a diamond

    global startx
    global starty
    x1 = startx 
    y1 = starty + 40 # Move to centre of stripe
    x2 = x1 + (size/2)
    y2 = y1 + (size/2)
    x3 = x1 + size
    y3 = y1
    x4 = x1 + (size/2)
    y4 = y1 - (size/2)
    fill(colour)
    quad(x1, y1, x2, y2, x3, y3, x4, y4)

  
def shape_2(size, colour): # Draw a square

    global startx
    global starty
    x = startx
    y = starty
    fill(colour)   
    rect(x, y, size, size)
  
  
def shape_3(size, colour): # Draw a triangle

    global startx
    global starty
    x1 = startx
    y1 = starty
    x2 = x1 + (size/2)
    y2 = y1 + size
    x3 = x1 + size
    y3 = y1
    fill(colour)   
    triangle(x1, y1, x2, y2, x3, y3)


# Adds a background colour
def draw_background():
  
    # Background colours
    fill(Color(0, 0, 255))
    rect(0, 0, 400, 80)
    fill(Color(0, 127, 127))
    rect(0, 80, 400, 80)
    fill(Color(0, 255, 0))
    rect(0, 160, 400, 80)
    fill(Color(127, 127, 0))
    rect(0, 240, 400, 80)
    fill(Color(255, 0, 0))
    rect(0, 320, 400, 80)

def setup():
  
    size(400, 400)


def draw():
  
    ## -- My colour palette -- 

    # Primary colours

    primary_1 = Color(246,32,100)
    primary_2 = Color(247,0,79)
    primary_3 = Color(234,0,75)
    primary_4 = Color(196,0,63)
    primary_5 = Color(4,0,1)

    # Secondary colours

    secondary_1 = Color(255,198,33)
    secondary_2 = Color(255,190,0)
    secondary_3 = Color(55,190,0)

    # Complementary colours

    complementary_1 = Color(59,63,230)
    complementary_2 = Color(5,9,154)
    complementary_3 = Color(133,246,32)


    code = {
        'a': ['shape 1', 80, primary_1],
        'b': ['shape 2', 50, complementary_3],
        'c': ['shape 3', 75, secondary_1],
        'd': ['shape 2', 80, secondary_1],
        'e': ['shape 1', 20, primary_2],
        'f': ['shape 3', 80, secondary_2],
        'g': ['shape 1', 10, secondary_2],
        'h': ['shape 2', 38, secondary_3],
        'i': ['shape 3', 23, primary_3],
        'j': ['shape 2', 76, secondary_3],
        'k': ['shape 1', 12, complementary_1],
        'l': ['shape 3', 43, complementary_1],
        'm': ['shape 1', 64, complementary_2],
        'n': ['shape 2', 64, complementary_2],
        'o': ['shape 3', 85, primary_4],
        'p': ['shape 2', 10, primary_3],
        'q': ['shape 1', 45, primary_3],
        'r': ['shape 3', 70, primary_4],
        's': ['shape 1', 36, primary_4],
        't': ['shape 2', 74, primary_1],
        'u': ['shape 3', 58, primary_3],
        'v': ['shape 2', 78, primary_1],
        'w': ['shape 1', 24, primary_4],
        'x': ['shape 3', 14, primary_4],
        'y': ['shape 1', 67, secondary_2],
        'z': ['shape 2', 70, complementary_2],
        ' ': ['shape 3', 25, complementary_1],
        
    }

    global name, startx, starty
    startx = 0
    starty = 0


    no_stroke()
    draw_background()

    name = name.lower()  # Change the input to lowercase

    message = []  # Initialise the message list


    for letter in name:
        message.append(code[letter])  # Encode each letter with a shape and add it to a list


    for item in message:
        if item[0] == 'shape 1':
            shape_1(item[1], item[2])  # Draw shape
            startx += item[1]  # Translate next starting x co-ord by width of shape
            size_check()  # Check to see if you've gone off the side of the window

        elif item[0] == 'shape 2':
            shape_2(item[1], item[2])
            startx += item[1]
            size_check()

        elif item[0] == 'shape 3':
            shape_3(item[1], item[2])
            startx += item[1]
            size_check()


print('Enter your name to make some encoded artwork:')
name = input()

run(frame_rate=10)
