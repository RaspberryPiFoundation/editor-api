#!/bin/python3
from p5 import *


def preload():
    global iss, be_flag, ca_flag, fr_flag, uk_flag, gm_flag, it_flag, jp_flag
    global ne_flag, ru_flag, us_flag
    iss = load_image('iss.jpg')
    be_flag = load_image('be.jpg')
    ca_flag = load_image('ca.jpg')
    fr_flag = load_image('fr.jpg')
    uk_flag = load_image('gb.jpg')
    gm_flag = load_image('gm.jpg')
    it_flag = load_image('it.jpg')
    jp_flag = load_image('jp.jpg')
    ne_flag = load_image('ne.jpg')
    ru_flag = load_image('ru.jpg')
    us_flag = load_image('us.jpg')


def setup():
    size(400, 400)
    load_data('iss-expedition-data.csv')
    
    date = (expedition_date(chosen_expedition)) 
    astronauts = (expedition_astronauts(chosen_expedition))
    countries = (expedition_countries(chosen_expedition))
    
    print('Expedition: ' + chosen_expedition)
    print('Mission launch date: '+ date + '\n')
    print('Astronauts:')
    for astronaut in astronauts:
        print(astronaut)
    
    print('\nRepresenting countries:')
    for country in countries:
        print(country)

def load_data(file_name):
  
    # Create a dictionary for each siting based on the data in the csv file
    
    global expeditions
    
    expeditions = []
    
    with open(file_name) as f:
        for line in f:
            info = line.strip('\n')
            info = info.split(',')
            expedition_dict = {
                'expedition number': info[0],
                'representing country': info[1],
                'astronaut': info[2],
                'mission launch date': info[3]
            }
            expeditions.append(expedition_dict) # Store dictionary in a list
    
def expedition_date(number):
  
    for expedition in expeditions:
        if expedition['expedition number'] == number:
            date = expedition['mission launch date']
    
    return date
  
def expedition_astronauts(number):
  
    astronauts = []
    
    for expedition in expeditions:
        if expedition['expedition number'] == number:
            astronaut = expedition['astronaut']
            astronauts.append(astronaut)
    
    return astronauts

def expedition_countries(number):
  
    countries = []
    
    for expedition in expeditions:
        if expedition['expedition number'] == number:
            country = expedition['representing country']
            if country not in countries:
                countries.append(country)
    
    return countries

def draw():
  
    f_width = 60
    f_height = 35
    
    flag_positions = [[45, 145], [130, 60], [210, 310], [300, 220], [300, 70]]
    
    country_dict = {
        'United States of America' : us_flag,
        'Russia' : ru_flag,
        'Netherlands' : ne_flag,
        'Japan' : jp_flag,
        'Italy' : it_flag,
        'Germany' : gm_flag,
        'United Kingdom' : uk_flag,
        'France' : fr_flag,
        'Canada' : ca_flag,
        'Belgium' : be_flag
    }
    
    image(iss, 0, 0, width, height)
    
    countries = expedition_countries(chosen_expedition)
    
    num_countries = len(countries)
    
    for x in range(num_countries):
        flag = countries[x]
        flag_image = country_dict[flag]
        image(flag_image, flag_positions[x][0], flag_positions[x][1], f_width, f_height)
    
print('Choose an ISS expedition. Enter a number from 1 to 65:')
chosen_expedition = input()
  
run()
