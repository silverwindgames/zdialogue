const std = @import("std");
const vm = @import("vm.zig");

const func_bool = @import("functions/bool.zig");
const func_number = @import("functions/number.zig");
const func_enum = @import("functions/enum.zig");
const func_builtin = @import("functions/builtin.zig");
const func_test_only = @import("functions/test_only.zig");

hash_map: std.StringHashMap(vm.YarnFn),
allocator: std.mem.Allocator,

const Self = @This();

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
    try func_lib.registerFunction("Bool.Not", &func_bool.boolNot);
    try func_lib.registerFunction("Number.EqualTo", &func_number.numberEqualTo);
    try func_lib.registerFunction("Number.Add", &func_number.numberAdd);
    try func_lib.registerFunction("Number.Subtract", &func_number.numberSubtract);
    try func_lib.registerFunction("Number.Divide", &func_number.numberDivide);
    try func_lib.registerFunction("Number.Multiply", &func_number.numberMultiply);
    try func_lib.registerFunction("Number.Modulus", &func_number.numberModulus);
    try func_lib.registerFunction("Number.UnaryMinus", &func_number.numberUnaryMinus);
    try func_lib.registerFunction("Number.GreaterThan", &func_number.numberGreaterThan);
    try func_lib.registerFunction("Number.GreaterThanOrEqualTo", &func_number.numberGreaterThanOrEqualTo);
    try func_lib.registerFunction("Number.LessThan", &func_number.numberLessThan);
    try func_lib.registerFunction("Number.LessThanOrEqualTo", &func_number.numberLessThanOrEqualTo);
    try func_lib.registerFunction("Enum.EqualTo", &func_enum.enumEqualTo);
    try func_lib.registerFunction("Enum.NotEqualTo", &func_enum.enumNotEqualTo);

    try func_lib.registerFunction("string", &func_builtin.convertToString);
    try func_lib.registerFunction("number", &func_builtin.convertToNumber);
    try func_lib.registerFunction("format_invariant", &func_builtin.formatInvariant);
    try func_lib.registerFunction("bool", &func_builtin.convertToBool);

    try func_lib.registerFunction("random", &func_builtin.random);
    try func_lib.registerFunction("random_range", &func_builtin.randomRange);
    try func_lib.registerFunction("random_range_float", &func_builtin.randomRangeFloat);
    try func_lib.registerFunction("dice", &func_builtin.yarnDice);

    try func_lib.registerFunction("min", &func_builtin.min);
    try func_lib.registerFunction("max", &func_builtin.max);

    try func_lib.registerFunction("round", &func_builtin.round);
    try func_lib.registerFunction("round_places", &func_builtin.roundPlaces);
    try func_lib.registerFunction("floor", &func_builtin.floor);
    try func_lib.registerFunction("ceil", &func_builtin.ceil);
    try func_lib.registerFunction("inc", &func_builtin.inc);
    try func_lib.registerFunction("dec", &func_builtin.dec);
    try func_lib.registerFunction("decimal", &func_builtin.decimal);
    try func_lib.registerFunction("int", &func_builtin.int);

    try func_lib.registerFunction("format", &func_builtin.format);

    // TEST ONLY
    // TODO: Should be declared in the tests directory
    try func_lib.registerFunction("add_three_operands", &func_test_only.addThreeOperands);

    return func_lib;
}

pub fn getFunction(self: *Self, name: []const u8) ?vm.YarnFn {
    return self.hash_map.get(name);
}
