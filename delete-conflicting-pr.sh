#!/bin/bash

# Set the repository (format: owner/repo)
REPO="dnegreira/os"

# Fetch all open pull requests with detailed information
# https://docs.github.com/en/graphql/reference/enums#mergeablestate
echo "Fetching open pull requests for $REPO..."
PR_LIST=$(gh pr list --repo $REPO --state open --json number,headRepositoryOwner,headRefName,author,mergeable --jq '.[] | select(.mergeable == "CONFLICTING") | "\(.number) \(.headRepositoryOwner.login) \(.author.login) \(.headRefName)"')

# Check if there are any PRs with conflicts
if [[ -z "$PR_LIST" ]]; then
  echo "No pull requests with merge conflicts found."
  exit 0
fi

echo "Pull requests with merge conflicts:"
IFS=$'\n'  # Set Internal Field Separator to newline for the for loop
for PR_INFO in $PR_LIST; do
  PR_NUMBER=$(echo "$PR_INFO" | awk '{print $1}')
  REPO_OWNER=$(echo "$PR_INFO" | awk '{print $2}')
  PR_OWNER=$(echo "$PR_INFO" | awk '{print $3}')
  BRANCH_NAME=$(echo "$PR_INFO" | awk '{print $4}')

  echo "PR #$PR_NUMBER in $REPO by @$PR_OWNER (branch: $BRANCH_NAME)"

  # Prompt to delete the PR and branch
  read -p "Do you want to delete PR #$PR_NUMBER and branch '$BRANCH_NAME'? (y/n): " DELETE_CONFIRM
  if [[ "$DELETE_CONFIRM" == "y" || "$DELETE_CONFIRM" == "Y" ]]; then
    echo "Deleting PR #$PR_NUMBER and branch '$BRANCH_NAME'..."

    # Delete the PR and branch
    gh pr close $PR_NUMBER --repo $REPO --delete-branch -c "Deleting to let automation create the PR again."

    # Verify deletion
    if [[ $? -eq 0 ]]; then
      echo "PR #$PR_NUMBER and branch '$BRANCH_NAME' deleted successfully."
    else
      echo "Failed to delete PR #$PR_NUMBER and branch '$BRANCH_NAME'."
    fi
  else
    echo "Skipping deletion of PR #$PR_NUMBER and branch '$BRANCH_NAME'."
  fi
done
