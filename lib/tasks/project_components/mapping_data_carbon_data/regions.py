#!/bin/python3
from math import radians, pi, log, tan

regions = {
  'Abkhazia': {
    'name': 'Abkhazia',
    'capital': 'Sukhumi',
    'latitude': 43.001525,
    'longitude': 41.023415
  },
  'Afghanistan': {
    'name': 'Afghanistan',
    'capital': 'Kabul',
    'latitude': 34.575503,
    'longitude': 69.240073
  },
  'Aland Islands': {
    'name': 'Aland Islands',
    'capital': 'Mariehamn',
    'latitude': 60.1,
    'longitude': 19.933333
  },
  'Albania': {
    'name': 'Albania',
    'capital': 'Tirana',
    'latitude': 41.327546,
    'longitude': 19.818698
  },
  'Algeria': {
    'name': 'Algeria',
    'capital': 'Algiers',
    'latitude': 36.752887,
    'longitude': 3.042048
  },
  'American Samoa': {
    'name': 'American Samoa',
    'capital': 'Pago Pago',
    'latitude': -14.275632,
    'longitude': -170.702036
  },
  'Andorra': {
    'name': 'Andorra',
    'capital': 'Andorra la Vella',
    'latitude': 42.506317,
    'longitude': 1.521835
  },
  'Angola': {
    'name': 'Angola',
    'capital': 'Luanda',
    'latitude': -8.839988,
    'longitude': 13.289437
  },
  'Anguilla': {
    'name': 'Anguilla',
    'capital': 'The Valley',
    'latitude': 18.214813,
    'longitude': -63.057441
  },
  'Antarctica': {
    'name': 'Antarctica',
    'capital': 'South Pole',
    'latitude': -90.0,
    'longitude': 0.0
  },
  'Antigua and Barbuda': {
    'name': 'Antigua and Barbuda',
    'capital': "St. John's",
    'latitude': 17.12741,
    'longitude': -61.846772
  },
  'Argentina': {
    'name': 'Argentina',
    'capital': 'Buenos Aires',
    'latitude': -34.603684,
    'longitude': -58.381559
  },
  'Armenia': {
    'name': 'Armenia',
    'capital': 'Yerevan',
    'latitude': 40.179186,
    'longitude': 44.499103
  },
  'Aruba': {
    'name': 'Aruba',
    'capital': 'Oranjestad',
    'latitude': 12.509204,
    'longitude': -70.008631
  },
  'Australia': {
    'name': 'Australia',
    'capital': 'Canberra',
    'latitude': -35.282,
    'longitude': 149.128684
  },
  'Austria': {
    'name': 'Austria',
    'capital': 'Vienna',
    'latitude': 48.208174,
    'longitude': 16.373819
  },
  'Azerbaijan': {
    'name': 'Azerbaijan',
    'capital': 'Baku',
    'latitude': 40.409262,
    'longitude': 49.867092
  },
  'Bahamas': {
    'name': 'Bahamas',
    'capital': 'Nassau',
    'latitude': 25.047984,
    'longitude': -77.355413
  },
  'Bahrain': {
    'name': 'Bahrain',
    'capital': 'Manama',
    'latitude': 26.228516,
    'longitude': 50.58605
  },
  'Bangladesh': {
    'name': 'Bangladesh',
    'capital': 'Dhaka',
    'latitude': 23.810332,
    'longitude': 90.412518
  },
  'Barbados': {
    'name': 'Barbados',
    'capital': 'Bridgetown',
    'latitude': 13.113222,
    'longitude': -59.598809
  },
  'Belarus': {
    'name': 'Belarus',
    'capital': 'Minsk',
    'latitude': 53.90454,
    'longitude': 27.561524
  },
  'Belgium': {
    'name': 'Belgium',
    'capital': 'Brussels',
    'latitude': 50.85034,
    'longitude': 4.35171
  },
  'Belize': {
    'name': 'Belize',
    'capital': 'Belmopan',
    'latitude': 17.251011,
    'longitude': -88.75902
  },
  'Benin': {
    'name': 'Benin',
    'capital': 'Porto-Novo',
    'latitude': 6.496857,
    'longitude': 2.628852
  },
  'Bermuda': {
    'name': 'Bermuda',
    'capital': 'Hamilton',
    'latitude': 32.294816,
    'longitude': -64.781375
  },
  'Bhutan': {
    'name': 'Bhutan',
    'capital': 'Thimphu',
    'latitude': 27.472792,
    'longitude': 89.639286
  },
  'Bolivia': {
    'name': 'Bolivia',
    'capital': 'La Paz',
    'latitude': -16.489689,
    'longitude': -68.119294
  },
  'Bosnia and Herzegovina': {
    'name': 'Bosnia and Herzegovina',
    'capital': 'Sarajevo',
    'latitude': 43.856259,
    'longitude': 18.413076
  },
  'Botswana': {
    'name': 'Botswana',
    'capital': 'Gaborone',
    'latitude': -24.628208,
    'longitude': 25.923147
  },
  'Bouvet Island': {
    'name': 'Bouvet Island',
    'capital': 'Bouvet Island',
    'latitude': -54.43,
    'longitude': 3.38
  },
  'Brazil': {
    'name': 'Brazil',
    'capital': 'Brasília',
    'latitude': -15.794229,
    'longitude': -47.882166
  },
  'British Indian Ocean Territory': {
    'name': 'British Indian Ocean Territory',
    'capital': 'Camp Justice',
    'latitude': 21.3419,
    'longitude': 55.4778
  },
  'British Virgin Islands': {
    'name': 'British Virgin Islands',
    'capital': 'Road Town',
    'latitude': 18.428612,
    'longitude': -64.618466
  },
  'Brunei': {
    'name': 'Brunei',
    'capital': 'Bandar Seri Begawan',
    'latitude': 4.903052,
    'longitude': 114.939821
  },
  'Bulgaria': {
    'name': 'Bulgaria',
    'capital': 'Sofia',
    'latitude': 42.697708,
    'longitude': 23.321868
  },
  'Burkina Faso': {
    'name': 'Burkina Faso',
    'capital': 'Ouagadougou',
    'latitude': 12.371428,
    'longitude': -1.51966
  },
  'Burundi': {
    'name': 'Burundi',
    'capital': 'Bujumbura',
    'latitude': -3.361378,
    'longitude': 29.359878
  },
  'Cambodia': {
    'name': 'Cambodia',
    'capital': 'Phnom Penh',
    'latitude': 11.544873,
    'longitude': 104.892167
  },
  'Cameroon': {
    'name': 'Cameroon',
    'capital': 'Yaoundé',
    'latitude': 3.848033,
    'longitude': 11.502075
  },
  'Canada': {
    'name': 'Canada',
    'capital': 'Ottawa',
    'latitude': 45.42153,
    'longitude': -75.697193
  },
  'Cape Verde': {
    'name': 'Cape Verde',
    'capital': 'Praia',
    'latitude': 14.93305,
    'longitude': -23.513327
  },
  'Cayman Islands': {
    'name': 'Cayman Islands',
    'capital': 'George Town',
    'latitude': 19.286932,
    'longitude': -81.367439
  },
  'Central African Republic': {
    'name': 'Central African Republic',
    'capital': 'Bangui',
    'latitude': 4.394674,
    'longitude': 18.55819
  },
  'Chad': {
    'name': 'Chad',
    'capital': "N'Djamena",
    'latitude': 12.134846,
    'longitude': 15.055742
  },
  'Chile': {
    'name': 'Chile',
    'capital': 'Santiago',
    'latitude': -33.44889,
    'longitude': -70.669265
  },
  'China': {
    'name': 'China',
    'capital': 'Beijing',
    'latitude': 39.904211,
    'longitude': 116.407395
  },
  'Christmas Island': {
    'name': 'Christmas Island',
    'capital': 'Flying Fish Cove',
    'latitude': -10.420686,
    'longitude': 105.679379
  },
  'Cocos (Keeling) Islands': {
    'name': 'Cocos (Keeling) Islands',
    'capital': 'West Island',
    'latitude': -12.188834,
    'longitude': 96.829316
  },
  'Colombia': {
    'name': 'Colombia',
    'capital': 'Bogotá',
    'latitude': 4.710989,
    'longitude': -74.072092
  },
  'Comoros': {
    'name': 'Comoros',
    'capital': 'Moroni',
    'latitude': -11.717216,
    'longitude': 43.247315
  },
  'Congo (DRC)': {
    'name': 'Congo (DRC)',
    'capital': 'Kinshasa',
    'latitude': -4.441931,
    'longitude': 15.266293
  },
  'Congo (Republic)': {
    'name': 'Congo (Republic)',
    'capital': 'Brazzaville',
    'latitude': -4.26336,
    'longitude': 15.242885
  },
  'Cook Islands': {
    'name': 'Cook Islands',
    'capital': 'Avarua',
    'latitude': -21.212901,
    'longitude': -159.782306
  },
  'Costa Rica': {
    'name': 'Costa Rica',
    'capital': 'San José',
    'latitude': 9.928069,
    'longitude': -84.090725
  },
  "Côte d'Ivoire": {
    'name': "Côte d'Ivoire",
    'capital': 'Yamoussoukro',
    'latitude': 6.827623,
    'longitude': -5.289343
  },
  'Croatia': {
    'name': 'Croatia',
    'capital': 'Zagreb ',
    'latitude': 45.815011,
    'longitude': 15.981919
  },
  'Cuba': {
    'name': 'Cuba',
    'capital': 'Havana',
    'latitude': 23.05407,
    'longitude': -82.345189
  },
  'Curaçao': {
    'name': 'Curaçao',
    'capital': 'Willemstad',
    'latitude': 12.122422,
    'longitude': -68.882423
  },
  'Cyprus': {
    'name': 'Cyprus',
    'capital': 'Nicosia',
    'latitude': 35.185566,
    'longitude': 33.382276
  },
  'Czech Republic': {
    'name': 'Czech Republic',
    'capital': 'Prague',
    'latitude': 50.075538,
    'longitude': 14.4378
  },
  'Denmark': {
    'name': 'Denmark',
    'capital': 'Copenhagen',
    'latitude': 55.676097,
    'longitude': 12.568337
  },
  'Djibouti': {
    'name': 'Djibouti',
    'capital': 'Djibouti',
    'latitude': 11.572077,
    'longitude': 43.145647
  },
  'Dominica': {
    'name': 'Dominica',
    'capital': 'Roseau',
    'latitude': 15.309168,
    'longitude': -61.379355
  },
  'Dominican Republic': {
    'name': 'Dominican Republic',
    'capital': 'Santo Domingo',
    'latitude': 18.486058,
    'longitude': -69.931212
  },
  'Ecuador': {
    'name': 'Ecuador',
    'capital': 'Quito',
    'latitude': -0.180653,
    'longitude': -78.467838
  },
  'Egypt': {
    'name': 'Egypt',
    'capital': 'Cairo',
    'latitude': 30.04442,
    'longitude': 31.235712
  },
  'El Salvador': {
    'name': 'El Salvador',
    'capital': 'San Salvador',
    'latitude': 13.69294,
    'longitude': -89.218191
  },
  'Equatorial Guinea': {
    'name': 'Equatorial Guinea',
    'capital': 'Malabo',
    'latitude': 3.750412,
    'longitude': 8.737104
  },
  'Eritrea': {
    'name': 'Eritrea',
    'capital': 'Asmara',
    'latitude': 15.322877,
    'longitude': 38.925052
  },
  'Estonia': {
    'name': 'Estonia',
    'capital': 'Tallinn',
    'latitude': 59.436961,
    'longitude': 24.753575
  },
  'Ethiopia': {
    'name': 'Ethiopia',
    'capital': 'Addis Ababa',
    'latitude': 8.980603,
    'longitude': 38.757761
  },
  'Falkland Islands (Islas Malvinas)': {
    'name': 'Falkland Islands (Islas Malvinas)',
    'capital': 'Stanley',
    'latitude': -51.697713,
    'longitude': -57.851663
  },
  'Faroe Islands': {
    'name': 'Faroe Islands',
    'capital': 'Tórshavn',
    'latitude': 62.007864,
    'longitude': -6.790982
  },
  'Fiji': {
    'name': 'Fiji',
    'capital': 'Suva',
    'latitude': -18.124809,
    'longitude': 178.450079
  },
  'Finland': {
    'name': 'Finland',
    'capital': 'Helsinki',
    'latitude': 60.173324,
    'longitude': 24.941025
  },
  'France': {
    'name': 'France',
    'capital': 'Paris',
    'latitude': 48.856614,
    'longitude': 2.352222
  },
  'French Guiana': {
    'name': 'French Guiana',
    'capital': 'Cayenne',
    'latitude': 4.92242,
    'longitude': -52.313453
  },
  'French Polynesia': {
    'name': 'French Polynesia',
    'capital': 'Papeete',
    'latitude': -17.551625,
    'longitude': -149.558476
  },
  'French Southern Territories': {
    'name': 'French Southern Territories',
    'capital': 'Saint-Pierre ',
    'latitude': -21.3419,
    'longitude': 55.4778
  },
  'Gabon': {
    'name': 'Gabon',
    'capital': 'Libreville',
    'latitude': 0.416198,
    'longitude': 9.467268
  },
  'Gambia': {
    'name': 'Gambia',
    'capital': 'Banjul',
    'latitude': 13.454876,
    'longitude': -16.579032
  },
  'Georgia': {
    'name': 'Georgia',
    'capital': 'Tbilisi',
    'latitude': 41.715138,
    'longitude': 44.827096
  },
  'Germany': {
    'name': 'Germany',
    'capital': 'Berlin',
    'latitude': 52.520007,
    'longitude': 13.404954
  },
  'Ghana': {
    'name': 'Ghana',
    'capital': 'Accra',
    'latitude': 5.603717,
    'longitude': -0.186964
  },
  'Gibraltar': {
    'name': 'Gibraltar',
    'capital': 'Gibraltar',
    'latitude': 36.140773,
    'longitude': -5.353599
  },
  'Greece': {
    'name': 'Greece',
    'capital': 'Athens',
    'latitude': 37.983917,
    'longitude': 23.72936
  },
  'Greenland': {
    'name': 'Greenland',
    'capital': 'Nuuk',
    'latitude': 64.18141,
    'longitude': -51.694138
  },
  'Grenada': {
    'name': 'Grenada',
    'capital': "St. George's",
    'latitude': 12.056098,
    'longitude': -61.7488
  },
  'Guadeloupe': {
    'name': 'Guadeloupe',
    'capital': 'Basse-Terre',
    'latitude': 16.014453,
    'longitude': -61.706411
  },
  'Guam': {
    'name': 'Guam',
    'capital': 'Hagåtña',
    'latitude': 13.470891,
    'longitude': 144.751278
  },
  'Guatemala': {
    'name': 'Guatemala',
    'capital': 'Guatemala City',
    'latitude': 14.634915,
    'longitude': -90.506882
  },
  'Guernsey': {
    'name': 'Guernsey',
    'capital': 'St. Peter Port',
    'latitude': 49.455443,
    'longitude': -2.536871
  },
  'Guinea': {
    'name': 'Guinea',
    'capital': 'Conakry',
    'latitude': 9.641185,
    'longitude': -13.578401
  },
  'Guinea-Bissau': {
    'name': 'Guinea-Bissau',
    'capital': 'Bissau',
    'latitude': 11.881655,
    'longitude': -15.617794
  },
  'Guyana': {
    'name': 'Guyana',
    'capital': 'Georgetown',
    'latitude': 6.801279,
    'longitude': -58.155125
  },
  'Haiti': {
    'name': 'Haiti',
    'capital': 'Port-au-Prince',
    'latitude': 18.594395,
    'longitude': -72.307433
  },
  'Honduras': {
    'name': 'Honduras',
    'capital': 'Tegucigalpa',
    'latitude': 14.072275,
    'longitude': -87.192136
  },
  'Hong Kong': {
    'name': 'Hong Kong',
    'capital': 'Hong Kong',
    'latitude': 22.396428,
    'longitude': 114.109497
  },
  'Hungary': {
    'name': 'Hungary',
    'capital': 'Budapest',
    'latitude': 47.497912,
    'longitude': 19.040235
  },
  'Iceland': {
    'name': 'Iceland',
    'capital': 'Reykjavík',
    'latitude': 64.126521,
    'longitude': -21.817439
  },
  'India': {
    'name': 'India',
    'capital': 'New Delhi',
    'latitude': 28.613939,
    'longitude': 77.209021
  },
  'Indonesia': {
    'name': 'Indonesia',
    'capital': 'Jakarta',
    'latitude': -6.208763,
    'longitude': 106.845599
  },
  'Iran': {
    'name': 'Iran',
    'capital': 'Tehran',
    'latitude': 35.689198,
    'longitude': 51.388974
  },
  'Iraq': {
    'name': 'Iraq',
    'capital': 'Baghdad',
    'latitude': 33.312806,
    'longitude': 44.361488
  },
  'Ireland': {
    'name': 'Ireland',
    'capital': 'Dublin',
    'latitude': 53.349805,
    'longitude': -6.26031
  },
  'Isle of Man': {
    'name': 'Isle of Man',
    'capital': 'Douglas',
    'latitude': 54.152337,
    'longitude': -4.486123
  },
  'Israel': {
    'name': 'Israel',
    'capital': 'Tel Aviv',
    'latitude': 32.0853,
    'longitude': 34.781768
  },
  'Italy': {
    'name': 'Italy',
    'capital': 'Rome',
    'latitude': 41.902784,
    'longitude': 12.496366
  },
  'Jamaica': {
    'name': 'Jamaica',
    'capital': 'Kingston',
    'latitude': 18.042327,
    'longitude': -76.802893
  },
  'Japan': {
    'name': 'Japan',
    'capital': 'Tokyo',
    'latitude': 35.709026,
    'longitude': 139.731992
  },
  'Jersey': {
    'name': 'Jersey',
    'capital': 'St. Helier',
    'latitude': 49.186823,
    'longitude': -2.106568
  },
  'Jordan': {
    'name': 'Jordan',
    'capital': 'Amman',
    'latitude': 31.956578,
    'longitude': 35.945695
  },
  'Kazakhstan': {
    'name': 'Kazakhstan',
    'capital': 'Astana',
    'latitude': 51.160523,
    'longitude': 71.470356
  },
  'Kenya': {
    'name': 'Kenya',
    'capital': 'Nairobi',
    'latitude': -1.292066,
    'longitude': 36.821946
  },
  'Kiribati': {
    'name': 'Kiribati',
    'capital': 'Tarawa Atoll',
    'latitude': 1.451817,
    'longitude': 172.971662
  },
  'Kosovo': {
    'name': 'Kosovo',
    'capital': 'Pristina',
    'latitude': 42.662914,
    'longitude': 21.165503
  },
  'Kuwait': {
    'name': 'Kuwait',
    'capital': 'Kuwait City',
    'latitude': 29.375859,
    'longitude': 47.977405
  },
  'Kyrgyzstan': {
    'name': 'Kyrgyzstan',
    'capital': 'Bishkek',
    'latitude': 42.874621,
    'longitude': 74.569762
  },
  'Laos': {
    'name': 'Laos',
    'capital': 'Vientiane',
    'latitude': 17.975706,
    'longitude': 102.633104
  },
  'Latvia': {
    'name': 'Latvia',
    'capital': 'Riga',
    'latitude': 56.949649,
    'longitude': 24.105186
  },
  'Lebanon': {
    'name': 'Lebanon',
    'capital': 'Beirut',
    'latitude': 33.888629,
    'longitude': 35.495479
  },
  'Lesotho': {
    'name': 'Lesotho',
    'capital': 'Maseru',
    'latitude': -29.363219,
    'longitude': 27.51436
  },
  'Liberia': {
    'name': 'Liberia',
    'capital': 'Monrovia',
    'latitude': 6.290743,
    'longitude': -10.760524
  },
  'Libya': {
    'name': 'Libya',
    'capital': 'Tripoli',
    'latitude': 32.887209,
    'longitude': 13.191338
  },
  'Liechtenstein': {
    'name': 'Liechtenstein',
    'capital': 'Vaduz',
    'latitude': 47.14103,
    'longitude': 9.520928
  },
  'Lithuania': {
    'name': 'Lithuania',
    'capital': 'Vilnius',
    'latitude': 54.687156,
    'longitude': 25.279651
  },
  'Luxembourg': {
    'name': 'Luxembourg',
    'capital': 'Luxembourg',
    'latitude': 49.611621,
    'longitude': 6.131935
  },
  'Macau': {
    'name': 'Macau',
    'capital': 'Macau',
    'latitude': 22.166667,
    'longitude': 113.55
  },
  'Macedonia': {
    'name': 'Macedonia',
    'capital': 'Skopje',
    'latitude': 41.997346,
    'longitude': 21.427996
  },
  'Madagascar': {
    'name': 'Madagascar',
    'capital': 'Antananarivo',
    'latitude': -18.87919,
    'longitude': 47.507905
  },
  'Malawi': {
    'name': 'Malawi',
    'capital': 'Lilongwe',
    'latitude': -13.962612,
    'longitude': 33.774119
  },
  'Malaysia': {
    'name': 'Malaysia',
    'capital': 'Kuala Lumpur',
    'latitude': 3.139003,
    'longitude': 101.686855
  },
  'Maldives': {
    'name': 'Maldives',
    'capital': 'Malé',
    'latitude': 4.175496,
    'longitude': 73.509347
  },
  'Mali': {
    'name': 'Mali',
    'capital': 'Bamako',
    'latitude': 12.639232,
    'longitude': -8.002889
  },
  'Malta': {
    'name': 'Malta',
    'capital': 'Valletta',
    'latitude': 35.898909,
    'longitude': 14.514553
  },
  'Marshall Islands': {
    'name': 'Marshall Islands',
    'capital': 'Majuro',
    'latitude': 7.116421,
    'longitude': 171.185774
  },
  'Martinique': {
    'name': 'Martinique',
    'capital': 'Fort-de-France',
    'latitude': 14.616065,
    'longitude': -61.05878
  },
  'Mauritania': {
    'name': 'Mauritania',
    'capital': 'Nouakchott',
    'latitude': 18.07353,
    'longitude': -15.958237
  },
  'Mauritius': {
    'name': 'Mauritius',
    'capital': 'Port Louis',
    'latitude': -20.166896,
    'longitude': 57.502332
  },
  'Mayotte': {
    'name': 'Mayotte',
    'capital': 'Mamoudzou',
    'latitude': -12.780949,
    'longitude': 45.227872
  },
  'Mexico': {
    'name': 'Mexico',
    'capital': 'Mexico City',
    'latitude': 19.432608,
    'longitude': -99.133208
  },
  'Micronesia': {
    'name': 'Micronesia',
    'capital': 'Palikir',
    'latitude': 6.914712,
    'longitude': 158.161027
  },
  'Moldova': {
    'name': 'Moldova',
    'capital': 'Chisinau',
    'latitude': 47.010453,
    'longitude': 28.86381
  },
  'Monaco': {
    'name': 'Monaco',
    'capital': 'Monaco',
    'latitude': 43.737411,
    'longitude': 7.420816
  },
  'Mongolia': {
    'name': 'Mongolia',
    'capital': 'Ulaanbaatar',
    'latitude': 47.886399,
    'longitude': 106.905744
  },
  'Montenegro': {
    'name': 'Montenegro',
    'capital': 'Podgorica',
    'latitude': 42.43042,
    'longitude': 19.259364
  },
  'Montserrat': {
    'name': 'Montserrat',
    'capital': 'Plymouth',
    'latitude': 16.706523,
    'longitude': -62.215738
  },
  'Morocco': {
    'name': 'Morocco',
    'capital': 'Rabat',
    'latitude': 33.97159,
    'longitude': -6.849813
  },
  'Mozambique': {
    'name': 'Mozambique',
    'capital': 'Maputo',
    'latitude': -25.891968,
    'longitude': 32.605135
  },
  'Myanmar': {
    'name': 'Myanmar',
    'capital': 'Naypyidaw',
    'latitude': 19.763306,
    'longitude': 96.07851
  },
  'Nagorno-Karabakh Republic': {
    'name': 'Nagorno-Karabakh Republic',
    'capital': 'Stepanakert',
    'latitude': 39.826385,
    'longitude': 46.763595
  },
  'Namibia': {
    'name': 'Namibia',
    'capital': 'Windhoek',
    'latitude': -22.560881,
    'longitude': 17.065755
  },
  'Nauru': {
    'name': 'Nauru',
    'capital': 'Yaren',
    'latitude': -0.546686,
    'longitude': 166.921091
  },
  'Nepal': {
    'name': 'Nepal',
    'capital': 'Kathmandu',
    'latitude': 27.717245,
    'longitude': 85.323961
  },
  'Netherlands': {
    'name': 'Netherlands',
    'capital': 'Amsterdam',
    'latitude': 52.370216,
    'longitude': 4.895168
  },
  'Netherlands Antilles': {
    'name': 'Netherlands Antilles',
    'capital': 'Willemstad ',
    'latitude': 12.1091242,
    'longitude': -68.9316546
  },
  'New Caledonia': {
    'name': 'New Caledonia',
    'capital': 'Nouméa',
    'latitude': -22.255823,
    'longitude': 166.450524
  },
  'New Zealand': {
    'name': 'New Zealand',
    'capital': 'Wellington',
    'latitude': -41.28646,
    'longitude': 174.776236
  },
  'Nicaragua': {
    'name': 'Nicaragua',
    'capital': 'Managua',
    'latitude': 12.114993,
    'longitude': -86.236174
  },
  'Niger': {
    'name': 'Niger',
    'capital': 'Niamey',
    'latitude': 13.511596,
    'longitude': 2.125385
  },
  'Nigeria': {
    'name': 'Nigeria',
    'capital': 'Abuja',
    'latitude': 9.076479,
    'longitude': 7.398574
  },
  'Niue': {
    'name': 'Niue',
    'capital': 'Alofi',
    'latitude': -19.055371,
    'longitude': -169.917871
  },
  'Norfolk Island': {
    'name': 'Norfolk Island',
    'capital': 'Kingston',
    'latitude': -29.056394,
    'longitude': 167.959588
  },
  'North Korea': {
    'name': 'North Korea',
    'capital': 'Pyongyang',
    'latitude': 39.039219,
    'longitude': 125.762524
  },
  'Northern Cyprus': {
    'name': 'Northern Cyprus',
    'capital': 'Nicosia',
    'latitude': 35.185566,
    'longitude': 33.382276
  },
  'Northern Mariana Islands': {
    'name': 'Northern Mariana Islands',
    'capital': 'Saipan',
    'latitude': 15.177801,
    'longitude': 145.750967
  },
  'Norway': {
    'name': 'Norway',
    'capital': 'Oslo',
    'latitude': 59.913869,
    'longitude': 10.752245
  },
  'Oman': {
    'name': 'Oman',
    'capital': 'Muscat',
    'latitude': 23.58589,
    'longitude': 58.405923
  },
  'Pakistan': {
    'name': 'Pakistan',
    'capital': 'Islamabad',
    'latitude': 33.729388,
    'longitude': 73.093146
  },
  'Palau': {
    'name': 'Palau',
    'capital': 'Ngerulmud',
    'latitude': 7.500384,
    'longitude': 134.624289
  },
  'Palestine': {
    'name': 'Palestine',
    'capital': 'Ramallah',
    'latitude': 31.9073509,
    'longitude': 35.5354719
  },
  'Panama': {
    'name': 'Panama',
    'capital': 'Panama City',
    'latitude': 9.101179,
    'longitude': -79.402864
  },
  'Papua New Guinea': {
    'name': 'Papua New Guinea',
    'capital': 'Port Moresby',
    'latitude': -9.4438,
    'longitude': 147.180267
  },
  'Paraguay': {
    'name': 'Paraguay',
    'capital': 'Asuncion',
    'latitude': -25.26374,
    'longitude': -57.575926
  },
  'Peru': {
    'name': 'Peru',
    'capital': 'Lima',
    'latitude': -12.046374,
    'longitude': -77.042793
  },
  'Philippines': {
    'name': 'Philippines',
    'capital': 'Manila',
    'latitude': 14.599512,
    'longitude': 120.98422
  },
  'Pitcairn Islands': {
    'name': 'Pitcairn Islands',
    'capital': 'Adamstown',
    'latitude': -25.06629,
    'longitude': -130.100464
  },
  'Poland': {
    'name': 'Poland',
    'capital': 'Warsaw',
    'latitude': 52.229676,
    'longitude': 21.012229
  },
  'Portugal': {
    'name': 'Portugal',
    'capital': 'Lisbon',
    'latitude': 38.722252,
    'longitude': -9.139337
  },
  'Puerto Rico': {
    'name': 'Puerto Rico',
    'capital': 'San Juan',
    'latitude': 18.466334,
    'longitude': -66.105722
  },
  'Qatar': {
    'name': 'Qatar',
    'capital': 'Doha',
    'latitude': 25.285447,
    'longitude': 51.53104
  },
  'Réunion': {
    'name': 'Réunion',
    'capital': 'Saint-Denis',
    'latitude': -20.882057,
    'longitude': 55.450675
  },
  'Romania': {
    'name': 'Romania',
    'capital': 'Bucharest',
    'latitude': 44.426767,
    'longitude': 26.102538
  },
  'Russia': {
    'name': 'Russia',
    'capital': 'Moscow',
    'latitude': 55.755826,
    'longitude': 37.6173
  },
  'Rwanda': {
    'name': 'Rwanda',
    'capital': 'Kigali',
    'latitude': -1.957875,
    'longitude': 30.112735
  },
  'Saint Pierre and Miquelon': {
    'name': 'Saint Pierre and Miquelon',
    'capital': 'St. Pierre',
    'latitude': 46.775846,
    'longitude': -56.180636
  },
  'Saint Vincent and the Grenadines': {
    'name': 'Saint Vincent and the Grenadines',
    'capital': 'Kingstown',
    'latitude': 13.160025,
    'longitude': -61.224816
  },
  'Samoa': {
    'name': 'Samoa',
    'capital': 'Apia',
    'latitude': -13.850696,
    'longitude': -171.751355
  },
  'San Marino': {
    'name': 'San Marino',
    'capital': 'San Marino',
    'latitude': 43.935591,
    'longitude': 12.447281
  },
  'São Tomé and Príncipe': {
    'name': 'São Tomé and Príncipe',
    'capital': 'São Tomé',
    'latitude': 0.330192,
    'longitude': 6.733343
  },
  'Saudi Arabia': {
    'name': 'Saudi Arabia',
    'capital': 'Riyadh',
    'latitude': 24.749403,
    'longitude': 46.902838
  },
  'Senegal': {
    'name': 'Senegal',
    'capital': 'Dakar',
    'latitude': 14.764504,
    'longitude': -17.366029
  },
  'Serbia': {
    'name': 'Serbia',
    'capital': 'Belgrade',
    'latitude': 44.786568,
    'longitude': 20.448922
  },
  'Seychelles': {
    'name': 'Seychelles',
    'capital': 'Victoria',
    'latitude': -4.619143,
    'longitude': 55.451315
  },
  'Sierra Leone': {
    'name': 'Sierra Leone',
    'capital': 'Freetown',
    'latitude': 8.465677,
    'longitude': -13.231722
  },
  'Singapore': {
    'name': 'Singapore',
    'capital': 'Singapore',
    'latitude': 1.280095,
    'longitude': 103.850949
  },
  'Slovakia': {
    'name': 'Slovakia',
    'capital': 'Bratislava',
    'latitude': 48.145892,
    'longitude': 17.107137
  },
  'Slovenia': {
    'name': 'Slovenia',
    'capital': 'Ljubljana',
    'latitude': 46.056947,
    'longitude': 14.505751
  },
  'Solomon Islands': {
    'name': 'Solomon Islands',
    'capital': 'Honiara',
    'latitude': -9.445638,
    'longitude': 159.9729
  },
  'Somalia': {
    'name': 'Somalia',
    'capital': 'Mogadishu',
    'latitude': 2.046934,
    'longitude': 45.318162
  },
  'South Africa': {
    'name': 'South Africa',
    'capital': 'Pretoria',
    'latitude': -25.747868,
    'longitude': 28.229271
  },
  'South Georgia and the South Sandwich Islands': {
    'name': 'South Georgia and the South Sandwich Islands',
    'capital': 'King Edward Point',
    'latitude': -54.28325,
    'longitude': -36.493735
  },
  'South Korea': {
    'name': 'South Korea',
    'capital': 'Seoul',
    'latitude': 37.566535,
    'longitude': 126.977969
  },
  'South Ossetia': {
    'name': 'South Ossetia',
    'capital': 'Tskhinvali',
    'latitude': 42.22146,
    'longitude': 43.964405
  },
  'South Sudan': {
    'name': 'South Sudan',
    'capital': 'Juba',
    'latitude': 4.859363,
    'longitude': 31.57125
  },
  'Spain': {
    'name': 'Spain',
    'capital': 'Madrid',
    'latitude': 40.416775,
    'longitude': -3.70379
  },
  'Sri Lanka': {
    'name': 'Sri Lanka',
    'capital': 'Sri Jayawardenepura Kotte',
    'latitude': 6.89407,
    'longitude': 79.902478
  },
  'St. Barthélemy': {
    'name': 'St. Barthélemy',
    'capital': 'Gustavia',
    'latitude': 17.896435,
    'longitude': -62.852201
  },
  'St. Kitts and Nevis': {
    'name': 'St. Kitts and Nevis',
    'capital': 'Basseterre',
    'latitude': 17.302606,
    'longitude': -62.717692
  },
  'St. Lucia': {
    'name': 'St. Lucia',
    'capital': 'Castries',
    'latitude': 14.010109,
    'longitude': -60.987469
  },
  'St. Martin': {
    'name': 'St. Martin',
    'capital': 'Marigot',
    'latitude': 18.067519,
    'longitude': -63.082466
  },
  'Sudan': {
    'name': 'Sudan',
    'capital': 'Khartoum',
    'latitude': 15.500654,
    'longitude': 32.559899
  },
  'Suriname': {
    'name': 'Suriname',
    'capital': 'Paramaribo',
    'latitude': 5.852036,
    'longitude': -55.203828
  },
  'Svalbard and Jan Mayen': {
    'name': 'Svalbard and Jan Mayen',
    'capital': 'Longyearbyen ',
    'latitude': 78.062,
    'longitude': 22.055
  },
  'Swaziland': {
    'name': 'Swaziland',
    'capital': 'Mbabane',
    'latitude': -26.305448,
    'longitude': 31.136672
  },
  'Sweden': {
    'name': 'Sweden',
    'capital': 'Stockholm',
    'latitude': 59.329323,
    'longitude': 18.068581
  },
  'Switzerland': {
    'name': 'Switzerland',
    'capital': 'Bern',
    'latitude': 46.947974,
    'longitude': 7.447447
  },
  'Syria': {
    'name': 'Syria',
    'capital': 'Damascus',
    'latitude': 33.513807,
    'longitude': 36.276528
  },
  'Taiwan': {
    'name': 'Taiwan',
    'capital': 'Taipei',
    'latitude': 25.032969,
    'longitude': 121.565418
  },
  'Tajikistan': {
    'name': 'Tajikistan',
    'capital': 'Dushanbe',
    'latitude': 38.559772,
    'longitude': 68.787038
  },
  'Tanzania': {
    'name': 'Tanzania',
    'capital': 'Dodoma',
    'latitude': -6.162959,
    'longitude': 35.751607
  },
  'Thailand': {
    'name': 'Thailand',
    'capital': 'Bangkok',
    'latitude': 13.756331,
    'longitude': 100.501765
  },
  'Timor-Leste': {
    'name': 'Timor-Leste',
    'capital': 'Dili',
    'latitude': -8.556856,
    'longitude': 125.560314
  },
  'Togo': {
    'name': 'Togo',
    'capital': 'Lomé',
    'latitude': 6.172497,
    'longitude': 1.231362
  },
  'Tokelau': {
    'name': 'Tokelau',
    'capital': 'Nukunonu',
    'latitude': -9.2005,
    'longitude': -171.848
  },
  'Tonga': {
    'name': 'Tonga',
    'capital': 'Nukuʻalofa',
    'latitude': -21.139342,
    'longitude': -175.204947
  },
  'Transnistria': {
    'name': 'Transnistria',
    'capital': 'Tiraspol',
    'latitude': 46.848185,
    'longitude': 29.596805
  },
  'Trinidad and Tobago': {
    'name': 'Trinidad and Tobago',
    'capital': 'Port of Spain',
    'latitude': 10.654901,
    'longitude': -61.501926
  },
  'Tristan da Cunha': {
    'name': 'Tristan da Cunha',
    'capital': 'Edinburgh of the Seven Seas',
    'latitude': -37.068042,
    'longitude': -12.311315
  },
  'Tunisia': {
    'name': 'Tunisia',
    'capital': 'Tunis',
    'latitude': 36.806495,
    'longitude': 10.181532
  },
  'Turkey': {
    'name': 'Turkey',
    'capital': 'Ankara',
    'latitude': 39.933364,
    'longitude': 32.859742
  },
  'Turkmenistan': {
    'name': 'Turkmenistan',
    'capital': 'Ashgabat',
    'latitude': 37.960077,
    'longitude': 58.326063
  },
  'Turks and Caicos Islands': {
    'name': 'Turks and Caicos Islands',
    'capital': 'Cockburn Town',
    'latitude': 21.467458,
    'longitude': -71.13891
  },
  'Tuvalu': {
    'name': 'Tuvalu',
    'capital': 'Funafuti',
    'latitude': -8.520066,
    'longitude': 179.198128
  },
  'U.S. Virgin Islands': {
    'name': 'U.S. Virgin Islands',
    'capital': 'Charlotte Amalie',
    'latitude': 18.3419,
    'longitude': -64.930701
  },
  'Uganda': {
    'name': 'Uganda',
    'capital': 'Kampala',
    'latitude': 0.347596,
    'longitude': 32.58252
  },
  'Ukraine': {
    'name': 'Ukraine',
    'capital': 'Kiev',
    'latitude': 50.4501,
    'longitude': 30.5234
  },
  'United Arab Emirates': {
    'name': 'United Arab Emirates',
    'capital': 'Abu Dhabi',
    'latitude': 24.299174,
    'longitude': 54.697277
  },
  'United Kingdom': {
    'name': 'United Kingdom',
    'capital': 'London',
    'latitude': 51.507351,
    'longitude': -0.127758
  },
  'United States': {
    'name': 'United States',
    'capital': 'Washington',
    'latitude': 38.907192,
    'longitude': -77.036871
  },
  'Uruguay': {
    'name': 'Uruguay',
    'capital': 'Montevideo',
    'latitude': -34.901113,
    'longitude': -56.164531
  },
  'Uzbekistan': {
    'name': 'Uzbekistan',
    'capital': 'Tashkent',
    'latitude': 41.299496,
    'longitude': 69.240073
  },
  'Vanuatu': {
    'name': 'Vanuatu',
    'capital': 'Port Vila',
    'latitude': -17.733251,
    'longitude': 168.327325
  },
  'Vatican City': {
    'name': 'Vatican City',
    'capital': 'Vatican City',
    'latitude': 41.902179,
    'longitude': 12.453601
  },
  'Venezuela': {
    'name': 'Venezuela',
    'capital': 'Caracas',
    'latitude': 10.480594,
    'longitude': -66.903606
  },
  'Vietnam': {
    'name': 'Vietnam',
    'capital': 'Hanoi',
    'latitude': 21.027764,
    'longitude': 105.83416
  },
  'Wallis and Futuna': {
    'name': 'Wallis and Futuna',
    'capital': 'Mata-Utu',
    'latitude': -13.282509,
    'longitude': -176.176447
  },
  'Western Sahara': {
    'name': 'Western Sahara',
    'capital': 'El Aaiún',
    'latitude': 27.125287,
    'longitude': -13.1625
  },
  'Yemen': {
    'name': 'Yemen',
    'capital': "Sana'a",
    'latitude': 15.369445,
    'longitude': 44.191007
  },
  'Zambia': {
    'name': 'Zambia',
    'capital': 'Lusaka',
    'latitude': -15.387526,
    'longitude': 28.322817
  },
  'Zimbabwe': {
    'name': 'Zimbabwe',
    'capital': 'Harare',
    'latitude': -17.825166,
    'longitude': 31.03351
  }
}

def convert_lat_long(latitude, longitude, map_width, map_height):
  
  false_easting = 180
  radius = map_width / (2 * pi)
  latitude = radians(latitude)
  longitude = radians(longitude + false_easting)
  
  x_coord = longitude * radius
  
  y_dist_from_equator = radius * log(tan(pi / 4 + latitude / 2))
  y_coord = map_height / 2 - y_dist_from_equator
  
  coords = {'x': x_coord, 'y': y_coord}
  
  return coords


def get_available_regions():
  return regions.keys()


def get_region_coords(region, map_width=991, map_height=768):
  coords = None
  
  try:
    lookup = regions[region]
    coords = convert_lat_long(lookup['latitude'], lookup['longitude'], map_width, map_height)
    return coords
  except KeyError:
    print('Region not recognised: ', region)
