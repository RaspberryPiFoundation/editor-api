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

