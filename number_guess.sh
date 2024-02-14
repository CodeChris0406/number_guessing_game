#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read USERNAME

# Validate username length
if [ ${#USERNAME} -gt 22 ]; then
  echo "Username cannot be longer than 22 characters."
  exit 1
fi

# Check if user exists
USER_DATA=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username = '$USERNAME';")

if [[ -z $USER_DATA ]]; then
    # User does not exist, insert new user
    echo "Welcome, $USERNAME! It looks like this is your first time here."
    INSERT_RESULT=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES ('$USERNAME', 0, NULL) RETURNING user_id;")
    USER_ID=$(echo $INSERT_RESULT | xargs) # Trim whitespace and capture user_id
    GAMES_PLAYED=0
    BEST_GAME="N/A"
else
    # User exists, parse data
    IFS='|' read USER_ID GAMES_PLAYED BEST_GAME <<< $(echo $USER_DATA)
    BEST_GAME=${BEST_GAME:-"N/A"} # Handle NULL best game with default value "N/A"
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
TRIES=0

echo "Guess the secret number between 1 and 1000:"
while :; do
    read GUESS
    if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
        echo "That is not an integer, guess again:"
        continue
    fi

    ((TRIES++))

    if [ $GUESS -eq $SECRET_NUMBER ]; then
        break
    elif [ $GUESS -gt $SECRET_NUMBER ]; then
        echo "It's lower than that, guess again:"
    else
        echo "It's higher than that, guess again:"
    fi
done
# Update user stats - assuming USER_ID is retrieved correctly above
$PSQL "UPDATE users SET games_played = games_played + 1, best_game = CASE WHEN best_game IS NULL OR $TRIES < best_game THEN $TRIES ELSE best_game END WHERE username = '$USERNAME';"

echo "You guessed it in $TRIES tries. The secret number was $SECRET_NUMBER. Nice job!"
