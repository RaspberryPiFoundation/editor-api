#!/bin/python3

# Import library code
from p5 import *
from random import randint, seed

level = 1
score = 0

# The draw_obstacle function goes here
def draw_obstacles():
    global level
  
    seed(12345678)
  
    if frame_count % height == height - 1 and level < 5:
        level += 1
        print('You reached level', level)
  
    for i in range(6 + level):
        ob_x = randint(0, height)
        ob_y = randint(0, height) + (frame_count * level)
        ob_y %= height  # wrap around
        text('🌵', ob_x, ob_y)


# The draw_player function goes here
def draw_player():
    global score, level
  
    player_y = int(height * 0.8)
  
    collide = get(mouse_x, player_y).hex
    collide2 = get(mouse_x - 12, player_y + 20).hex
    collide3 = get(mouse_x + 12, player_y + 20).hex
    collide4 = get(mouse_x, player_y + 40).hex
  
    if mouse_x < width:  # off the left of the screen
        collide2 = safe.hex
  
    if mouse_x > width:  # off the right of the screen
        collide3 = safe.hex
  
    if collide == safe.hex and collide2 == safe.hex and collide3 == safe.hex and collide4 == safe.hex:
        text('🎈', mouse_x, player_y)
        score += level
    else:
        text('💥', mouse_x, player_y)
        level = 0


def setup():
    # Setup your animation here
    size(400, 400)
    text_size(40)
    text_align(CENTER, TOP)  # position around the centre, top


def draw():
    # Things to do in every frame
    global score, safe, level
    safe = Color(200, 150, 0)

    if level > 0:
        background(safe)
        fill(255)
        text('Score: ' + str(score), width/2, 20)
        draw_obstacles()
        draw_player()

run()
