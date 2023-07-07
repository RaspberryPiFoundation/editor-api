#!/bin/python3
from pygal import Bar
from frequency import english

# Set up data structures 
alphabet = list(' abcdefghijklmnopqrstuvwxyz ') #  List from a string
code = {}

# Create the atbash code by reversing the alphabet
def create_code():
  backwards = list(reversed(alphabet))  # Reverses a list

  for i in range(len(alphabet)):  # Gets the length of a list
    code[alphabet[i]] = backwards[i]  # Populate the code dictionary with a letter of the alphabet and its encoded letter

  # print(code)

# Calculate the frequency of all letters in a piece of text
def frequency(text):
  text = list(text.lower())  # Convert the message to lower case and make it a list

  freq = {}  # Create a dictionary of every letter, with a count of 0
  for letter in alphabet:
    freq[letter] = 0

  total_letters = len(text)  # Count the letters in the message
  
  for letter in text:
    if letter in freq:
      freq[letter] += 1

  for letter in freq:
    freq[letter] = freq[letter] / total_letters * 100  # Convert from counts to percentages

  return freq
    
# Make frequency chart
def make_chart(text, language):
  chart = Bar(width=800, height=400, title='Frequency analysis', x_labels = list(text.keys()))
  chart.add('Target message', list(text.values()))  # Label the frequency data for the encoded message
  chart.add('Language', list(language.values()))  # Label the frequency data for the language
  
  chart.render()
    
# Encode/decode a piece of text — atbash is symetrical
def atbash(text):
  text = text.lower()  # Converts text to lower case
  output = ''
  
  for letter in text: 
    if letter in code: 
      output += code[letter]  # Populates output with the encoded/decoded message using the dictionary
  
  return output  # Return the encoded/decoded message

# Fetch and return text from a file
def get_text(filename):
  with open(filename) as f:
    text = f.read().replace('\n','')  # Need to strip the newline characters

  return text

# Create a text-based menu system  
def menu():
  choice = ''  # Start with a wrong answer for choice.
  
  while choice != 'c' and choice != 'f':  # Keep asking the user for the right answer
    choice = input('Please enter c to encode/decode text, or f to perform frequency analysis: ')

  if choice == 'c':
    print('Running your message through the cypher…')
    message = get_text('longer.txt')  # Take input from a file
    code = atbash(message)
    print(code)

  elif choice == 'f':
    print('Analysing message…')
    message = get_text('longer.txt')
    message_freq = frequency(message)
    # print(message_freq)
    lang_freq = english  # Import the English frequency dictionary
    make_chart(message_freq, lang_freq)  # Call the function to make a chart
      
# Start up
def main():
  create_code()
  # print(atbash('Test'))
  menu()

main()
