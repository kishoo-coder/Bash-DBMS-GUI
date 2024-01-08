#!/bin/bash

# List all files (excluding directories) using zenity --list
files=$(ls -F | grep -v '/')
tablename=$(zenity --list --title="Select a Table" --column="Tables" $files)
if [ -z "$tablename" ]; then
    echo "No table selected. Exiting."
    exit 1
fi

# Ask for confirmation using zenity --question
confirmm=$(zenity --question --title="Confirmation" --text="Are you sure you want to delete '$tablename' table?")
if [ $? -eq 0 ]; then
    if [ -e "$tablename" ]; then
        rm "$tablename"
        zenity --info --title="Success" --text="Table '$tablename' deleted successfully."

        # Remove associated metadata file
        metafile=".$tablename.meta"
        if [ -e "$metafile" ]; then
            rm "$metafile"
            zenity --info --title="Success" --text="Metadata file '$metafile' deleted successfully."
        fi
    else
        zenity --error --title="Error" --text="Table '$tablename' does not exist."
    fi
else
    zenity --info --title="Info" --text="Table deletion aborted."
fi

