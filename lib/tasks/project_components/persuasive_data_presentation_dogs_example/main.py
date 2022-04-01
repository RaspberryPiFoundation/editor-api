#!/bin/python3

# Data headings: 0 BreedName, 1 Type,	2 Average Price (American Dollars),	3 Intelligence score,	4 Popularity score US 2017

from pygal import *

with open('dog_breed_characteristics.csv') as f:
  data = f.read()
  lines = data.splitlines()

choice = 0

def main():
  
  choice = input('Analysing Toy dogs. What would you like to see? \n1. Average price, \n2. Popularity, \n3. Intelligence, \nChoice:')
  
  if choice == '1':
    chart = Bar(width=600, height=400)
    chart.title = ' 🐶 Average price of Toy dogs by breed 🐶 '
    for line in lines:
      info = line.split(',')
      BreedName = info[0]
      Type = info[1]
      AvgPrice = info[2]
      if Type == 'Toy':
        chart.add(BreedName, float(AvgPrice))
    chart.render()
    main()
      
  if choice == '2':
    chart = Pie(width=600, height=400)
    chart.title = '🐶 Popularity of Toy dogs by breed 🐶 '
    for line in lines:
      info = line.split(',')
      BreedName = info[0]
      Type = info[1]
      AvgPrice = info[2]
      Intelligence = info[3]
      Popularity = info[4]
      if Type == 'Toy':
        chart.add(BreedName, float(Popularity))
    chart.render()
    main()
    
  if choice == '3':
    chart = Bar(width=600, height=400)
    chart.title = '🐶 Intelligence of Toy dogs by breed 🐶'
    for line in lines:
      info = line.split(',')
      BreedName = info[0]
      Type = info[1]
      AvgPrice = info[2]
      Intelligence = info[3]
      Popularity = info[4]
      if Type == 'Toy':
        chart.add(BreedName, float(Intelligence))
    chart.render()
    main()


main()
