from datetime import datetime
from random import randint

# Emoji variables to use in your project
world = '🌍🌎🌏'
python = 'Python 🐍'
fire = '🔥'

# Emojis to copy and paste into your code 
# 📅🕒🎨🎮🔬🎉🕶️🎲🦄🚀💯⭐💛
# 😃😜❤️📚⚽🎾👟♻️🌳✨🥺🌈

# Useful characters :',()*_/.#

# Function definitions  
def roll_dice():   
    max = input('How many sides?:') # Wait for input from the user    
    print('That\'s a D', max) # Use the number the user entered    
    roll = randint(1, int(max)) # Use max to determine the number of sides the dice has
    print('You rolled a', roll, fire * roll) # Repeat the fire emoji to match the dice roll
  
# Put code to run under here
print('Hello', world) 
print('Welcome to', python) 
print(python, 'is very good at maths!')   
print(230 * 5782 ** 2 / 23781) # Print the result of the sum  
print('The date and time is', datetime.now()) # Print the current date and time

roll_dice() # Call the roll dice function
print('I ❤️ rainbows 🌈')   
print('Unicorns 🦄 make me 😃')   
print('I\'d like to make a story 📖 with', python)
