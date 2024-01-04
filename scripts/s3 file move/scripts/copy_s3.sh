# This defines a variable source_path that holds the path to the file containing the list of source folders to be moved
source_path="$pwd../inputs/source.txt"
# This defines a variable destination_path that holds the path to the file containing the list of destination folders for the objects to be moved.
destination_path="$pwd../inputs/dest.txt"
#kms ey used to encrypt the objects
kms_key="arn:aws:kms:us-west-2:867396380247:key/94ca1e91-52a1-4a34-937f-d2364122adeb"
# This defines a variable log_file and error_log that holds the path to the log file where errors and code execution details will be logged.
log_file="$pwd../log/log.txt"
error_log="$pwd../log/error_log.txt"
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
if [ ! -f "$source_path" ] || [ ! -f "$destination_path" ]; then
  log_error "Source or destination file not found."
  exit 1
fi
# This sets up a loop that reads lines from the source and destination files, with one line at a time.
# The IFS= before read commands prevents leading/trailing whitespaces from being trimmed, and read -r prevents backslashes from being interpreted as escape characters.
while IFS= read -r source_path && IFS= read -r destination_path <&3; do
# This logs a code execution message with the source and destination folders being processed.
  echo "Copying objects from '$source_path' to '$destination_path'"
  # This is an AWS CLI command using the aws s3 move command to move objects from the source folder to the destination folder.
  aws s3 sync  "$source_path" "$destination_path"  --sse-kms-key-id "$kms_key"  --sse aws:kms  >> "$log_file"
  # Which holds the exit status of the last executed command. If the exit status is not 0, indicating an error, the script logs an error.
  if [ "$?" -ne 0 ]; then
  # This logs an error message indicating that the move operation failed for the current source and destination folders.
    log_error "Failed to copy objects from '$source_path' to '$destination_path'"
  # If the previous if condition is not met, meaning the move operation was successful, the script logs a code execution message indicating the successful move.
  else
  # This logs a code execution message indicating that the move operation was successful for the current source and destination folders.
        echo "$log_code"
  fi
done < "$source_path" 3< "$destination_path"
echo "Script execution completed."