The tests are taken from [TestCases](https://github.com/YarnSpinnerTool/YarnSpinner/tree/main/Tests).

## Running tests
```sh
# Run all
zig build testplan

# Run one (provide path to yarnc file)
zig build testplan -- tests/compiled/Lines.yarnc
```

## Updating tests
In order to avoid having C# in the build system, the test cases are precompiled into protobuf files and associated data files (`<Name>-Lines.csv` and `<Name>-Metadata.csv` respectively), which are loaded by the Zig runtime. You can generate a new version by running the provided python script, so long as `ysc` is on your path.

```bash
cd tests/ # this directory
python3 compile_cases.py
```
