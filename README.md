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

## Status
Comparing against the upstream test suite:
```sh
info: Passed Tests:
info:  - ShadowLines.yarnc
info:  - Detours.yarnc
info:  - VariableStorage.yarnc
info:  - DecimalNumbers.yarnc
info:  - Jumps.yarnc
info:  - IfStatements.yarnc
info:  - Enums.yarnc
info:  - Functions.yarnc
info:  - Inference-FunctionsCalledWithConvertibleParameters.yarnc
info:  - VisitCount.yarnc
info:  - Lines.yarnc
info:  - VisitTracking.yarnc
error: Failed Tests:
error:  - NodeGroupVisitTracking.yarnc
error:  - Visited.yarnc
error:  - LineGroups.yarnc
error:  - Types.yarnc
error:  - Enums-FunctionsReturningStringMayBeComparedToAnyStringEnum.yarnc
error:  - InlineExpressions.yarnc
error:  - SmartVariables.yarnc
error:  - NodeGroupsWithImplicitDeclarations.yarnc
error:  - Escaping.yarnc
error:  - Once.yarnc
error:  - FormatFunctions.yarnc
error:  - Inference-FunctionsAndVarsInheritType.yarnc
error:  - ShortcutOptions.yarnc
error:  - NodeGroups.yarnc
error:  - Smileys.yarnc
error:  - Indentation.yarnc
error:  - Commands.yarnc
error:  - NodeGroupsContentQuerying.yarnc
info: Summary: 12 passed, 18 failed
```

## Updating Protobuf Mappings
To update for newer versions of yarn spinner:
 1. Grab the latest [yarn_spinner.proto](https://github.com/YarnSpinnerTool/YarnSpinner/blob/main/YarnSpinner/yarn_spinner.proto) file
 2. Run `zig build gen-proto` to new Zig mappings
 3. Profit!
