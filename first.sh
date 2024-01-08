#!/bin/bash

export LC_COLLATE=C
shopt -s extglob

validate_db_name() {
    dbname=$1
    regex='^[a-zA-Z_]+$'

    if [[ ! $dbname =~ $regex ]]; then
        zenity --error --text="Invalid database name. Please use only letters and underscores. It must start with a letter or underscore."
        return 1
    elif [ -e "$dbname" ]; then
        zenity --error --text="Database name already exists."
        return 1
    else
        mkdir "$dbname" && zenity --info --text="Database '$dbname' created successfully."
        return 0
    fi
}

check_exist() {
    if [ ! -d "./Databases" ]; then
        mkdir "./Databases"
    fi
    cd "./Databases" || exit 1
}

check_exist
options=("Create Database" "List Databases" "Connect To Database" "Rename Database" "Drop Database" "Quit")

while true; do
    choice=$(zenity --list --title="Database Management" --text="Select an option:" --column="Options" "${options[@]}")

    case $choice in
        "Create Database")
            dbname=$(zenity --entry --title="Create Database" --text="Please Enter Your Database Name:")
            until validate_db_name "$dbname"; do
                dbname=$(zenity --entry --title="Create Database" --text="Please Enter Your Database Name:")
            done
            ;;
        "List Databases")
            databases=$(ls -F | grep '/')
            zenity --info --title="List of Databases" --text="Databases:\n$databases"
            ;;
        "Connect To Database")
            ./ConnectToDatabase.sh
            ;;
        "Rename Database")
            ./RenameDatabase.sh
            ;;
        "Drop Database")
            ./DropDatabase.sh
            ;;
        "Quit")
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

