//! Reimplementations of Yarn's standard library in Zig
//! Catchall file sourced from: https://github.com/YarnSpinnerTool/YarnSpinner/blob/main/YarnSpinner/Dialogue.cs
const std = @import("std");
const vm = @import("../vm.zig");

var prng: ?std.Random.DefaultPrng = null;

// Lazy initialise the PRNG
fn getRandom(io: std.Io) std.Random {
    if (prng == null) {
        var seed: u64 = undefined;
        io.random(std.mem.asBytes(&seed));
        prng = std.Random.DefaultPrng.init(seed);
    }
    return prng.?.random();
}

// string(val)
pub fn convertToString(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    std.debug.assert(params.len == 1);

    var buf: [64]u8 = undefined;
    const text = switch (params[0]) {
        .string_value => |sv| sv.str,
        .bool_value => |bv| if (bv) "True" else "False",
        .float_value => |fv| std.fmt.bufPrint(&buf, "{d}", .{fv}) catch {
            std.log.err("string(): failed to format float: {d}", .{fv});
            return null;
        },
    };

    const str_obj = ctx.allocString(text) catch |err| {
        std.log.err("string(): failed to allocate result: {any}", .{err});
        return null;
    };

    return .{ .string_value = str_obj };
}

// number(val)
pub fn convertToNumber(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 1);

    const ret: f32 = switch (params[0]) {
        .float_value => |fv| fv,
        .bool_value => |bv| if (bv) 1.0 else 0.0,
        .string_value => |sv| std.fmt.parseFloat(f32, sv.str) catch {
            std.log.err("number(): failed to parse string '{s}' as float", .{sv.str});
            return null;
        },
    };

    return .{ .float_value = ret };
}

// format_invariant(val)
// Short Answer: Convert float to string
// Long Answer: In C# you can pass an IFormatProvider to ToString, which changes
// how e.g. decimals are formatted. Because of this, YarnSpinner specifically does:
//
//   return v.ToString(System.Globalization.CultureInfo.InvariantCulture);
//
// Zig however has no concept of culture/locale whatsoever, so we just convert float to string
pub fn formatInvariant(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    std.debug.assert(params.len == 1);
    std.debug.assert(params[0] == vm.Value.float_value);

    var buf: [64]u8 = undefined;
    const text = std.fmt.bufPrint(&buf, "{d}", .{params[0].float_value}) catch {
        std.log.err("format_invariant(): failed to format float: {d}", .{params[0].float_value});
        return null;
    };

    const str_obj = ctx.allocString(text) catch |err| {
        std.log.err("format_invariant(): failed to allocate result: {any}", .{err});
        return null;
    };

    return .{ .string_value = str_obj };
}

// bool(v)
pub fn convertToBool(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 1);

    const ret: bool = switch (params[0]) {
        .bool_value => |bv| bv,
        .float_value => |fv| fv != 0,
        .string_value => |sv| std.ascii.eqlIgnoreCase(sv.str, "true"),
    };

    return .{ .bool_value = ret };
}

// random()
pub fn random(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    std.debug.assert(params.len == 0);

    return .{ .float_value = getRandom(ctx.io).float(f32) };
}

// random_range(min, max)
// Inclusive of both min/max
pub fn randomRange(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const range_min: i64 = @intFromFloat(params[0].float_value);
    const range_max: i64 = @intFromFloat(params[1].float_value);

    const ret = getRandom(ctx.io).intRangeAtMost(i64, range_min, range_max);

    return .{ .float_value = @floatFromInt(ret) };
}

// random_range_float(min, max)
// Alias for above
pub fn randomRangeFloat(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    return randomRange(params, ctx);
}

// dice(sides)
pub fn yarnDice(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    std.debug.assert(params.len == 1);
    std.debug.assert(params[0] == vm.Value.float_value);

    const sides: i64 = @intFromFloat(params[0].float_value);
    const roll = getRandom(ctx.io).intRangeLessThan(i64, 0, sides);

    return .{ .float_value = @floatFromInt(roll + 1) };
}

// min(a, b)
pub fn min(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    return .{ .float_value = @min(params[0].float_value, params[1].float_value) };
}

// max(a, b)
pub fn max(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    return .{ .float_value = @max(params[0].float_value, params[1].float_value) };
}

// round(num)
// We use `std.math.round()` as it implements "rounding away from zero", matching
// C#'s default behaviour for Math.Round().
// See: https://learn.microsoft.com/en-us/dotnet/api/system.math.round?view=net-10.0#midpoint-values-and-rounding-conventions
pub fn round(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 1);
    std.debug.assert(params[0] == vm.Value.float_value);

    return .{ .float_value = std.math.round(params[0].float_value) };
}

// round_places(num, places)
// TODO: I'm not so sure about this one
pub fn roundPlaces(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.float_value);
    std.debug.assert(params[1] == vm.Value.float_value);

    const places: i32 = @intFromFloat(params[1].float_value);
    const factor = std.math.pow(f32, 10.0, @as(f32, @floatFromInt(places)));

    return .{ .float_value = @round(params[0].float_value * factor) / factor };
}

// floor(num)
pub fn floor(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 1);
    std.debug.assert(params[0] == vm.Value.float_value);

    return .{ .float_value = @floor(params[0].float_value) };
}

// ceil(num)
pub fn ceil(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 1);
    std.debug.assert(params[0] == vm.Value.float_value);

    return .{ .float_value = @ceil(params[0].float_value) };
}

fn helperGetDecimalPart(value: f32) f32 {
    return value - @trunc(value);
}

// inc(value)
pub fn inc(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 1);
    std.debug.assert(params[0] == vm.Value.float_value);

    const value = params[0].float_value;
    const ret = if (helperGetDecimalPart(value) == 0) value + 1 else @ceil(value);

    return .{ .float_value = ret };
}

// dec(value)
pub fn dec(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 1);
    std.debug.assert(params[0] == vm.Value.float_value);

    const value = params[0].float_value;
    const ret = if (helperGetDecimalPart(value) == 0) value - 1 else @floor(value);

    return .{ .float_value = ret };
}

// decimal(value)
pub fn decimal(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 1);
    std.debug.assert(params[0] == vm.Value.float_value);

    return .{ .float_value = helperGetDecimalPart(params[0].float_value) };
}

// int(value)
pub fn int(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 1);
    std.debug.assert(params[0] == vm.Value.float_value);

    return .{ .float_value = @trunc(params[0].float_value) };
}

// format(format_string, argument)
pub fn format(params: []vm.Value, ctx: vm.Context) ?vm.Value {
    _ = ctx;

    std.debug.assert(params.len == 2);
    std.debug.assert(params[0] == vm.Value.string_value);

    // TODO: Somehow support C# compatible format strings
    std.log.err("format() is not implemented yet. format_string: '{s}', argument: '{any}'", .{ params[0].string_value.str, params[1] });

    return null;

    // return .{ .string_value = str_obj };
}
