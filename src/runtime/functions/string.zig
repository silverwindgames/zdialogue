//! Reimplementations of Yarn's standard library in Zig
//! String functions sourced from: https://github.com/YarnSpinnerTool/YarnSpinner/blob/main/YarnSpinner/Types/StringType.cs
const std = @import("std");
const vm = @import("../vm.zig");

// String.Add(str1, str2)
pub fn stringAdd(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.string_value);
    std.debug.assert(params[1] == vm.Value.string_value);

    const param1 = params[0].string_value.str;
    const param2 = params[1].string_value.str;

    const concatenated = std.fmt.allocPrint(ctx.allocator, "{s}{s}", .{ param1, param2 }) catch |err| {
        std.log.err("String.Add(): failed to concatenate strings: {any}", .{err});
        return null;
    };
    defer ctx.allocator.free(concatenated);

    const str_obj = ctx.allocString(concatenated) catch |err| {
        std.log.err("String.Add(): failed to allocate result: {any}", .{err});
        return null;
    };

    return .{ .string_value = str_obj };
}

// String.EqualTo(str1, str2)
pub fn stringEqualTo(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.string_value);
    std.debug.assert(params[1] == vm.Value.string_value);

    const param1 = params[0].string_value.str;
    const param2 = params[1].string_value.str;

    const ret = std.mem.eql(u8, param1, param2);

    return .{ .bool_value = ret };
}

// String.NotEqualTo(str1, str2)
pub fn stringNotEqualTo(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    return .{ .bool_value = !(stringEqualTo(params, ctx).?.bool_value) };
}
