namespace :projects do
  desc "Import starter projects"
  task create_starter: :environment do

    Project.find_by(identifier: "python-hello-starter")&.destroy
    project = Project.new(identifier: "python-hello-starter")
    project.components << Component.new(name: "main", extension: "py", content: main_content)
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

print('Hello ', world)
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
