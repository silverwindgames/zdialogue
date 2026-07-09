const std = @import("std");
const vm = @import("vm.zig");

hash_map: std.StringHashMap(vm.YarnFn),
allocator: std.mem.Allocator,

const Self = @This();

fn boolNot(param: bool) bool {
    return !param;
}

// Bool.Not
fn boolNotYarnFn(params: []vm.Value) ?vm.Value {
    std.debug.assert(params.len == 1);
    std.debug.assert(params[0] == vm.Value.bool_value);

    const param1 = params[0].bool_value;

    const ret = boolNot(param1);

    return .{ .bool_value = ret };
}

// Number.EqualTo
fn number_equal_to(params: []vm.Value) ?vm.Value {
    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;

    const ret = param1 == param2;

    return .{ .bool_value = ret };
}

// Number.Add
fn number_add(params: []vm.Value) ?vm.Value {
    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;

    const ret = param1 + param2;

    return .{ .float_value = ret };
}

// Number.Subtract
fn number_subtract(params: []vm.Value) ?vm.Value {
    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;

    const ret = param1 - param2;

    return .{ .float_value = ret };
}

// Number.Divide
fn number_divide(params: []vm.Value) ?vm.Value {
    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;

    const ret = param1 / param2;

    return .{ .float_value = ret };
}

// Number.Multiply
fn number_multiply(params: []vm.Value) ?vm.Value {
    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;

    const ret = param1 * param2;

    return .{ .float_value = ret };
}

// Number.Modulus
fn number_modulus(params: []vm.Value) ?vm.Value {
    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1: i64 = @intFromFloat(params[0].float_value);
    const param2: i64 = @intFromFloat(params[1].float_value);

    // @mod? @rem? Have a read of https://torstencurdt.com/tech/modulo-of-negative-numbers/
    // C# uses "truncated division" for modulus, so we need @rem instead of @mod to match it.
    const ret = @rem(param1, param2);

    return .{ .float_value = @floatFromInt(ret) };
}

// Number.UnaryMinus
fn number_unary_minus(params: []vm.Value) ?vm.Value {
    std.debug.assert(params.len == 1);
    std.debug.assert(params[0] == vm.Value.float_value);

    const param1 = params[0].float_value;

    const ret = -param1;

    return .{ .float_value = ret };
}

// Number.GreaterThan
fn number_greater_than(params: []vm.Value) ?vm.Value {
    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;

    const ret = param1 > param2;

    return .{ .bool_value = ret };
}

// Number.GreaterThanOrEqualTo
fn number_greater_than_or_equal_to(params: []vm.Value) ?vm.Value {
    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;

    const ret = param1 >= param2;

    return .{ .bool_value = ret };
}

// Number.LessThan
fn number_less_than(params: []vm.Value) ?vm.Value {
    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;

    const ret = param1 < param2;

    return .{ .bool_value = ret };
}

// Number.LessThanOrEqualTo
fn number_less_than_or_equal_to(params: []vm.Value) ?vm.Value {
    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;

    const ret = param1 <= param2;

    return .{ .bool_value = ret };
}

// Enum.EqualTo
fn enum_equal_to(params: []vm.Value) ?vm.Value {
    std.debug.assert(params.len == 2);

    const ret: bool = switch (params[0]) {
        .string_value => |a_str| blk: {
            std.debug.assert(params[1] == vm.Value.string_value);
            break :blk std.mem.eql(u8, a_str.str, params[1].string_value.str);
        },
        else => blk: {
            std.debug.assert(params[0] == vm.Value.float_value);
            std.debug.assert(params[1] == vm.Value.float_value);
            break :blk params[0].float_value == params[1].float_value;
        },
    };

    return .{ .bool_value = ret };
}

// Enum.NotEqualTo
fn enum_not_equal_to(params: []vm.Value) ?vm.Value {
    return .{ .bool_value = !(enum_equal_to(params).?.bool_value) };
}

// Test Only: Add Three Operands
// TODO: Move to tests/ directory
fn add_three_operands(params: []vm.Value) ?vm.Value {
    std.debug.assert(params.len == 3);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);
    std.debug.assert(params[2] == vm.Value.float_value);

    const param1 = params[0].float_value;
    const param2 = params[1].float_value;
    const param3 = params[2].float_value;

    const ret = param1 + param2 + param3;

    return .{ .float_value = ret };
}

fn registerFunction(self: *Self, name: []const u8, func: vm.YarnFn) !void {
    const key = try self.allocator.dupe(u8, name);
    try self.hash_map.put(key, func);
}

pub fn init(allocator: std.mem.Allocator) !Self {
    var func_lib = Self{
        .hash_map = std.StringHashMap(vm.YarnFn).init(allocator),
        .allocator = allocator,
    };

    // Register Standard Library
    try func_lib.registerFunction("Bool.Not", &boolNotYarnFn);
    try func_lib.registerFunction("Number.EqualTo", &number_equal_to);
    try func_lib.registerFunction("Number.Add", &number_add);
    try func_lib.registerFunction("Number.Subtract", &number_subtract);
    try func_lib.registerFunction("Number.Divide", &number_divide);
    try func_lib.registerFunction("Number.Multiply", &number_multiply);
    try func_lib.registerFunction("Number.Modulus", &number_modulus);
    try func_lib.registerFunction("Number.UnaryMinus", &number_unary_minus);
    try func_lib.registerFunction("Number.GreaterThan", &number_greater_than);
    try func_lib.registerFunction("Number.GreaterThanOrEqualTo", &number_greater_than_or_equal_to);
    try func_lib.registerFunction("Number.LessThan", &number_less_than);
    try func_lib.registerFunction("Number.LessThanOrEqualTo", &number_less_than_or_equal_to);
    try func_lib.registerFunction("Enum.EqualTo", &enum_equal_to);
    try func_lib.registerFunction("Enum.NotEqualTo", &enum_not_equal_to);

    // TEST ONLY
    // TODO: Should be declared in the tests directory
    try func_lib.registerFunction("add_three_operands", &add_three_operands);

    return func_lib;
}

pub fn getFunction(self: *Self, name: []const u8) ?vm.YarnFn {
    return self.hash_map.get(name);
}
