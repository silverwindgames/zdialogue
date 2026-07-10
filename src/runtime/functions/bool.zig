//! Reimplementations of Yarn's standard library in Zig
//! Bool functions sourced from: https://github.com/YarnSpinnerTool/YarnSpinner/blob/main/YarnSpinner/Types/BooleanType.cs
const std = @import("std");
const vm = @import("../vm.zig");

// Bool.Not(bool)
pub fn boolNot(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 1);
    std.debug.assert(params[0] == vm.Value.bool_value);

    const param1 = params[0].bool_value;

    const ret = !param1;

    return .{ .bool_value = ret };
}
