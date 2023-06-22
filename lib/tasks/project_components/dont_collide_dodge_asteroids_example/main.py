#!/bin/python3

# Import library code
import py5
from random import randint, seed

level = 1
score = 0
lives = 3
invun = 0

# The draw_obstacle function goes here
def draw_obstacles():
  
  global level
  
  seed(random_seed)
  
  if py5.frame_count % py5.height == py5.height - 1 and level < 8:
    level += 1
    print('You reached level', level)
    
  for i in range(6 + level):
    ob_x = randint(0, py5.width)
    ob_y = randint(0, py5.height) + (py5.frame_count * level)
    ob_y %= py5.height # wrap around
    py5.push_matrix()
    py5.translate(ob_x, ob_y)
    py5.rotate(py5.degrees(randint(1, 359)+py5.frame_count / 1000))
    py5.image(rock, 0, 0, randint(18,24), randint(18,24))
    py5.pop_matrix()

    
# The draw_player function goes here
def draw_player():
  
  global score, level, lives, invun
  
  player_y = int(py5.height * 0.8)
  player_x = py5.mouse_x
  
  collide = py5.get(player_x, player_y)
  collide2 = py5.get(player_x - 18, player_y + 17)
  collide3 = py5.get(player_x + 18, player_y + 17)
  collide4 = py5.get(player_x, player_y + 25)
  
  if player_x < py5.width: # off the left of the screen
    collide2 = safe
  
  if player_x > py5.width: # off the right of the screen
    collide3 = safe
    
  if (collide == safe and collide2 == safe and collide3 == safe and collide4 == safe) or invun > 0:
    if lives == 0 and py5.frame_count % 12 == 0:
      py5.tint(200, 0, 0)
    
    py5.image(rocket, player_x, player_y + 25, 64, 64)
    score += level
    invun -= 1
    py5.no_tint()
    
    if invun > 0:
      py5.stroke(220)
      py5.fill(220, 220, 220, 60)
      py5.ellipse(player_x, player_y + 18, 47, 47)
      
  elif lives > 0:
    lives -= 1
    invun = 50
    py5.tint(200, 0, 0)
    py5.image(rocket, player_x, player_y + 25, 64, 64)
    py5.no_tint()
    score += level
  else:
    py5.text('💥', player_x + 10, player_y + 5)
    level = 0
    

def display_score():
  global level
  
  py5.fill(255)
  py5.text_size(16)
  py5.text_align(py5.RIGHT, py5.TOP)
  py5.text('Score', py5.width * 0.45, 10, py5.width * 0.5, 20)
  py5.text(str(score), py5.width * 0.45, 25, py5.width * 0.5, 20)
  
  if score > 10000:
    level = 0
    print('🎉🎉 You win! 🎉🎉')

  
def display_lives():
  py5.fill(255)
  py5.text_size(16)
  py5.text_align(py5.LEFT, py5.TOP)
  py5.text('Lives', py5.width * 0.05, 10, 30, 20)
  
  for i in range(lives):
    py5.image(rocket, py5.width * 0.05 + i * 25, 40, 20, 20)
  

def setup():
  # Setup your animation here
  global rocket, rock, random_seed
 
  py5.size(400, 400)
  font = py5.create_font("Monaco", 32)
  py5.text_font(font)
  py5.text_size(40)
  py5.text_align(py5.CENTER, py5.TOP) # position around the centre, top
  
  rocket = py5.load_image('rocket.png')
  rock = py5.load_image('moon.png')
  random_seed = randint(0, 1000000)
  
def draw():
  # Things to do in every frame
  global score, safe, level
  safe = py5.color(0)
  
  if level > 0:
    py5.background(safe) 
    py5.fill(255)
    py5.image_mode(py5.CENTER)
    draw_obstacles()
    draw_player()
    display_score()
    display_lives()
  
py5.run_sketch()
