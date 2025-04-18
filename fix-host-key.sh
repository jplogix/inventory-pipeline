#!/bin/bash
# Script to update SSH known hosts for SFTP access

echo "Removing old SFTP host key from known_hosts file..."
ssh-keygen -R "[107.175.249.182]:2222"

echo "Done! Now try connecting again with:"
echo "sftp -P 2222 finaleftp@107.175.249.182"
