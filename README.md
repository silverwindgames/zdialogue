# zdialogue - Yarn Spinner-compatible Zig runtime

A dialogue engine written in Zig, compatible with the [Yarn Spinner](https://yarnspinner.dev/) dialogue format.

In heavy development - not usable yet!

## Features
zdialogue is a Zig-native runtime for the Yarn Spinner format.

What you get:
 * Yarn Spinner-compatible runtime with virtual machine, options, etc.
 * Zig-native protobuf mappings for the Yarn Spinner format, generated from the official `.proto` file

What this isn't:
 * A compiler for Yarn Spinner. Just use the official one - it's great :)

## Licensing
This project is not affiliated with Yarn Spinner.

Yarn Spinner® is a trademark of Secret Lab Pty. Ltd., the original creators, and is licensed to Yarn Spinner Pty. Ltd, which is a spinoff company to look after the project.

zdialogue, like Yarn Spinner, is MIT licensed. See LICENSE for exact terms.


## Updating Protobuf Mappings
To update for newer versions of yarn spinner:
 1. Grab the latest [yarn_spinner.proto](https://github.com/YarnSpinnerTool/YarnSpinner/blob/main/YarnSpinner/yarn_spinner.proto) file
 2. Run `zig build gen-proto` to new Zig mappings
 3. Profit!
