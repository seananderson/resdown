#!/bin/bash

# Script to sum subsection word counts within each CONTEXT section
# and substitute XX with the total in each CONTEXT header

# Function to process a single file
process_file() {
    local input_file="$1"
    local output_file="${input_file%.md}-contextsums.md"

    echo "Processing: $input_file -> $output_file"

    # Create a temporary file for processing
    local temp_file=$(mktemp)
    cp "$input_file" "$temp_file"

    # Find all CONTEXT section headers and their line numbers
    local context_lines=($(grep -n "^# CONTEXT:" "$input_file" | cut -d: -f1))

    # Process each CONTEXT section
    for i in "${!context_lines[@]}"; do
        local context_line=${context_lines[$i]}
        echo "Found CONTEXT section at line $context_line"

        # Determine the end of this CONTEXT section (start of next CONTEXT or end of file)
        local next_context_line=""
        if [ $((i + 1)) -lt ${#context_lines[@]} ]; then
            next_context_line=${context_lines[$((i + 1))]}
        else
            next_context_line=$(wc -l < "$input_file" | tr -d ' ')
            next_context_line=$((next_context_line + 1))
        fi

        echo "CONTEXT section spans lines $context_line to $((next_context_line - 1))"

        # Extract the section content
        local section_content=$(sed -n "${context_line},$((next_context_line - 1))p" "$input_file")

        # Find all subsection headers with word counts in this section
        # Look for lines like "## Subsection (123 words)"
        local word_counts=($(echo "$section_content" | grep -o "^## .* (\([0-9]\+\) words)" | grep -o "([0-9]\+ words)" | grep -o "[0-9]\+"))

        echo "Found word counts in this section: ${word_counts[*]}"

        # Sum the word counts
        local total=0
        for count in "${word_counts[@]}"; do
            total=$((total + count))
        done

        echo "Total word count for this CONTEXT: $total"

        # Replace XX in the CONTEXT header with the total
        if [ $total -gt 0 ]; then
            echo "Replacing XX on line $context_line with $total"
            sed -i "" "${context_line}s/XX/$total/" "$temp_file"
        else
            echo "No word counts found in this section, skipping replacement"
        fi
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