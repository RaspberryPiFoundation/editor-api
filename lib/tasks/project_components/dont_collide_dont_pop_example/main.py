#!/bin/python3

# Import library code
import py5
from random import randint, seed

level = 1
score = 0

# The draw_obstacle function goes here
def draw_obstacles():

  global level

  seed(12345678)

  if py5.frame_count % py5.height == py5.height - 1 and level < 5:
    level += 1
    print('You reached level', level)

  for i in range(6 + level):
    ob_x = randint(0, py5.height)
    ob_y = randint(0, py5.height) + (py5.frame_count * level)
    ob_y %= py5.height # wrap around
    py5.text('🌵', ob_x, ob_y)


# The draw_player function goes here
def draw_player():

  global score, level

  player_y = int(py5.height * 0.8)

  collide = py5.get(py5.mouse_x, player_y)
  collide2 = py5.get(py5.mouse_x - 12, player_y + 20)
  collide3 = py5.get(py5.mouse_x + 12, player_y + 20)
  collide4 = py5.get(py5.mouse_x, player_y + 40)

  if py5.mouse_x < py5.width: # off the left of the screen
    collide2 = safe

  if py5.mouse_x > py5.width: # off the right of the screen
    collide3 = safe

  if collide == safe and collide2 == safe and collide3 == safe and collide4 == safe:
    py5.text('🎈', py5.mouse_x, player_y)
    score += level
  else:
    py5.text('💥', py5.mouse_x, player_y)
    level = 0

def setup():
  # Setup your animation here
  py5.size(400, 400)
  font = py5.create_font("Monaco", 32)
  py5.text_font(font) 
  py5.text_size(40)
  py5.text_align(py5.CENTER, py5.TOP) # position around the centre, top

def draw():
  # Things to do in every frame
  global score, safe, level
  safe = py5.color(200, 150, 0)

  if level > 0:
    py5.background(safe)
    py5.fill(255)
    py5.text('Score: ' + str(score), py5.width/2, 20)
    draw_obstacles()
    draw_player()

py5.run_sketch()
