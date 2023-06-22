#!/bin/python3

# Import library code
import py5
from random import randint, seed

speed = 1
score = 0

# The draw_background function goes here
def draw_obstacles():
  
  global speed
  
  seed(12345678)
  
  if py5.frame_count % py5.height == py5.height - 1 and speed < 5:
    speed += 1
    print('You reached level', speed)
    
  for i in range(6):
    ob_x = randint(0, py5.height)
    ob_y = randint(0, py5.height) + (py5.frame_count * speed)
    ob_y %= py5.height # wrap around
    py5.no_stroke()
    py5.fill(0,255,0)
    py5.triangle(ob_x + 20, ob_y + 20, ob_x + 10, ob_y + 40, ob_x + 30, ob_y + 40)
    py5.triangle(ob_x + 20, ob_y + 30, ob_x + 5, ob_y + 55, ob_x + 35, ob_y + 55)
    py5.triangle(ob_x + 20, ob_y + 40, ob_x + 0, ob_y + 70, ob_x + 40, ob_y + 70)
    py5.fill(150,100,100)
    py5.rect(ob_x + 15, ob_y + 70, 10, 10)
    
# The draw_player function goes here
def draw_player():
  
  global score, speed, skiing, crashed
  
  player_y = int(py5.height * 0.8)
  
  py5.fill(safe)

  collide = py5.get(py5.mouse_x, player_y)
  
  if collide == safe:
    py5.image(skiing, py5.mouse_x, player_y, 30, 30)
    score += speed
  else:
    py5.image(crashed, py5.mouse_x, player_y, 30, 30)
    speed = 0
    
  
def setup():
  
  global skiing, crashed
  
  # Setup your animation here
  py5.size(400, 400)
  py5.text_size(40)
  py5.text_align(py5.CENTER, py5.TOP) # position around the centre
  skiing = py5.load_image('skiing.png')
  crashed = py5.load_image('fallenover.png')
  
def draw():
  # Things to do in every frame
  global score, safe, speed, skiing, crashed
  safe = py5.color(255)

  if speed > 0:
    py5.background(safe) 
    py5.fill(0)
    py5.text('Score: ' + str(score), py5.width/2, 20)
    draw_obstacles()
    draw_player()
  
py5.run_sketch()
