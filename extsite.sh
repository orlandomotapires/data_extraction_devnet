#!/bin/bash

# Salve Araga!
# Student Name: Orlando Mota Pires
# Version: alpha0.2

# Description: This script installs and configures the Lynx browser, uses dialog to create an interactive interface,
#              and extracts data from a specific website using Lynx.

# Global variables
SITE_URL="https://www.example.com"
EXTRACTED_DATA="extracted_data.txt"

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
            for i in {1..10}; do
                sleep 1
                echo $((i * 10))
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

# Function to display the initial screen with dialog
initial_screen() {
    dialog --backtitle "Data Extraction Script" --title "Welcome" --msgbox "Welcome to the data extraction script!\nPress OK to continue." 10 50
}

# Function to get the URL from the user
get_url() {
    SITE_URL=$(dialog --backtitle "Data Extraction Script" --title "Enter URL" --inputbox "Enter the site URL:" 8 50 "https://www.example.com" 3>&1 1>&2 2>&3 3>&-)
}

# Function to display extracted data
display_data() {
    if [ -s "$EXTRACTED_DATA" ]; then
        dialog --backtitle "Data Extraction Script" --title "Extracted Data" --textbox "$EXTRACTED_DATA" 20 70
    else
        dialog --backtitle "Data Extraction Script" --title "Error" --msgbox "No data extracted. Please extract data first." 10 50
    fi
}

# Function to make the backup of the current data extracted
backup() {
    current_time=$(date +"%Y-%m-%d_%H-%M-%S")
    site_name=$(echo "$SITE_URL" | awk -F[/:] '{print $4}')
    backup_file="extracted_data_${site_name}_backup_$current_time.txt"
    cp "$EXTRACTED_DATA" "$backup_file"
    dialog --backtitle "Data Extraction Script" --title "Backup" --msgbox "Backup created: $backup_file" 10 50
}

# Function to display the main menu
main_menu() {
    while true; do
        option=$(dialog --backtitle "Data Extraction Script" --title "Main Menu" --menu "Choose an option:" 15 50 5 \
            1 "Extract Data from a Site" \
            2 "Display Extracted Data" \
            3 "Backup Extracted Data" \
            4 "Exit" 3>&1 1>&2 2>&3 3>&-)

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
