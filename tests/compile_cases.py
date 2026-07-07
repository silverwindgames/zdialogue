#!/usr/bin/env python3
# Runs the following command for all *.yarn files in the cases/ directory:
#   ysc compile <file>.yarn

import os
import subprocess


def main():
    # Get the path to the cases directory
    cases_dir = os.path.join(os.path.dirname(__file__), "cases")

    # Iterate over all .yarn files in the cases directory
    for filename in os.listdir(cases_dir):
        # Compile the file
        if filename.endswith(".yarn"):
            file_path = os.path.join(cases_dir, filename)
            print(f"Compiling {file_path}...")
            result = subprocess.run(
                ["ysc", "compile", file_path, "-o", "compiled"],
                capture_output=True,
                text=True,
            )
            if result.returncode != 0:
                print(f"Error compiling {file_path}:")
                print(result.stderr)
            else:
                print(f"Successfully compiled {file_path}.")

        # Copy it's .testplan too
        elif filename.endswith(".testplan"):
            file_path = os.path.join(cases_dir, filename)
            print(f"Copying {file_path} to compiled/...")
            subprocess.run(["cp", file_path, "compiled/"])


if __name__ == "__main__":
    main()
