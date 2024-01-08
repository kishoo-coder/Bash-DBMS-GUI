#!/bin/bash

# List all files (excluding directories and .sh files) using zenity --list
files=$(ls -F | grep -v '/\|\.sh$' | zenity --list --title="Select a Table" --column="Tables")
if [ -z "$files" ]; then
    echo "No table selected. Exiting."
    exit 1
fi

# Ask for the table name
tablename=$files
if [ -z "$tablename" ]; then
    echo "No table name provided. Exiting."
    exit 1
fi

# Check if the table and its metafile exist
if [[ -f "$tablename" && -f ".$tablename.meta" ]]; then
    echo "Table and metafile exist."

    # Show options using zenity --list
    choice=$(zenity --list --title="Select an Operation" --column="Options" "Delete row by primary key" "Delete all rows in the table" "Delete all contents of a column")
    if [ -z "$choice" ]; then
        echo "No option selected. Exiting."
        exit 1
    fi

    case $choice in
        "Delete row by primary key")
	    # Read the metafile
	    IFS=$'\n' read -d '' -r -a lines < ".$tablename.meta"

	    # Identify the primary key and its datatype
	    for line in "${lines[@]}"; do
		IFS=':' read -r -a parts <<< "$line"
		for part in "${parts[@]}"; do
		    if [[ $part == "PK" ]]; then
		        pk_column=${parts[0]}
		        zenity --info --title="Info" --text="Primary key found in column: $pk_column"
		        break 2
		    fi
		done
	    done

	    if [[ -n "$pk_column" ]]; then
		pk_value=$(zenity --entry --title="Delete Row by Primary Key" --text="Enter the value of $pk_column to delete the corresponding row:")
		if [[ -n "$pk_value" ]]; then
		    # Find the line number in the meta file where the primary key is located
		    meta_line_number=$(grep -n "^$pk_column" ".$tablename.meta" | cut -d ":" -f 1)

		    if grep -Pq "\b$pk_value\b" "$tablename"; then
		        # Find the line number in the table file where the primary key value is located
		        table_line_number=$(grep -nP "\b$pk_value\b" "$tablename" | cut -d ":" -f 1)

		        # Check if the primary key value exists in the table
		        if [[ -n "$table_line_number" ]]; then
		            # Delete the row in the table file
		            sed -i "${table_line_number}d" "$tablename"
		            zenity --info --title="Success" --text="Row with $pk_column=$pk_value deleted successfully."
		        else
		            zenity --info --title="Info" --text="Primary key value '$pk_value' not found in the table."
		        fi
		    else
		        zenity --info --title="Info" --text="Primary key value '$pk_value' not found in the table."
		    fi
		else
		    zenity --info --title="Info" --text="Invalid primary key value."
		fi
	    else
		zenity --info --title="Info" --text="Primary key not found in metafile."
	    fi
	    break
	    ;;
	"Delete all rows in the table")
	    # Confirm before deleting all rows
	    confirm=$(zenity --question --title="Confirmation" --text="Are you sure you want to delete all rows in the table?" --ok-label="Yes" --cancel-label="No")
	    if [ $? -eq 0 ]; then
		# Remove all rows from the table (excluding column names)
		awk 'NR==1 {print; next} {next} ' "$tablename" > temp && mv temp "$tablename"
		zenity --info --title="Success" --text="All rows in the table '$tablename' deleted successfully."
	    else
		zenity --info --title="Info" --text="Deletion canceled."
	    fi
	    break
	    ;;

        "Delete all contents of a column")
            read -r header < "$tablename"
            IFS=':' read -r -a columns <<< "$header"
            col_choice=$(zenity --list --title="Delete Column Contents" --text="Select column to delete all contents:" --column="Columns" "${columns[@]}")
            if [[ -n "$col_choice" ]]; then
                if grep -q "^$col_choice:.*:PK$" ".$tablename.meta"; then
                    zenity --error --title="Error" --text="Cannot delete contents of a primary key column ('$col_choice')."
                else
                    awk -F: -v OFS=: -v COL="$col_choice" '
                        NR==1 {
                            for(i=1; i<=NF; i++) {
                                if ($i == COL) {
                                    colindex = i
                                }
                            }
                            print
                            next
                        }
                        {
                            $colindex = ""
                            print
                        }
                        ' "$tablename" > temp && mv temp "$tablename"

                    echo "All contents of column '$col_choice' deleted successfully."
                fi
            else
                echo "Invalid column choice. Please select a valid column."
            fi
            ;;

        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
else
    echo "Table or metafile does not exist."
fi

