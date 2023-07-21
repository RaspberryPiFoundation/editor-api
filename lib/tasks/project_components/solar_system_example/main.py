#!/bin/python3
from p5 import *
from make_planet import make_planet

def draw_sun():
    fill(255, 255, 0)  # Yellow
    ellipse(width / 2 , height / 2, 100, 100)


# draw_orbits function
def draw_orbits():
    no_fill()
    stroke(255)  # Make it white

    ellipse(width / 2, height / 2, mercury['orbit'], mercury['orbit'])
    ellipse(width / 2, height / 2, venus['orbit'], venus['orbit'])
    ellipse(width / 2, height / 2, earth['orbit'], earth['orbit'])

# draw_planets function
def draw_planets():

    colour = mercury['colour']
    orbit = mercury['orbit']
    size = mercury['size']
    speed = mercury['speed']

    make_planet(
        colour, 
        orbit, 
        size, 
        speed
    )

    colour = venus['colour']
    orbit = venus['orbit']
    size = venus['size']
    speed = venus['speed']

    make_planet(
        colour, 
        orbit, 
        size, 
        speed
    )

    colour = earth['colour']
    orbit = earth['orbit']
    size = earth['size']
    speed = earth['speed']

    make_planet(
        colour, 
        orbit, 
        size, 
        speed
    )


# load_planets function
def load_planets():
    global mercury, venus, earth

    mercury = {
        'name': 'Mercury',
        'colour': Color(165, 42, 42),
        'size': 15,
        'orbit': 150,
        'speed': 1,
        'info': 'The smallest, and fastest, planet.'
    }
  
    with open('planets.csv') as f:
        data = f.read()
        lines = data.splitlines()
  
    planet = lines[2].split(',')  # Split Venus' data
    venus = { 
        'name': planet[0],
        'colour': Color(int(planet[1]), int(planet[2]), int(planet[3])),
        'size': int(planet[4]),  # int() for whole numbers
        'orbit': int(planet[5]),
        'speed': float(planet[6]),  # float() for decimals
        'info': planet[7]
    }

    planet = lines[3].split(',') 
    earth = { 
        'name': planet[0],
        'colour': Color(int(planet[1]), int(planet[2]), int(planet[3])),
        'size': int(planet[4]), 
        'orbit': int(planet[5]),
        'speed': float(planet[6]), 
        'info': planet[7]
    }

  
def setup():
    # Put code to run once here
    size(400, 400)
    load_planets()
  
def draw():
    # Put code to run every frame here
    background(0)
    no_stroke()
    draw_sun()
    draw_orbits()
    draw_planets()

def mouse_pressed():
    # Put code to run when the mouse is pressed here
    pixel_colour = Color(get(mouse_x, mouse_y)).hex  # Here the RGB value is converted to Hex so it can be used in a string comparison later

    if pixel_colour == mercury['colour'].hex:
        print(mercury['name'])
        print(mercury['info'])
    elif pixel_colour == venus['colour'].hex:
        print(venus['name'])
        print(venus['info'])
    elif pixel_colour == earth['colour'].hex:
        print(earth['name'])
        print(earth['info'])
  
  
run(frame_rate=60)
