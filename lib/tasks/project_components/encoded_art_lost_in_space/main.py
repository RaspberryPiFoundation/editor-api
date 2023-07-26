#!/bin/python3

from p5 import *
from random import randint, seed

# Draw a planet based on chosen size and colour
def shape_1(size, colour): 
  
    x = randint(0, 400)
    y = randint(0, 400)
    if colour == 'purple':
        image(purple_planet, x, y, size, size)
    elif colour == 'orange':
        image(orange_planet, x, y, size, size)
    elif colour == 'green':
        image(green_planet, x, y, size, size)
    elif colour == 'grey':
        image(grey_moon, x, y, size, size)
  
# Draw a space object based on chosen object and size
def shape_2(size, object): 
  
    x = randint(0, 400)
    y = randint(0, 400)
    if object == 'satellite':
        image(satellite, x, y, size, size)
    elif object == 'astronaut':
        image(astronaut, x, y, size, size)
    elif object == 'astropi':
        image(astropi, x, y, size, size)

# Draw a star based on chosen colour and size
def shape_3(size, colour): 
  
    x = randint(0, 400)
    y = randint(0, 400)
    if colour == 'yellow':
        image(yellow_star, x, y, size, size)
    elif colour == 'pink':
        image(pink_star, x, y, size, size)
    elif colour == 'blue':
        image(blue_star, x, y, size, size)

# Adds a background colour
def draw_background():
  
    # Background colour
    fill(Color(0, 0, 0))
    rect(0, 0, 400, 400)

def setup():
  
    # Allow other functions to access the images
    global purple_planet, orange_planet, green_planet, astropi, astronaut, satellite 
    global grey_moon, yellow_star, pink_star, blue_star

    size(400, 400)

    # Load the images needed into variables
    purple_planet = load_image('purple_planet.png')
    orange_planet = load_image('orange_planet.png')
    green_planet = load_image('green_planet.png')
    astropi = load_image('astropi.png')
    astronaut = load_image('astronaut.png')
    satellite = load_image('satellite.png')
    grey_moon = load_image('moon.png')
    yellow_star = load_image('yellow_star.png')
    pink_star = load_image('pink_star.png')
    blue_star = load_image('blue_star.png')

  
def draw():
  
    # Dictionary of letters and their encoded shape
    code = {
        'a': ['shape 3', 150, 'pink'],
        'b': ['shape 3', 50, 'yellow'],
        'c': ['shape 2', 75, 'astronaut'],
        'd': ['shape 2', 80, 'astropi'],
        'e': ['shape 1', 20, 'orange'],
        'f': ['shape 2', 80, 'satellite'],
        'g': ['shape 1', 10, 'purple'],
        'h': ['shape 1', 300, 'green'],
        'i': ['shape 1', 200, 'orange'],
        'j': ['shape 2', 90, 'astropi'],
        'k': ['shape 1', 12, 'purple'],
        'l': ['shape 3', 43, 'pink'],
        'm': ['shape 1', 93, 'orange'],
        'n': ['shape 1', 64, 'green'],
        'o': ['shape 3', 85, 'blue'],
        'p': ['shape 2', 10, 'astropi'],
        'q': ['shape 3', 45, 'blue'],
        'r': ['shape 1', 70, 'purple'],
        's': ['shape 1', 36, 'orange'],
        't': ['shape 2', 74, 'astronaut'],
        'u': ['shape 1', 58, 'grey'],
        'v': ['shape 3', 78, 'yellow'],
        'w': ['shape 1', 24, 'orange'],
        'x': ['shape 2', 14, 'astropi'],
        'y': ['shape 1', 67, 'purple'],
        'z': ['shape 2', 70, 'astropi'],
        ' ': ['shape 3', 25, 'pink'],
    }

    global name

    seed(10) # Generate the same random numbers each time
    no_stroke()
    draw_background()

    name = name.lower() # Change the input to lowercase

    message = [] # Initialise the message list

    for letter in name:
        message.append(code[letter]) # Encode each letter with a shape and add it to a list

    for item in message: # For each letter in the message, draw a shape
        if item[0] == 'shape 1':
            shape_1(item[1], item[2])
        elif item[0] == 'shape 2':
            shape_2(item[1], item[2])
        elif item[0] == 'shape 3':
            shape_3(item[1], item[2])

print('Enter your name to make some encoded artwork:')
name = input()

run(frame_rate=10)
