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

    # Show options using zenity --list
    choice=$(zenity --list --title="Select an Operation" --column="Options" "Select all" "Select row by primary key" "Select column by column name")
    if [ -z "$choice" ]; then
        echo "No option selected. Exiting."
        exit 1
    fi

    case $choice in
        "Select all")
            zenity --text-info --title="All Rows" --filename="$tablename"
            ;;
        "Select row by primary key")
            primaryKeyInfo=$(grep -F ":PK" ".$tablename.meta")
            primaryKeyColumn=$(echo "$primaryKeyInfo" | cut -d ":" -f 1)
            primaryKeyDatatype=$(echo "$primaryKeyInfo" | cut -d ":" -f 2)

            primaryKeyValue=$(zenity --entry --title="Enter Primary Key" --text=" column name $primaryKeyColumn [$primaryKeyDatatype]")
          if [ -n "$primaryKeyValue" ]; then
    result=$(awk -F: -v pk="$primaryKeyValue" '{
        for(i=1; i<=NF; i++) {
            if ($i == pk) {
                print
                exit
            }
        }
    }' "$tablename")
    echo "$result" > result.txt
    zenity --text-info --title="Selected Row" --filename="result.txt"
    rm result.txt
else
    zenity --error --title="Error" --text="Invalid primary key value."
fi
            ;;
        "Select column by column name")
            # Display column names, primary key column name, and its datatype using zenity --info
columnNames=$(head -n 1 "$tablename")
IFS=':' read -r -a columns <<< "$columnNames"
columnList=""
for col in "${columns[@]}"; do
    columnList+="$col\n"
done


zenity --info --title="Column Names" --text="$columnList"

# Select column by column name using zenity --entry
columnName=$(zenity --entry --title="Enter Column Name" --text="Enter column name:" --entry-text "")

if [ -n "$columnName" ]; then
    # Get the first line of the table file
    firstLine=$(head -n 1 "$tablename")

    # Convert the first line into an array of column names
    IFS=':' read -r -a columns <<< "$firstLine"

    # Find the column number
    columnNumber=-1
    for index in "${!columns[@]}"; do
        if [[ "${columns[$index]}" == "${columnName}" ]]; then
            columnNumber=$((index+1))
            break
        fi
    done

    if [ "$columnNumber" -ne -1 ]; then
        result=$(awk -F: -v col="$columnNumber" '{print $col}' "$tablename")
        echo "$result" > result.txt
        zenity --text-info --title="Selected Column" --filename="result.txt"
        rm result.txt
    else
        zenity --error --title="Error" --text="Column '$columnName' not found."
    fi
else
    zenity --error --title="Error" --text="Invalid column name."
fi
            ;;
        *)
            zenity --error --title="Error" --text="Invalid choice. Exiting."
            ;;
    esac
else
    zenity --error --title="Error" --text="Table or metafile does not exist."
fi


