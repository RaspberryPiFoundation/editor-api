#!/bin/python3

from p5 import *
from random import randint, seed

level = 1
score = 0

def safe_player():
    global player_y
    
    # Face
    fill(200, 134, 145)
    ellipse(mouse_x, player_y, 60, 60)
  
    # Eyes
    fill(178, 200, 145)
    ellipse(mouse_x - 10, player_y - 10, 20, 20)
    ellipse(mouse_x + 10, player_y - 10, 20, 20)
    fill(0)
    ellipse(mouse_x - 10, player_y - 10, 10, 10)
    ellipse(mouse_x + 10, player_y - 10, 10, 10)
    fill(255)
    ellipse(mouse_x - 12, player_y - 12, 5, 5)
    ellipse(mouse_x + 12, player_y - 12, 5, 5)
    
    # Mouth
    fill(0)
    ellipse(mouse_x, player_y + 10, 15, 10)
    fill(200, 134, 145)
    ellipse(mouse_x, player_y + 5, 10, 10)

def crashed_player():
    global player_y
    
    # Face
    fill(178, 200, 145)
    ellipse(mouse_x, player_y, 60, 60)
  
    # Eyes
    fill(149, 161, 195)
    ellipse(mouse_x - 10, player_y - 10, 20, 20)
    ellipse(mouse_x + 10, player_y - 10, 20, 20)
    fill(0)
    ellipse(mouse_x - 10, player_y - 10, 10, 10)
    ellipse(mouse_x + 10, player_y - 10, 10, 10)
    fill(255)
    ellipse(mouse_x - 12, player_y - 12, 5, 5)
    ellipse(mouse_x + 12, player_y - 12, 5, 5)
    
    # Mouth
    fill(0)
    ellipse(mouse_x, player_y + 15, 15, 10)
    fill(178, 200, 145)
    ellipse(mouse_x, player_y + 20, 10, 10)
  
def draw_player():
  
    global player_y, safe, score, level
    
    player_y = int(height * 0.8)
    
    collide = get(mouse_x, player_y).hex
    collide2 = get(mouse_x, player_y + 30).hex
    collide3 = get(mouse_x + 30, player_y).hex
    collide4 = get(mouse_x, player_y - 30).hex
    
    if mouse_x < width:  # off the left of the screen
        collide2 = safe.hex
    
    if mouse_x > width:  # off the right of the screen
        collide3 = safe.hex
      
    #print(collide, collide2, collide3, collide4)
      
    if collide == safe.hex and collide2 == safe.hex and collide3 == safe.hex and collide4 == safe.hex:
        safe_player()
        score += level
    else:  # Collided
        crashed_player()
        level = 0
  
def draw_obstacles():
    global level
    
    seed(41143644)
    
    if frame_count & height == height - 1 and level < 5:
        level += 1
        print('You reached level', level)
    
    for i in range(9 + level):
        ob_x = randint(0, width)
        ob_y = randint(0, height) + frame_count
        ob_y %= height
        text('🦠', ob_x, ob_y)

def setup():
    # Put code to run once here
    size(400, 400)  # width and height
    no_stroke()
    text_size(40)
    text_align(CENTER, TOP)

def draw():
    # Put code to run every frame here
    global safe, score, level
  
    safe = Color(149, 161, 195)
  
    if level > 0:
        background(safe)
        fill(145, 134, 126)
        text('Score: ' + str(score), width/2, 20)
        draw_obstacles()
        draw_player()
  
# Keep this to run your code
run()
