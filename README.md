# README


# Initial Setup

Copy the `.env.example` file into a `.env` file.

From the project directory build the app using docker:

```
docker-compose build
```

# Running the app

Start the application and its dependencies via docker:

```
docker-compose up
```

# CORS Allowed Origins

Add a comma separated list to the relevant enviroment settings. E.g for development in the `.env` file:

```
ALLOWED_ORIGINS=localhost:3002,localhost:3000
