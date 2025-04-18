#!/bin/bash
# Setup passwordless SSH to the server

# Check if SSH key exists, generate if not
if [ ! -f ~/.ssh/id_rsa ]; then
  echo "Generating SSH key pair..."
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
  echo "SSH key pair generated."
fi

# Copy the SSH public key to the server
echo "Copying SSH public key to server at 107.175.249.182..."
echo "You will need to enter the server password one last time."
ssh-copy-id root@107.175.249.182

echo "Testing passwordless SSH connection..."
ssh -o BatchMode=yes root@107.175.249.182 echo "Passwordless SSH is now configured!"

echo "Done! You should now be able to SSH to your server without a password."
