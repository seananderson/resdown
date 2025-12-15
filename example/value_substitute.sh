#!/bin/bash
# value_substitute.sh - Substitute values from values.txt into markdown files
# Usage: ./value_substitute.sh input.md
#
# Reads tag-value pairs from values.txt (format: "tag, value")
# Replaces all $tag$ occurrences in the input file with their values
# Outputs to input-valuesub.md (preserves original)
# Tags not found in values.txt are replaced with "MISSING"

if [ $# -ne 1 ]; then
    echo "Usage: $0 input_file.md"
    exit 1
fi

input_file="$1"
base="${input_file%.md}"
output_file="${base}-valuesub.md"
values_file="values.txt"

# Check if input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' not found"
    exit 1
fi

# Check if values file exists
if [ ! -f "$values_file" ]; then
    echo "Error: Values file '$values_file' not found"
    exit 1
fi

# Copy input to output
cp "$input_file" "$output_file"

# Find all tags in the input file
input_tags=$(grep -o '\$[^$]*\$' "$input_file" | sed 's/\$//g' | sort -u)

# Perform substitutions for each tag found in input
for tag in $input_tags; do
    # Look for this tag in values.txt
    value=$(grep "^${tag}," "$values_file" | head -n1 | cut -d',' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [ -n "$value" ]; then
        # Tag exists in values.txt - substitute the value
        sed -i '' 's/\$'"$tag"'\$/'"$value"'/g' "$output_file"
    else
        # Tag not found in values.txt - mark as MISSING
        echo "Warning: Tag '$tag' not found in $values_file, substituting with 'MISSING'"
        sed -i '' 's/\$'"$tag"'\$/MISSING/g' "$output_file"
    fi
done

echo "Created $output_file with substituted values"
