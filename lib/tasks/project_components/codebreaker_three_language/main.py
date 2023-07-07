##!/bin/python3 
from pygal import Bar
from frequency import english, french, spanish

# Set up data structures 
alphabet = list(' abcdefghijklmnopqrstuvwxyz ') # List from a string
code = {}

# Create the atbash code by reversing the alphabet
def create_code():
  backwards = list(reversed(alphabet)) # Reversing a list
  
  for i in range(len(alphabet)): # Getting length of a list
    code[alphabet[i]] = backwards[i] # Populate the code dictionary with a letter of the alphabet and its encoded letter
  
  #print(code)

# Calculate the frequency of all letters in a piece of text
def frequency(text):
  text = list(text.lower()) # Lowercase the message and make it a list
  
  freq = {} # Create a dict of every letter, with a count of 0
  for letter in alphabet:
    freq[letter] = 0
  
  total_letters = len(text) # Count the letters in the message
  
  for letter in text:
    if letter in freq: 
      freq[letter] += 1
  
  for letter in freq: # Convert from counts to percentages
    freq[letter] = freq[letter] / total_letters * 100
  
  return freq

# Make frequency chart
def make_chart(text, language):
  chart = Bar(width = 800, title='Frequency analysis', x_labels = list(text.keys()))
  chart.add('Target message', list(text.values())) # First explicit use of values
  chart.add('Language', list(language.values()))
  
  chart.render()


# Encode/decode a piece of text — atbash is symetrical
def atbash(text):
  text = text.lower() # Converting text to lowercase
  output = ''
  
  for letter in text: 
    if letter in code: 
      output += code[letter] # Populate output with the encoded/decoded message using the dictionary
  
  return output # Return the encoded/decoded message


# Fetch and return text from a file
def get_text(filename):
    with open(filename) as f:
      text = f.read().replace('\n','') # Need to strip the newline characters
    
    return text

# Create a text-based menu system  
def menu():
  choice = '' # Start with a wrong answer for choice.
  
  while choice != 'c' and choice != 'f' and choice != 'm': # Keep asking the user for the right answer
    choice = input('Please enter c to encode/decode a text file, f to perform frequency analysis in three languages, or m to enter your own message to encode:' )
  
  if choice == 'c':
    print('Running your message through the cypher…')
    message = get_text('longer.txt') # Take input from a file 
    code = atbash(message)
    print(code)

  elif choice == 'f':
    print('Analysing message…')
    message = get_text('longer.txt') # Take input from the same file. We have a 'longer.txt' or similar containing cyphertext we know to perform reasonably well for frequency analysis
    message_freq = frequency(message) # Get the frequency of the letters in the message, as %
    # print(message_freq)
    language = input('Which language is your message in? \n1. English \n2. French \n3. Spanish')
    
    if language == '1':
      lang_freq = english # Import the English frequency dictionary
    elif language == '2':
      lang_freq = french
    elif language == '3':
      lang_freq = spanish
      
    make_chart(message_freq, lang_freq) # Call the function to make a chart
    
  elif choice == 'm':
    message = input('What text would you like to encode?')
    code = atbash(message)
    print(code)
    
# Start up
def main():
  create_code()
  menu()

  
main()
