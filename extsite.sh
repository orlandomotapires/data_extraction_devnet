#!/bin/bash

# Save Araga!
# Student Name: Orlando Mota Pires
# Version: beta1.7

# Description: This script installs and configures the Lynx browser, uses dialog to create an interactive interface,
#              extracts data from a specific website using Lynx, filter and store its information using backup feature.

# Global variables
SITE_URL="https://www.example.com"
EXTRACTED_DATA="extracted_data.txt"
epochs=3

# Function to check and install lynx
install_lynx() {
    if ! command -v lynx &> /dev/null
    then
        echo "Lynx not found. Installing..."
        sudo apt-get update
        sudo apt-get install lynx -y
    else
        echo "Lynx is already installed."
    fi
}

# Function to extract data from the site using lynx with progress bar
extract_data() {
    # Check if the site exists
    if curl --output /dev/null --silent --head --fail "$SITE_URL"; then
        {
            for ((i=1; i<=epochs; i++)); do
                sleep 1
                echo $((i * 100 / epochs))
            done
        } | dialog --gauge "Extracting data from $SITE_URL..." 10 70 0

        # Data collection
        lynx -dump "$SITE_URL" > $EXTRACTED_DATA

        if [ $? -eq 0 ]; then
            dialog --backtitle "Data Extraction Script" --title "Success" --msgbox "Data extracted from the site $SITE_URL and saved in $EXTRACTED_DATA." 10 50
        else
            dialog --backtitle "Data Extraction Script" --title "Error" --msgbox "Failed to extract data from $SITE_URL." 10 50
        fi
    else
        dialog --backtitle "Data Extraction Script" --title "Error" --msgbox "The URL $SITE_URL is not accessible. Please check the URL and try again." 10 50
    fi
}

# Function to extract references (links) from the extracted data
extract_references() {
    local references_file="$1"
    # This regex matches URLs starting with http or https
    # This [^ ]+ means that will get anything that comes after the // that is not a blank space
    grep -Eo '(http|https)://[^ ]+' "$EXTRACTED_DATA" | sort | uniq >> "$references_file"
}

# Function to filter and transform the extracted data
filter_data() {
    current_time=$(date +"%Y-%m-%d_%H-%M-%S")
    site_name=$(echo "$SITE_URL" | awk -F[/:] '{print $4}')
    filtered_data_file="Extracted_data_${site_name}_filtered_$current_time.txt"
    
    filtered_data=()

    # Read and process each line from the extracted data file
    while IFS= read -r line; do
        # This regex matches lines with the pattern [number]text
        # \[       : Escapes the [ character
        # ([0-9]+) : Captures one or more digits and stores them in group 1
        # \]       : Escapes the ] character
        # (.*)     : Captures any character (except newline) zero or more times and stores them in group 2
        if [[ $line =~ \[([0-9]+)\](.*) ]]; then
            # The BASH_REAMTCH variable is a special variable in bash that allows you to get all the correspondencies of a regex expression
            # This can be combined with the $line =~ to enter the result of the correspondecies into the BASH_REAMTCH array
            # So for each part of the regex checking it will be stored in a position of the array BASH_REAMTCH
            number="${BASH_REMATCH[1]}"
            text="${BASH_REMATCH[2]}"
            filtered_data+=("$text:$number")
        fi
    done < "$EXTRACTED_DATA"

    # Save the transformed data to the file
    printf "%s\n" "${filtered_data[@]}" > "$filtered_data_file"

    # Append references to the filtered data file
    echo -e "\nReferences:\n" >> "$filtered_data_file"
    extract_references "$filtered_data_file"

    dialog --backtitle "Data Filtering Script" --title "Filtering" --msgbox "Data has been filtered: $filtered_data_file" 10 50
}

# Function to get the URL from the user
get_url() {
    SITE_URL=$(dialog --backtitle "Data Extraction Script" --title "Enter URL" --inputbox "Enter the site URL:" 8 50 "https://www.example.com" 3>&1 1>&2 2>&3 3>&-)
}

# Function to make the backup of the current data extracted
backup() {
    current_time=$(date +"%Y-%m-%d_%H-%M-%S")
    site_name=$(echo "$SITE_URL" | awk -F[/:] '{print $4}')
    backup_file="extracted_data_${site_name}_backup_$current_time.txt"
    cp "$EXTRACTED_DATA" "$backup_file"
    dialog --backtitle "Data Extraction Script" --title "Backup" --msgbox "Backup created: $backup_file" 10 50
}

# Dialog Functions =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

# Function to display the initial screen with dialog
initial_screen() {
    dialog --backtitle "Data Extraction Script" --title "Welcome" --msgbox "Welcome to the data extraction script!\nPress OK to continue." 10 50
}

# Function to display extracted data
display_data() {
    if [ -s "$EXTRACTED_DATA" ]; then
        dialog --backtitle "Data Extraction Script" --title "Extracted Data" --textbox "$EXTRACTED_DATA" 20 70
    else
        dialog --backtitle "Data Extraction Script" --title "Error" --msgbox "No data extracted. Please extract data first." 10 50
    fi
}

# Function to display the main menu
main_menu() {
    while true; do
        option=$(dialog --backtitle "Data Extraction Script" --title "Main Menu" --menu "Choose an option:" 15 50 5 \
            1 "Extract Data from a Site" \
            2 "Display Extracted Data" \
            3 "Backup Extracted Data" \
            4 "Filter Data" \
            5 "Exit" 3>&1 1>&2 2>&3 3>&-)

        case $option in
            1)
                get_url
                extract_data
                ;;
            2)
                display_data
                ;;
            3)
                backup
                ;;
            4)
                filter_data
                ;;
            5)
                break
                ;;
            *)
                dialog --backtitle "Data Extraction Script" --title "Error" --msgbox "Invalid option. Please try again." 10 50
                ;;
        esac
    done
}

# Script execution
initial_screen
install_lynx
main_menu

# Cleanup
rm -f $EXTRACTED_DATA
dialog --backtitle "Data Extraction Script" --title "Exit" --msgbox "Thank you for using the script. Goodbye!" 10 50
clear
