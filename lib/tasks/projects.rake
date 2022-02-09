namespace :projects do
  desc "Import starter projects"
  task create_starter: :environment do

    Project.find_by(identifier: "python-hello-starter")&.destroy
    project = Project.new(identifier: "python-hello-starter", name: "Hello 🌍🌎🌏")
    project.components << Component.new(name: "main", extension: "py", content: main_content)
    project.components << Component.new(name: "emoji", extension: "py", content: emoji_content)
    project.components << Component.new(name: "noemoji", extension: "py", content: no_emoji_content)
    project.save

    Project.find_by(identifier: "python-emoji-example")&.destroy
    project = Project.new(identifier: "python-emoji-example", name: "Emoji Example Project")
    project.components << Component.new(name: "main", extension: "py", content: main_runner_content)
    project.components << Component.new(name: "emoji", extension: "py", content: emoji_content)
    project.components << Component.new(name: "noemoji", extension: "py", content: no_emoji_content)
    project.save

    Project.find_by(identifier: "python-archery-example")&.destroy
    project = Project.new(identifier: "python-archery-example", name: "Target Practice Example")
    project.components << Component.new(name: "main", extension: "py", content: archery_content)
    project.save

    Project.find_by(identifier: "python-archery-starter")&.destroy
    project = Project.new(identifier: "python-archery-starter", name: "Target Practice")
    project.components << Component.new(name: "main", extension: "py", content: archery_starter)
    project.save
  end
end

def main_content
  main_content = <<-END
#!/bin/python3

from emoji import * 
from datetime import *
from random import randint

# Put function definitions under here

# Useful characters :',()*_/.#

# Put code to run under here

    END
end

def emoji_content
  emoji_content = <<-END
# Emoji variables to use in your project

world = '🌍🌎🌏'
python = '🐍⌨️'
sums = '✖️➗➖➕'
calendar = '📅'
clock = '🕒'
projects = '🎨🎮🔬'
fun = '🎉🕶️'
dice = '🎲'
unicorn = '🦄'
space = '🚀'
happy = '😃'
silly = '😜'
heart = '❤️'
games = '🎮'
books = '📚'
sports = '⚽🎾👟'
green = '♻️'
nature = '🌳'
fire = '🔥'
sparkles = '✨'
plead = '🥺'
hundred = '💯'
star = '⭐'
yellow_heart = '💛'
rainbow = '🌈'
  END
end

def no_emoji_content
  no_emoji_content = <<-END
# Add ASCII art alternatives
# Before emoji we used emoticons made from characters

world = 'o'
python = '~~~-<'
happy = ':-)'
heart = '♡' # or '<3'
star = '☆'
sparkles = '✺'
silly = ';)'
sums = '+-*/'
hundred = '100!'
plead = '◔◔'
fire = '/\\'
books = '≣'
rainbow = '⌒'
dice = '⊡'
clock = '◷'
calendar = '▦'

  END
end

def main_runner_content

  main_runner_content = <<-END
#!/bin/python3

from emoji import * 
from datetime import *
from random import randint

# Put function definitions under here

def roll_dice():
  print(python, 'can make a', dice)
  max = input('How many sides?') # get input from the user
  print('That is a D', max) # use the number the user entered
  roll = randint(1, int(max)) # generate a random number 
  print('You rolled a', roll) # print the value of the roll variable
  print(fire * roll) # repeat the fire text roll times

def hobbies():
  hobby = input('What do you like?')
  print('That sounds', fun)
  print('You could make a', python, 'project about', hobby)

# Put code to run under here
# Useful characters :',()*_/.#

print('Hello', world)
print('Welcome to', python)

input() # wait for the user to tap Enter

print(python, 'is very good at', sums)
print(230 * 5782 ** 2 / 23781)

input()

now = datetime.now() # get the current date and time
print('The', calendar, clock, 'is', now) # print with emoji 

input()

roll_dice() # Call the roll_dice function

input()

hobbies() # Call the hobbies function
END
end

def archery_content
  archery_content = <<-END
#!/bin/python3

# Import library code
from p5 import *
from math import *
from random import randint

# The mouse_pressed function goes here
def mouse_pressed():
  if hit_color == outer:  
    print('You hit the outer circle, 50 points!') #Like functions, 'if' statements are indented
  elif hit_color == inner:    
    print('You hit the inner circle, 200 points!')   
  elif hit_color == bullseye:    
    print('You hit the bullseye, 500 points!')   
  else:   
    print('You missed! No points!')    
    
# The shoot_arrow function goes here
def shoot_arrow():
  global hit_color 
  arrow_x = randint(100, 300)
  arrow_y = randint(100, 300)
  hit_color = get(arrow_x, arrow_y)
  ellipse(arrow_x, arrow_y, 15, 15)

def setup():
# Setup your game here
  size(400, 400) # width and height
  frame_rate(2)


def draw():
# Things to do in every frame
  global outer, inner, bullseye
  sky = color(92, 204, 206) # Red = 92, Green = 204, Blue = 206
  grass = color(149, 212, 122)
  wood = color(145, 96, 51)
  outer = color(0, 120, 180) 
  inner = color(210, 60, 60)
  bullseye = color(220, 200, 0)

  no_stroke()
  fill(sky)
  rect(0, 0, 400, 250)
  fill(grass)
  rect(0, 250, 400, 150)
  
  fill(wood)
  triangle(150, 350, 200, 150, 250, 350)
  fill(outer)
  ellipse(200, 200, 170, 170)
  fill(inner)   
  ellipse(200, 200, 110, 110) #Inner circle   
  fill(bullseye)   
  ellipse(200, 200, 30, 30) #Bullseye 
  
  fill(wood)
  shoot_arrow()
# Keep this to run your code
run()

  END
end

def archery_starter 
  archery_starter = <<-END
#!/bin/python3

# Import library code
from p5 import *
from math import *
from random import randint

# The mouse_pressed function goes here

# The shoot_arrow function goes here

def setup():
# Setup your game here
  size(400, 400) # width and height
  frame_rate(2)


def draw():
# Things to do in every frame
  sky = color(92, 204, 206) # Red = 92, Green = 204, Blue = 206
  grass = color(149, 212, 122)
  wood = color(145, 96, 51)
  outer = color(0, 120, 180) 

  
# Keep this to run your code
run()

  END
end
