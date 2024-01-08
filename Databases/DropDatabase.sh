export LC_COLLATE=C
shopt -s extglob

# Display a file selection dialog to choose a database directory
dbName=$(zenity --file-selection --directory --title="Select Database Directory for Deletion" --filename="Databases")

if [[ -e "$dbName" ]]; then
    # Display a confirmation dialog
    zenity --question --title="Confirm Deletion" --text="Are you sure you want to delete the database '$dbName'?"
    answer=$?
    if [[ "$answer" -eq 0 ]]; then
        # Delete the database using the rm command
        rm -r "$dbName"
        zenity --info --title="Success" --text="Database '$dbName' deleted successfully."
    else
        zenity --info --title="Cancelled" --text="Deletion of database '$dbName' cancelled."
    fi
else 
    zenity --error --title="Error" --text="Database directory '$dbName' does not exist. Please select an existing database directory."
fi

