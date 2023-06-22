#!/bin/python3

# Import library code
import py5
from random import randint, seed

level = 1
score = 0

# The draw_obstacle function goes here
def draw_obstacles():
  
  global level
  
  seed(123456789)
  
  if py5.frame_count % py5.width == py5.width - 1 and level < 10:
    level += 1
    print('You reached level', level)
    
  for i in range(6 + level):
    ob_x = randint(0, py5.width) - (py5.frame_count * level)
    ob_y = randint(0, py5.height) 
    ob_x %= py5.width # wrap around
    py5.text('💩', ob_x, ob_y)
    
# The draw_player function goes here
def draw_player():
  
  global score, level
  
  player_x = int(py5.width * 0.2)
  player_y = py5.mouse_y
  
  collide = py5.get(player_x + 50, player_y + 15)
  collide2 = py5.get(player_x + 50, player_y - 15)
  collide3 = py5.get(player_x, player_y + 15)
  collide4 = py5.get(player_x, player_y - 15)
  collide5 = py5.get(player_x - 50, player_y + 15)
  collide6 = py5.get(player_x - 50, player_y - 15)
  
  if player_y > py5.height - 18: # Off the bottom of the screen
    collide = safe
    collide3 = safe
    collide5 = safe
    
  elif player_y < 18: # Off the top of the screen
    collide2 = safe
    collide4 = safe
    collide6 = safe
    
  if collide == safe and collide2 == safe and collide3 == safe and collide4 == safe:
    py5.image(car, player_x, player_y, 100, 31)
    score += level
  else:
    py5.text('💥', player_x, player_y)
    level = 0
    
  
def setup():
  # Setup your animation here
  global car
  
  py5.size(400, 400)
  font = py5.create_font("Monaco", 32)
  py5.text_font(font)
  car = py5.load_image('car.png')
  py5.image_mode(py5.CENTER)
  
  
def draw():
  # Things to do in every frame
  global score, safe, level
  safe = py5.color(128)
  
  if level > 0:
    py5.background(safe)
    py5.fill(255)
    py5.text_size(16)
    py5.text_align(py5.RIGHT, py5.TOP)
    py5.text('Score', py5.width * 0.45, 10, py5.width * 0.5, 20)
    py5.text(str(score), py5.width * 0.45, 25, py5.width * 0.5, 20)
    py5.text_size(20)
    py5.text_align(py5.CENTER, py5.TOP) # position around the centre, top
    draw_obstacles()
    draw_player()
  
py5.run_sketch()
