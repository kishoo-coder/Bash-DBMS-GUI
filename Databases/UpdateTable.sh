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
else
    echo "Table or metafile does not exist."
    exit 1
fi

# Read the metafile
IFS=$'\n' read -d '' -r -a lines < ".$tablename.meta"

# Identify the primary key and its datatype
for line in "${lines[@]}"; do
    IFS=':' read -r -a parts <<< "$line"
    if [[ "${parts[2]}" == "PK" ]]; then
        pk_column="${parts[0]}"
        pk_datatype="${parts[1]}"
        break
    fi
done

# Display column names, primary key column name, and its datatype using zenity --info
columnNames=$(head -n 1 "$tablename")
IFS=':' read -r -a columns <<< "$columnNames"
columnList=""
for col in "${columns[@]}"; do
    columnList+="$col\n"
done

zenity --info --title="Column Names" --text="$columnList"

# Show a sample of the data using zenity --text-info
sampleData=$(tail -n +2 "$tablename" | awk '{printf "%s\n", $0}')
zenity --text-info --title="Sample Data from $tablename" --text="$sampleData" --filename="$tablename" --no-markup

# Ask the user to choose an option using select and handle it with a case loop
options=("Update value in a Row" "Update Multiple Values in a Column" "Exit")
while true; do
    option=$(zenity --list --title="Choose an Option" --column="Options" "${options[@]}")
    case $option in
        "Update value in a Row")
            while true; do
    pk=$(zenity --entry --title="Enter $pk_column[$pk_datatype] to Update" --text="Enter the $pk_column, ($pk_datatype) to update:")

    if [ "${#pk}" -eq 0 ]; then
        zenity --error --title="Error" --text="No primary key provided. Exiting."
        exit 1
    fi

    # Check if the primary key matches the expected data type pattern
    if [[ "$pk_datatype" == "integer" && "$pk" =~ ^[0-9]+$ ]]; then
        # Integer data type with digits only
        break
    elif [[ "$pk_datatype" == "string" && "$pk" =~ ^[a-zA-Z_]+$ ]]; then
        # String data type with letters and underscore
        break
    else
        zenity --error --title="Error" --text="Entered primary key does not match the expected data type pattern ($pk_datatype). Please enter a valid primary key."
    fi

    # Check if the primary key exists in the meta file
    meta_line_number=$(grep -n "^$pk_column" ".$tablename.meta" | cut -d ":" -f 1)

    if [[ -n "$meta_line_number" ]]; then
        # Primary key exists, continue with the update
        break
    else
        zenity --error --title="Error" --text="Primary key '$pk_column' not found in the meta file. Please enter a valid primary key."
        exit 1
    fi
done

# Check if the primary key exists in the table file
# Determine the column index dynamically based on the meta file
pk_colindex=$(awk -F: -v pk_col="$pk_column" 'NR==1{for(i=1;i<=NF;i++){if($i==pk_col){col=i;break}}} END{print col}' "$tablename")
if ! awk -F: -v col="$pk_colindex" -v pk_val="$pk" 'NR>1{if($col==pk_val){found=1}} END{exit !found}' "$tablename"; then
    zenity --error --title="Error" --text="Entered primary key does not exist in the table. Please enter a valid primary key."
    exit 1
fi

# Ask for the column to update using zenity --entry
columnList=$(awk -F: 'NR==1{for(i=1;i<=NF;i++) print $i}' "$tablename" | tr '\n' ' ')
column=$(zenity --list --title="Choose Column to Update" --text="Select the column to update:" --column="Columns" $columnList)

if [ "$column" == "$pk_column" ]; then
    zenity --error --title="Error" --text="Updating the primary key column is not allowed."
    exit 1
fi


# Find the data type of the column
datatype=$(grep "^$column:" ".$tablename.meta" | cut -d ':' -f 2)

# Ask for the new value using zenity --entry
new_value=$(zenity --entry --title="Enter New Value" --text="Enter the new value for $column, ($datatype):")

# Check the data type of the new value
if [[ "$datatype" == "integer" && "$new_value" =~ ^[0-9]+$ ]] || [[ "$datatype" == "string" && "$new_value" =~ ^[a-zA-Z_]+$ ]]; then
    # If the data type is correct, update the value
    colindex=$(awk -F: -v col="$column" 'NR==1{for(i=1;i<=NF;i++){if($i==col){col=i;break}}} END{print col}' "$tablename")
    awk -F: -v OFS=: -v pk="$pk" -v col="$colindex" -v val="$new_value" -v pk_col="$pk_colindex" '
        $pk_col == pk {
            $col = val
        }
        {print}
    ' "$tablename" > temp && mv temp "$tablename"
    zenity --info --title="Success" --text="Record is updated."
else
    zenity --error --title="Error" --text="Invalid data type for the new value."
    exit 1
fi
break            
;;  
        "Update Multiple Values in a Column")
            # Display column names using zenity --list
            columnList=$(echo -e "${columns[@]}" | tr ' ' '\n')
            column=$(zenity --list --title="Choose Column to Update" --text="Select the column to update:" --column="Columns" $columnList)
            if [ -z "$column" ]; then
                zenity --error --title="Error" --text="No column selected. Exiting."
                exit 1
            fi

            if [ "$column" == "$pk_column" ]; then
                zenity --error --title="Error" --text="Updating the primary key column is not allowed."
                exit 1
            fi

            # Find the data type of the column
            datatype=$(grep "^$column:" ".$tablename.meta" | cut -d ':' -f 2)
            
            # Ask for the old value using zenity --entry
            while true; do
    old_value=$(zenity --entry --title="Enter Old Value" --text="Enter the old value for $column, ($datatype):")

    if [ $? -eq 1 ]; then
        exit 1
    fi

    # Check if the old value exists
    column_index=$(awk -F: 'NR==1 { for (i=1; i<=NF; i++) { if ($i == col) print i } }' col="$column" "$tablename")
if awk -F: -v col="$column_index" -v val="$old_value" 'NR>1 && $col == val { found=1; exit } END { exit !found }' $tablename; then
        break  # Exit the loop if the old value exists
    else
        zenity --error --title="Error" --text="Old value '$old_value' does not exist. Please enter a valid old value."
    fi
done

            # Ask for the new value using zenity --entry
            new_value=$(zenity --entry --title="Enter New Value" --text="Enter the new value for $column, ($datatype):")
            
            if [ $? -eq 1 ]; then
    zenity --info --title="Info" --text="Operation cancelled by user."
    exit 1
fi

            # Check the data type of the new value
    if [[ "$datatype" == "integer" && "$new_value" =~ ^[0-9]+$ ]] || [[ "$datatype" == "string" && "$new_value" =~ ^[a-zA-Z]+$ ]]; then
        # If the data type is correct, update the values
        awk -F: -v OFS=: -v col="$column" -v old_val="$old_value" -v new_val="$new_value" '
            BEGIN {colindex=-1}
            NR==1 {
                for(i=1; i<=NF; i++) {
                    if ($i == col) {
                        colindex = i
                    }
                }
            }
            $colindex == old_val {
                $colindex = new_val
            }
            {print}
        ' "$tablename" > temp && mv temp "$tablename"
        zenity --info --title="Success" --text="Records are updated."
            else
                zenity --error --title="Error" --text="Invalid datatype. Enter $datatype only."
            fi
            break
            ;;
        "Exit")
            exit 0
            ;;
        *)
            exit 1
            ;;
    esac
done
