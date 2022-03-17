#!/bin/python3

# Import library code
from p5 import *
from random import randint

# Setup global variables
screen_size = 400
rocket_y = screen_size # start at the bottom
burn = 100 # how much fuel is burned in each frame
orbit_radius = 250
orbit_y = screen_size - orbit_radius

# The draw_rocket function goes here
def draw_rocket():

  global rocket_y, fuel, burn
  
  if fuel >= burn and rocket_y > orbit_y: # still flying
    rocket_y -= 1 # move the rocket
    fuel -= burn # burn fuel
    print('Fuel left: ', fuel)
  
    no_stroke() # Turn off the stroke
  
    for i in range(25): # draw 25 burning exhaust ellipses
      fill(255, 255 - i*10, 0) # yellow
      ellipse(width/2, rocket_y + i, 8, 3) # i increases each time the loop repeats
    
    fill(200, 200, 200, 100) # transparent grey
    for i in range(20): # draw 20 random smoke ellipses
      ellipse(width/2 + randint(-5, 5), rocket_y + randint(20, 50), randint(5, 10), randint(5, 10))
  
  if fuel < burn and rocket_y > orbit_y: # No more fuel and not in orbit
    tint(255, 0, 0) # Failure
  elif fuel < 1000 and rocket_y <= orbit_y:
    tint(0, 255, 0) # Success
  elif fuel >= 1000 and rocket_y <= orbit_y: 
    tint(255, 200, 0) # Too much fuel
  
  image(rocket, width/2, rocket_y, 64, 64)
  no_tint()
  

# The draw_background function goes here
def draw_background():
  background(0) # short for background(0, 0, 0) - black 
  image(planet, width/2, height, 300, 300) # draw the image
  
  no_fill() # Turn off any fill
  stroke(255) # Set a white stroke
  stroke_weight(2)
  ellipse(width/2, height, orbit_radius*2, orbit_radius*2)
  

def setup():
  # Setup your animation here
  size(screen_size, screen_size)
  image_mode(CENTER)
  global planet, rocket
  planet = load_image('planet.png') # your chosen planet
  rocket = load_image('rocket.png')


def draw():
  # Things to do in every frame
  draw_background()  
  draw_rocket()
  

fuel = int(input('How many kilograms of fuel do you want to use?'))
run()
