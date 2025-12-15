#!/bin/bash

# Script to count words between <!--start count--> and <!--end count--> tags
# and substitute XX with the word count on the line two lines above the start tag

# Function to process a single file
process_file() {
    local input_file="$1"
    local output_file="${input_file%.md}-sub.md"

    echo "Processing: $input_file -> $output_file"

    # Create a temporary file for processing
    local temp_file=$(mktemp)
    cp "$input_file" "$temp_file"

    # Find all start tags and their line numbers
    local start_lines=($(grep -n "<!--start count-->" "$input_file" | cut -d: -f1))

    # Process each start/end pair
    for start_line in "${start_lines[@]}"; do
        echo "Found start tag at line $start_line"

        # Find the corresponding end tag
        local end_line=$(tail -n +$((start_line + 1)) "$input_file" | grep -n "<!--end count-->" | head -1 | cut -d: -f1)
        if [ -z "$end_line" ]; then
            echo "Warning: No matching end tag found for start tag at line $start_line"
            continue
        fi

        # Calculate actual end line number
        end_line=$((start_line + end_line))
        echo "Found end tag at line $end_line"

        # Extract text between start and end tags (exclusive)
        local content=$(sed -n "$((start_line + 1)),$((end_line - 1))p" "$input_file")

        # Count words in the content
        local word_count=$(echo "$content" | wc -w | tr -d ' ')
        echo "Word count: $word_count"

        # Find the line two lines above the start tag (where XX should be replaced)
        local target_line=$((start_line - 2))
        if [ $target_line -lt 1 ]; then
            echo "Warning: Target line $target_line is invalid (less than 1)"
            continue
        fi

        # Check if XX exists on the target line
        local target_content=$(sed -n "${target_line}p" "$temp_file")
        if [[ ! "$target_content" =~ XX ]]; then
            echo "ERROR: No 'XX' found on line $target_line (2 lines above start tag at line $start_line)"
            echo "       Line $target_line contains: '$target_content'"
            echo "       Did you forget to remove blank lines between the header and <!--start count-->?"
            rm "$temp_file"
            exit 1
        fi

        echo "Replacing XX on line $target_line with $word_count"

        # Replace XX with word count on the target line
        sed -i "" "${target_line}s/XX/$word_count/" "$temp_file"
    done

    # Copy the processed file to the output location
    cp "$temp_file" "$output_file"
    rm "$temp_file"

    echo "Created: $output_file"
}

# Main script logic
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file1.md> [file2.md] ..."
    echo "       $0 *.md  # Process all .md files"
    exit 1
fi

# Process each file provided as argument
for file in "$@"; do
    if [ -f "$file" ] && [[ "$file" == *.md ]]; then
        process_file "$file"
    else
        echo "Skipping: $file (not a .md file or doesn't exist)"
    fi
done

echo "Processing complete!"