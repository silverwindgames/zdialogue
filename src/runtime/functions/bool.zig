//! Reimplementations of Yarn's standard library in Zig
//! Bool functions sourced from: https://github.com/YarnSpinnerTool/YarnSpinner/blob/main/YarnSpinner/Types/BooleanType.cs
const std = @import("std");
const vm = @import("../vm.zig");

// Bool.EqualTo(bool1, bool2)
pub fn boolEqualTo(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.bool_value);
    std.debug.assert(params[1] == vm.Value.bool_value);

    const param1 = params[0].bool_value;
    const param2 = params[1].bool_value;

    const ret = param1 == param2;

    return .{ .bool_value = ret };
}

// Bool.NotEqualTo(bool1, bool2)
pub fn boolNotEqualTo(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    return .{ .bool_value = !(boolEqualTo(params, ctx).?.bool_value) };
}

// Bool.And(bool1, bool2)
pub fn boolAnd(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.bool_value);
    std.debug.assert(params[1] == vm.Value.bool_value);

    const param1 = params[0].bool_value;
    const param2 = params[1].bool_value;

    const ret = param1 and param2;

    return .{ .bool_value = ret };
}

// Bool.Or(bool1, bool2)
pub fn boolOr(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.bool_value);
    std.debug.assert(params[1] == vm.Value.bool_value);

    const param1 = params[0].bool_value;
    const param2 = params[1].bool_value;

    const ret = param1 or param2;

    return .{ .bool_value = ret };
}

// Bool.Xor(bool1, bool2)
pub fn boolXor(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.bool_value);
    std.debug.assert(params[1] == vm.Value.bool_value);

    const param1 = params[0].bool_value;
    const param2 = params[1].bool_value;

    const ret = param1 != param2;

    return .{ .bool_value = ret };
}

// Bool.Not(bool)
pub fn boolNot(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 1);
    std.debug.assert(params[0] == vm.Value.bool_value);

    const param1 = params[0].bool_value;

    const ret = !param1;

    return .{ .bool_value = ret };
}
