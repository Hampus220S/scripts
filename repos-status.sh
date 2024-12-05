#!/bin/bash

#
# repos-status.sh
#
# Written by Hampus Fridholm
#
# Last updated 2024-12-05
#

# Default values for arguments 
verbose=false
dirty=false

# Parse command-line arguments
while [[ "$1" =~ ^- ]]; do
  case "$1" in
    --verbose)
      verbose=true
      ;;
    --dirty)
      dirty=true
      ;;
    *)
      echo "Usage: $0 [--verbose] [--dirty]"
      exit 1
      ;;
  esac
  shift
done

func_dirty() {
  # Loop through each item in the current directory
  for dir in */; do
    # Check if it's a Git repository by looking for .git folder
    if [ -d "$dir/.git" ]; then
      clean=true

      # Run `git status --short` and check if there are any changes
      if git -C "$dir" status --porcelain | grep -q .; then
        # Print the repository name
        if [ "$clean" = true ]; then
          repo=$(basename "$dir")
          echo -e "\033[1;36m$repo\033[0m"
        fi

        clean=false

        echo "Uncommitted changes"
        git -C "$dir" status --short
      fi
      
      # Check if the repository has any commits by running `git log` or checking HEAD
      if git -C "$dir" rev-list --count HEAD >/dev/null 2>&1 && [ $(git -C "$dir" rev-list --count HEAD) -gt 0 ]; then
        # Get the current branch
        branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD)
        
        # Fetch the latest changes from the remote (without merging)
        # git -C "$dir" fetch --quiet
        
        # Check if the remote branch exists
        if git -C "$dir" rev-parse --quiet "origin/$branch" >/dev/null 2>&1; then
          local_commit=$(git -C "$dir" rev-parse "$branch")
          remote_commit=$(git -C "$dir" rev-parse "origin/$branch")
          
          # Check if local branch is ahead of remote (unpushed changes)
          if [ "$local_commit" != "$remote_commit" ]; then
            # Check if there are unpushed commits
            if git -C "$dir" log origin/"$branch"..HEAD --oneline | grep -q .; then
              # Print the repository name
              if [ "$clean" = true ]; then
                repo=$(basename "$dir")
                echo -e "\033[1;36m$repo\033[0m"
              fi

              clean=false

              echo "Unpushed commits in branch $branch:"
              git -C "$dir" log origin/"$branch"..HEAD --oneline --no-decorate
            fi
          fi
        fi
      fi
      if [ "$clean" = false ]; then echo; fi
    fi
  done
}

func_default() {
  # Loop through each item in the current directory
  for dir in */; do
    # Check if it's a Git repository by looking for .git folder
    if [ -d "$dir/.git" ]; then
      # Print the repository name
      repo=$(basename "$dir")
      echo -e "\033[1;36m$repo\033[0m"

      clean=true

      # Run `git status --short` and check if there are any changes
      if git -C "$dir" status --porcelain | grep -q .; then
        clean=false
        echo "Uncommitted changes"
        git -C "$dir" status --short

      else # if no changes exist
        if [ "$verbose" = true ]; then
          echo "All changes are committed"
        fi
      fi
      
      # Check if the repository has any commits by running `git log` or checking HEAD
      if git -C "$dir" rev-list --count HEAD >/dev/null 2>&1 && [ $(git -C "$dir" rev-list --count HEAD) -gt 0 ]; then
        # Get the current branch
        branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD)
        
        # Fetch the latest changes from the remote (without merging)
        # git -C "$dir" fetch --quiet
        
        # Check if the remote branch exists
        if git -C "$dir" rev-parse --quiet "origin/$branch" >/dev/null 2>&1; then
          local_commit=$(git -C "$dir" rev-parse "$branch")
          remote_commit=$(git -C "$dir" rev-parse "origin/$branch")
          
          # Check if local branch is ahead of remote (unpushed changes)
          if [ "$local_commit" != "$remote_commit" ]; then
            # Check if there are unpushed commits
            if git -C "$dir" log origin/"$branch"..HEAD --oneline | grep -q .; then
              clean=false
              echo "Unpushed commits in branch $branch:"
              git -C "$dir" log origin/"$branch"..HEAD --oneline --no-decorate

            else # if there are unmerged remote commits
              clean=false
              echo "Unmerged remote commits in branch $branch"
            fi

          else # if local commit and remote commit are the same
            if [ "$verbose" = true ]; then
              echo "Up to date with remote branch $branch"
            fi
          fi

        else # if no remote branch exists
          if [ "$verbose" = true ]; then
            echo "No remote branch for local branch $branch"
          fi
        fi

      else # if repository has no commits
        if [ "$verbose" = true ]; then
          echo "Repository has no commits"
        fi
      fi
      
      # If repository is "clean", output that
      if [ "$clean" = true ]; then
        echo "Repository is clean"
      fi

      echo
    fi
  done
}

if [ "$dirty" = true ]; then 
  func_dirty
else
  func_default
fi
