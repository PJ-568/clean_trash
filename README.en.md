# Trash Cleaner Script

[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC%20BY--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)

> [简体中文](README.md) | English

A script to clean files in the trash that have been kept for more than a specified number of days.

```bash
Trash Cleaner Tool
Usage: ./clean_trash.sh [-h] [-v] <days to keep>
Options:
  -h  Show help message
  -v  Verbose output mode
Examples:
  ./clean_trash.sh 30    # Clean trash files older than 30 days
  ./clean_trash.sh -v 7  # Verbose mode to clean files older than 7 days
```

## Contributing

[Contribution Guide](CONTRIBUTING.md)

## Overview of Linux Trash Mechanism

When you "delete" a file in a Linux desktop environment, it moves the file to a special "trash" directory, which is usually `~/.local/share/Trash/`.
The trash directory typically contains three subdirectories:

- `files/`: Stores the deleted **files** themselves. For example: `question.png`.
- `info/`: Stores **metadata** related to the deleted files (such as the original path, deletion timestamp, etc.). For example:

  ```plaintext ~/.local/share/Trash/info/question.png.trashinfo
  [Trash Info]
  Path=/home/user/question.png
  DeletionDate=2025-08-13T19:47:35
  ```

- `expunged/`: Temporarily stores files that are to be **permanently deleted**.

### Purpose of the `expunged` Folder

- **"Permanent Deletion" Operation:** When you decide to empty the trash (select the "Empty Trash" menu item in the file manager), the desktop environment does not simply delete all the contents of the `files/` and `info/` directories.
- **Marking Process:** It first **moves** the corresponding files in the `files/` directory to the `~/.local/share/Trash/expunged/` directory (because moving files is fast).
- **Physical Deletion:** Then, it **physically deletes** the corresponding metadata files in the `info/` directory; and slowly **physically deletes** the corresponding files in the `expunged/` directory (deleting a large number of files takes time, and doing it too quickly may slow down the entire computer).