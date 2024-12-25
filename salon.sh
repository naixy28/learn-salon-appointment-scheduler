#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=salon --tuples-only --no-align -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"

echo -e "Welcome to My Salon, how can I help you?\n"

display_services() {
  SERVICES=$($PSQL "SELECT * FROM services;")
  # echo $SERVICES
  echo "$SERVICES" | while IFS="|" read SERVICE_ID SERVICE_NAME; do
    echo -e "$SERVICE_ID) $SERVICE_NAME"
  done
  read SERVICE_ID_SELECTED
  check_service_id $SERVICE_ID_SELECTED
} 
check_service_id() {
  SERVICE_ID_SELECTED=$1
  EXIST=$($PSQL "SELECT 1 FROM services WHERE service_id=$SERVICE_ID_SELECTED")
  if [[ -n $EXIST ]]
  then
    # check user exist, if not, create user
    find_or_create_user $SERVICE_ID_SELECTED
  else
    echo -e "\nI could not find that service. What would you like today?"
    display_services
  fi
}
find_or_create_user() {
  SERVICE_ID_SELECTED=$1
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  CUSTOMER_EXIST=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
  if [[ -n $CUSTOMER_EXIST ]]
  then
    # echo customer_id
    CUSTOMER_ID=$CUSTOMER_EXIST
    create_appointment $CUSTOMER_ID $SERVICE_ID_SELECTED
  else
    # create customer
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME
    # insert customer
    RESULT=$($PSQL "INSERT INTO customers (name, phone) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
    # echo customer_id
    if [[ $RESULT == "INSERT 0 1" ]]
    then
      CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
      create_appointment $CUSTOMER_ID $SERVICE_ID_SELECTED
    fi
  fi
}
create_appointment() {
  CUSTOMER_ID=$1
  SERVICE_ID_SELECTED=$2
  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id=$CUSTOMER_ID")
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")

  echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
  read SERVICE_TIME

  RESULT=$($PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

  if [[ $RESULT == 'INSERT 0 1' ]]
  then
    echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
  fi
}
display_services
