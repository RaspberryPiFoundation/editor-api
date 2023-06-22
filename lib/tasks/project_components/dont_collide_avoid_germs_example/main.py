#!/bin/python3

import py5
from random import randint, seed

level = 1
score = 0

def safe_player():
  
  global player_y
  
  # Face
  py5.fill(200, 134, 145)
  py5.ellipse(py5.mouse_x, player_y, 60, 60)

  # Eyes
  py5.fill(178, 200, 145)
  py5.ellipse(py5.mouse_x - 10, player_y - 10, 20, 20)
  py5.ellipse(py5.mouse_x + 10, player_y - 10, 20, 20)
  py5.fill(0)
  py5.ellipse(py5.mouse_x - 10, player_y - 10, 10, 10)
  py5.ellipse(py5.mouse_x + 10, player_y - 10, 10, 10)
  py5.fill(255)
  py5.ellipse(py5.mouse_x - 12, player_y - 12, 5, 5)
  py5.ellipse(py5.mouse_x + 12, player_y - 12, 5, 5)
  
  # Mouth
  py5.fill(0)
  py5.ellipse(py5.mouse_x, player_y + 10, 15, 10)
  py5.fill(200, 134, 145)
  py5.ellipse(py5.mouse_x, player_y + 5, 10, 10)

def crashed_player():
  
  global player_y
  
  # Face
  py5.fill(178, 200, 145)
  py5.ellipse(py5.mouse_x, player_y, 60, 60)

  # Eyes
  py5.fill(149, 161, 195)
  py5.ellipse(py5.mouse_x - 10, player_y - 10, 20, 20)
  py5.ellipse(py5.mouse_x + 10, player_y - 10, 20, 20)
  py5.fill(0)
  py5.ellipse(py5.mouse_x - 10, player_y - 10, 10, 10)
  py5.ellipse(py5.mouse_x + 10, player_y - 10, 10, 10)
  py5.fill(255)
  py5.ellipse(py5.mouse_x - 12, player_y - 12, 5, 5)
  py5.ellipse(py5.mouse_x + 12, player_y - 12, 5, 5)
  
  # Mouth
  py5.fill(0)
  py5.ellipse(py5.mouse_x, player_y + 15, 15, 10)
  py5.fill(178, 200, 145)
  py5.ellipse(py5.mouse_x, player_y + 20, 10, 10)
  
def draw_player():
  
  global player_y, safe, score, level
  
  player_y = int(py5.height * 0.8)
  
  collide = py5.get(py5.mouse_x, player_y)
  collide2 = py5.get(py5.mouse_x, player_y + 30)
  collide3 = py5.get(py5.mouse_x + 30, player_y)
  collide4 = py5.get(py5.mouse_x, player_y - 30)
  
  if py5.mouse_x < py5.width: # off the left of the screen
    collide2 = safe
  
  if py5.mouse_x > py5.width: # off the right of the screen
    collide3 = safe
    
  #print(collide, collide2, collide3, collide4)
    
  if collide == safe and collide2 == safe and collide3 == safe and collide4 == safe:
    safe_player()
    score += level
  else: # Collided
    crashed_player()
    level = 0
  
def draw_obstacles():
  
  global level
  
  seed(41143644)
  
  if py5.frame_count & py5.height == py5.height - 1 and level < 5:
    level += 1
    print('You reached level', level)
  
  for i in range(9 + level):
    ob_x = randint(0, py5.width)
    ob_y = randint(0, py5.height) + py5.frame_count
    ob_y %= py5.height
    py5.text('🦠', ob_x, ob_y)

def setup():
# Put code to run once here
  py5.size(400, 400) # width and height
  py5.no_stroke()
  font = py5.create_font("Monaco", 32)
  py5.text_font(font)
  py5.text_size(40)
  py5.text_align(py5.CENTER, py5.TOP)

def draw():
# Put code to run every frame here
  global safe, score, level
  
  safe = py5.color(149, 161, 195)
  
  if level > 0:
    py5.background(safe)
    py5.fill(145, 134, 126)
    py5.text('Score: ' + str(score), py5.width/2, 20)
    draw_obstacles()
    draw_player()
  
# Keep this to run your code
py5.run_sketch()
