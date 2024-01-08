#!/bin/bash

# List all files (excluding directories) using zenity --list
files=$(ls -F | grep -v '/' | zenity --list --title="Select a Table" --column="Tables")
if [ -z "$files" ]; then
    echo "No table selected. Exiting."
    exit 1
fi

# Ask for the old table name using zenity --entry
old_name=$files
if [ -z "$old_name" ]; then
    echo "No old table name provided. Exiting."
    exit 1
fi

# Check if the old table and its metafile exist
if [ -e "$old_name" ]; then
    # Loop to ask for the new table name
    while true; do
        new_name=$(zenity --entry --title="Enter New Table Name" --text="Enter the new table name:")
        regex='^[a-zA-Z_]+$'

        if [[ ! $new_name =~ $regex ]]; then
            zenity --error --title="Error" --text="Invalid table name. Please use only letters and underscores. It must start with a letter or underscore."
        elif [ -e "$new_name" ]; then
            zenity --error --title="Error" --text="Invalid table name. Already exists."
        else
            break
        fi
    done

    # Rename the table and its metafile using zenity --info
    mv -i "$old_name" "$new_name"
    mv -i ".$old_name.meta" ".$new_name.meta"
    zenity --info --title="Success" --text="Table '$old_name' renamed to '$new_name'."
else 
    zenity --error --title="Error" --text="Table '$old_name' does not exist. Please enter an existing table name."
fi
break

