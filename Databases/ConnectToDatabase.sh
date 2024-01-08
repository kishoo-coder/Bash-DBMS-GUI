export LC_COLLATE=C
shopt -s extglob

pwd

validate_table_name() {
    tablename=$1
    regex='^[a-zA-Z_]+$'

    if [[ ! $tablename =~ $regex ]]; then
        zenity --error --title="Error" --text="Invalid table name. Please use only letters and underscores. It must start with a letter or underscore."
        return 1
    elif [ -e "$tablename" ]; then
        zenity --error --title="Error" --text="Table name already exists."
        return 1
    else
        touch "$tablename" && zenity --info --title="Success" --text="Table '$tablename' created successfully."
        return 0
    fi
}

validate_column_name() {
    columnname=$1
    regex='^[a-zA-Z_]+$'
    if [[ $columnname =~ $regex ]]; then
        return 0
    else 
        zenity --error --title="Error" --text="Invalid column name. Please use only letters and underscores. It must start with a letter or underscore."
        return 1
    fi
}

# List all databases to be shown before selection
database_list=$(ls -d */)
Selected_database=$(zenity --list --title="Select Database" --text="Please select a database:" --column="Databases" $database_list)

if [ -d "$Selected_database" ]; then
    cd ./$Selected_database || exit 1

    while true;
    do
        PS3="$Selected_database DB, Enter Value: "
        options=("Create Table" "List Table" "Drop Table" "Rename Table" "Insert Into Table" "Update Table" "Select from Table" "Delete from Table" "Quit")
        option=$(zenity --list --title="Select Option" --text="Choose an option:" --column="Options" "${options[@]}")

        case $option in
            "Create Table")
		pwd
                ../CreateTable.sh
                ;;

            "List Table")
                zenity --list --title="List Tables" --column="Tables" $(ls -F | grep -v 		'/') --width=300 --height=200
                ;;

            "Drop Table")
                ../DropTable.sh
                ;;
                
            "Rename Table")          
		../RenameTable.sh
                ;;

            "Insert Into Table")
                ../InsertIntoTable.sh
                ;;

            "Update Table")
                ../UpdateTable.sh
                ;;
            "Select from Table")
                ../SelectFromTable.sh
                ;;

            "Delete from Table")
                ../DeleteFromTable.sh
                ;;

            "Quit")
                break 2
                ;;

            *)
                break 2
                ;;
        esac
    done
else
    zenity --error --title="Error" --text="Database doesn't exist"
fi

