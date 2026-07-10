//! Reimplementations of Yarn's standard library in Zig
//! Enum functions sourced from: https://github.com/YarnSpinnerTool/YarnSpinner/blob/main/YarnSpinner/Types/EnumType.cs
const std = @import("std");
const vm = @import("../vm.zig");

// Enum.EqualTo(enum1, enum2)
pub fn enumEqualTo(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

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

// Enum.NotEqualTo(enum1, enum2)
pub fn enumNotEqualTo(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    return .{ .bool_value = !(enumEqualTo(params, ctx).?.bool_value) };
}
