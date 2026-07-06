# Zig Runtime for Yarn Spinner

## Updating Protobuf Mappings
To update for newer versions of yarn spinner:
 1. Grab the latest [yarn_spinner.proto](https://github.com/YarnSpinnerTool/YarnSpinner/blob/main/YarnSpinner/yarn_spinner.proto) file
 2. Run `zig build gen-proto` to new Zig mappings
 3. Profit!
