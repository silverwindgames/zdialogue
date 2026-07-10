//! Test only functions
//! Lives here until we expose define-your-own-function API

const std = @import("std");
const vm = @import("../vm.zig");

// Adds three operands together
pub fn addThreeOperands(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

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
