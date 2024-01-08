#!/bin/bash

# List all files (excluding directories and .sh files) using zenity --list
files=$(ls -F | grep -v '/\|\.sh$' | zenity --list --title="Select a Table" --column="Tables")
if [ -z "$files" ]; then
    echo "No table selected. Exiting."
    exit 1
fi

# Ask for the table name using zenity --entry
tablename=$files
if [ -z "$tablename" ]; then
    echo "No table name provided. Exiting."
    exit 1
fi

# Check if the table and its metafile exist
if [[ -f "$tablename" && -f ".$tablename.meta" ]]; then
    echo "Table and metafile exist."
    # cd nameOfTable
else
    echo "Table or metafile does not exist."
    exit 1
fi

# Read the metafile
IFS=$'\n' read -d '' -r -a lines < ".$tablename.meta"

# Loop to add rows
while true; do
    row=""
    pk_value=""
    # Loop over the lines in the metafile
    for line in "${lines[@]}"; do
        # Split the line into column name, data type, and primary key indicator
        IFS=':' read -r -a parts <<< "$line"
        column="${parts[0]}"
        datatype="${parts[1]}"
        PK="${parts[2]}"

        # Ask for the column data using zenity --entry
        data=$(zenity --entry --title="Enter $column" --text="Enter $column, ($datatype):")
        if [[ -z "$data" ]]; then
    zenity --error --title="Error" --text="No data entered. Please enter a value."
    continue
fi
        # Check the data type
        if [[ "$datatype" == "integer" && "$data" =~ ^[0-9]+$ ]] || [[ "$datatype" == "string" && "$data" =~ ^[a-zA-Z]+$ ]]; then
            # If the data type is correct, add the data to the row
            row="$row$data:"
            # If this column is the primary key, save the value
            if [[ "$PK" == "PK" ]]; then
                pk_value="$data"
            fi
        else
            zenity --error --title="Error" --text="Invalid datatype. Enter $datatype only."
            continue 2
        fi
    done

	    # Check if the primary key is unique and not null
	if [[ -z "$pk_value" ]]; then
	    zenity --error --title="Error" --text="Primary key cannot be null."
	    continue
	elif grep -Pq "\b$pk_value\b" "$tablename"; then
	    zenity --error --title="Error" --text="Primary key $pk_value already exists."
	    continue
	fi

    # Remove the trailing colon and add the row to the table
    row="${row%:}"
    echo "$row" >> "$tablename"

    # Ask if the user wants to add another row using zenity --question
    zenity --question --title="Add Another Row?" --text="Do you want to add another row?"
    answer=$?
    if [[ "$answer" -eq 0 ]]; then
        continue
    else
        break
    fi
done

