//! Reimplementations of Yarn's standard library in Zig
//! Number functions sourced from: https://github.com/YarnSpinnerTool/YarnSpinner/blob/main/YarnSpinner/Types/NumberType.cs
const std = @import("std");
const vm = @import("../vm.zig");

// Number.EqualTo(num1, num2)
pub fn numberEqualTo(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;

    const ret = param1 == param2;

    return .{ .bool_value = ret };
}

// Number.Add(num1, num2)
pub fn numberAdd(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;

    const ret = param1 + param2;

    return .{ .float_value = ret };
}

// Number.Subtract(num1, num2)
pub fn numberSubtract(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;

    const ret = param1 - param2;

    return .{ .float_value = ret };
}

// Number.Divide(num1, num2)
pub fn numberDivide(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;

    const ret = param1 / param2;

    return .{ .float_value = ret };
}

// Number.Multiply(num1, num2)
pub fn numberMultiply(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;

    const ret = param1 * param2;

    return .{ .float_value = ret };
}

// Number.Modulus(num1, num2)
pub fn numberModulus(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1: i64 = @intFromFloat(params[0].float_value);
    const param2: i64 = @intFromFloat(params[1].float_value);

    // @mod? @rem?
    // Have a read of https://torstencurdt.com/tech/modulo-of-negative-numbers/
    // C# uses "truncated division" for modulus, so we need @rem instead of @mod to match it.
    const ret = @rem(param1, param2);

    return .{ .float_value = @floatFromInt(ret) };
}

// Number.UnaryMinus(num)
pub fn numberUnaryMinus(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 1);
    std.debug.assert(params[0] == vm.Value.float_value);

    const param1 = params[0].float_value;

    const ret = -param1;

    return .{ .float_value = ret };
}

// Number.GreaterThan(num1, num2)
pub fn numberGreaterThan(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;

    const ret = param1 > param2;

    return .{ .bool_value = ret };
}

// Number.GreaterThanOrEqualTo(num1, num2)
pub fn numberGreaterThanOrEqualTo(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;

    const ret = param1 >= param2;

    return .{ .bool_value = ret };
}

// Number.LessThan(num1, num2)
pub fn numberLessThan(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;

    const ret = param1 < param2;

    return .{ .bool_value = ret };
}

// Number.LessThanOrEqualTo(num1, num2)
pub fn numberLessThanOrEqualTo(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;

    const ret = param1 <= param2;

    return .{ .bool_value = ret };
}
