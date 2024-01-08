#!/bin/bash

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

# Get the table name using a zenity entry dialog
nameOfTable=$(zenity --entry --title="Table Creation" --text="Enter your table name:")

while ! validate_table_name "$nameOfTable"
do
    nameOfTable=$(zenity --entry --title="Table Creation" --text="Enter your table name:")

done

# Get the number of columns in the table using a zenity entry dialog
numOfColumns=$(zenity --entry --title="Table Creation" --text="No. of columns?")
while ! [[ "$numOfColumns" =~ ^[1-9][0-9]*$ ]]
do
    zenity --error --title="Error" --text="Please use a valid number."
    numOfColumns=$(zenity --entry --title="Table Creation" --text="No. of columns?")
done

# Array to store column names
columnNames=()

# Flag to track if a primary key has been set
primaryKeySet=false

# Loop to get the column information
for (( i = 0 ; i < $numOfColumns ; i++ ))
do
    # Get the column name using a zenity entry dialog
    columnName=$(zenity --entry --title="Table Creation" --text="Enter Column $((i+1)) Name:")
    while ! validate_column_name "$columnName" || [[ "${columnNames[*]}" =~ "$columnName" ]]; do
        if ! validate_column_name "$columnName"; then
            zenity --error --title="Error" --text="Invalid column name."
        else
            zenity --error --title="Error" --text="Column name must be unique within the table."
        fi
        columnName=$(zenity --entry --title="Table Creation" --text="Enter Column $((i + 1)) Name:")
    done
    columnNames+=("$columnName")

    # Get the datatype of the input using a zenity list dialog
    dataType=$(zenity --list --title="Table Creation" --text="Enter the data type for column $columnName:" --column="Options" "integer" "string")
    while [[ "$dataType" != "integer" && "$dataType" != "string" ]]
    do
        zenity --error --title="Error" --text="Invalid option. Please enter 'integer' or 'string'."
        dataType=$(zenity --list --title="Table Creation" --text="Enter the data type for column $columnName:" --column="Options" "integer" "string")
    done

if [ "$primaryKeySet" == false ]
then
    # If it's a primary key, ask using a zenity question dialog
    zenity --question --title="Table Creation" --text="Is this a primary key for table $nameOfTable?"
    isPrimaryKey=$?
    if [ "$isPrimaryKey" -eq 0 ]; then
        echo "$columnName:$dataType:PK" >> ".$nameOfTable.meta"
        primaryKeySet=true
    else
        echo "$columnName:$dataType" >> ".$nameOfTable.meta"
    fi
else
    echo "$columnName:$dataType" >> ".$nameOfTable.meta"
fi
done

# Check if any of the columns is a primary key
if [ "$primaryKeySet" == false ]; then
    zenity --error --title="Error" --text="Error: At least one column must be a primary key."
rm $nameOfTable
rm ".$nameOfTable.meta"
    exit 1
fi

# Create the table and echo success
echo "${columnNames[*]}" | tr ' ' ':' >> "$nameOfTable"
zenity --info --title="Success" --text="Table '$nameOfTable' created successfully."

