from datetime import datetime
from random import randint

# Emoji variables to use in your project
world = '🌍🌎🌏'
python = 'Python 🐍'

# Emojis to copy and paste into your code 
# 📅🕒🎨🎮🔬🎉🕶️🎲🦄🚀💯⭐💛
# 😃😜❤️📚⚽🎾👟♻️🌳🔥✨🥺🌈

# Useful characters :',()*_/.#

# Function definitions  
def roll_dice(): 
    max = input('How many sides?: ') # Wait for input from the user    
    print('Rolling a', max, 'sided dice ...') # Use the number the user entered  
    roll = randint(1, int(max)) # Generate a random number between 1 and 6    
    print('You rolled a', roll) # Print the value of the roll variable  
    print('🔥' * roll) # Repeat the fire emoji to match the dice roll
  
# Put code to run under here
print('Hello', world) 
print('Welcome to', python) 
print(python, 'is very good at maths!')   
print(230 * 5782 ** 2 / 23781) # Print the result of the sum  
print('The 📅 🕒 is', datetime.now()) # Print with emojis 

roll_dice() # Call the roll dice function
print('I ❤️ ...')   
print('... makes me 😃')   
print('I\'d like to make ... with', python)  
