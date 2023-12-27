#!/bin/bash

# Input file paths for source and destination folders
# This defines a variable source_file that holds the path to the file containing the list of source folders to be moved
source_file="/home/hadoop/praveen/misshrtbt/input/missing-hrtbt.txt"
# This defines a variable destination_file that holds the path to the file containing the list of destination folders for the objects to be moved.
destination_file="/home/hadoop/praveen/misshrtbt/input/prod_path.txt"

# This defines a variable log_file and error_log that holds the path to the log file where errors and code execution details will be logged.
log_file="/home/hadoop/praveen/misshrtbt/logs/log.txt"
error_log="/home/hadoop/praveen/misshrtbt/logs/error_log.txt"

#This defines a function named log_error that takes an error message as an argument and appends it with a timestamp to the log file.
log_error() {
  echo "[ERROR] $(date): $1" >> "$error_log"
}

# This defines a function named log_code that takes a code execution message as an argument and appends it with a timestamp to the log file.
log_code() {
  echo "[LOG] $(date): $1" >> "$log_file"
}
# This checks if the source and destination files exist by using the -f flag with the [ (test) command. 
# If either of the files does not exist, the script logs an error and exits with a status code of 1.
if [ ! -f "$source_file" ] || [ ! -f "$destination_file" ]; then
  log_error "Source or destination file not found."
  exit 1
fi

# This sets up a loop that reads lines from the source and destination files, with one line at a time. 
# The IFS= before read commands prevents leading/trailing whitespaces from being trimmed, and read -r prevents backslashes from being interpreted as escape characters.
while IFS= read -r source_folder && IFS= read -r destination_folder <&3; do

# This logs a code execution message with the source and destination folders being processed.
  log_code "Moving objects from '$source_folder' to '$destination_folder'"
  
  # This is an AWS CLI command using the aws s3 move command to move objects from the source folder to the destination folder. 
  aws s3 mv "$source_folder" "$destination_folder" --recursive --sse aws:kms --sse-kms-key-id e18cb522-8757-4623-bd77-8ef0a871e188 >> /home/hadoop/praveen/misshrbt/logs/log.txt

  # This checks the exit status of the previously executed command using the special shell variable $?, 
  # Which holds the exit status of the last executed command. If the exit status is not 0, indicating an error, the script logs an error.
  if [ "$?" -ne 0 ]; then
  # This logs an error message indicating that the move operation failed for the current source and destination folders.
    log_error "Failed to move objects from '$source_folder' to '$destination_folder'"
  # If the previous if condition is not met, meaning the move operation was successful, the script logs a code execution message indicating the successful move.
  else
  # This logs a code execution message indicating that the move operation was successful for the current source and destination folders.
    log_code "Successfully moved objects from '$source_file' to '$destination_file'"
    echo "$log_code"
  fi
# This marks the end of the while loop and specifies that the input for the source file comes from the file defined by $source_file, 
# and the input for the destination file comes from the file defined by $destination_file. The 3< before the destination file indicates that file  
done < "$source_file" 3< "$destination_file"

log_code "Script execution completed."