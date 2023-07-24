#!/bin/python3
from p5 import *
from make_planet import make_planet

def draw_sun():
    fill(255, 255, 0)  # Yellow
    ellipse(width / 2 , height / 2, 100, 100)


# draw_orbits function


# draw_planets function


# load_planets function

  
  
def setup():
    # Put code to run once here
    size(400, 400)

  
def draw():
    # Put code to run every frame here
    background(0)
    no_stroke()
    draw_sun()


def mouse_pressed():
    # Put code to run when the mouse is pressed here
    pixel_colour = Color(get(mouse_x, mouse_y)).hex  # Here the RGB value is converted to Hex so it can be used in a string comparison later

  
run(frame_rate=60)

