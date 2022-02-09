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

