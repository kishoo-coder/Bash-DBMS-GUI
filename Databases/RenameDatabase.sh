export LC_COLLATE=C
shopt -s extglob

# Display a file selection dialog to choose a database directory
old_name=$(zenity --file-selection --directory --title="Select Database Directory" --filename="Databases")

if [ -e "$old_name" ]; then
    while true; do
        # Display an input dialog to get the new database name
        new_name=$(zenity --entry --title="Enter New Database Name" --text="Please enter the new database name:")

        regex='^[a-zA-Z_]+$'

        if [[ ! $new_name =~ $regex ]]; then
            # Display an error message if the entered name is invalid
            zenity --error --title="Error" --text="Invalid database name. Please use only letters and underscores. It must start with a letter or underscore."
        elif [ -e "$new_name" ]; then
            # Display an error message if the entered name already exists
            zenity --error --title="Error" --text="Invalid database name. Already exists."
        else
            break
        fi
    done

    # Rename the database using the mv command
    mv -i "$old_name" "$new_name"
    
    # Display a notification with the successful rename message
    zenity --info --title="Success" --text="Database '$old_name' renamed to '$new_name'."
else
    # Display an error message if the selected database directory does not exist
    zenity --error --title="Error" --text="Database directory '$old_name' does not exist. Please select an existing database directory."
fi

