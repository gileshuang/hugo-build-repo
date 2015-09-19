#!/bin/bash

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

# Replace local ip by github site.
sed -i 's/127.0.0.1:1313/alienhjy.github.io/' config.toml

# Build the project.
hugo -t material-design # if using a theme, replace by `hugo -t <yourtheme>`

# Go To Public folder
cd public
# Pull public before commit
git pull
# Add changes to git.
git add -A

# Commit changes.
msg="rebuilding site `date`"
if [ $# -eq 1 ]
	then msg="$1"
fi
git commit -m "$msg"

# Push source and build repos.
git push origin master

# Come Back
cd ..

# Push hugo content source.
git add -A
git commit -m "$msg"
git push origin master

