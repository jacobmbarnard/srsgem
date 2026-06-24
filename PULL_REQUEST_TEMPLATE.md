# Allow organizing project assets into folders

## Description
This PR implements support for organizing project assets into folders, addressing issue #4.

## Changes
- **FileManager**: Added `all_files_recursive()` method to recursively scan for files in subdirectories
  - Excludes special directories (`.srsgem`, `output`, `.git`)
  - Returns files in lexicographic order
  - Handles permission errors gracefully

- **SRSBuilder**: Updated all file discovery methods to use recursive scanning
  - `assembled_markdown()`: Now finds markdown files in nested directories
  - `yaml_file_names()`: Discovers YAML files in subdirectories
  - `export_svgs_from_plantuml()`: Processes PlantUML files from any depth
  - `copy_resources()`: Handles resource files from nested directories

## Benefits
- Users can now organize their markdown, YAML, and PlantUML files into logical folder structures
- Maintains backward compatibility - flat directory structures still work
- Files are still processed in lexicographic order across all directories
- Cleaner project organization for complex SRS documents

## Testing
The implementation:
- Maintains the existing flat directory structure support
- Recursively discovers files at any depth
- Preserves file ordering across directories
- Excludes system directories to avoid scanning unnecessary files

## Related Issues
Closes #4
