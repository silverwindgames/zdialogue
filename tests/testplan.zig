const std = @import("std");
const sample = @embedFile("Commands.testplan");

pub const StepType = enum {
    line,
    option,
    command,
    stop,
    action_select,
    action_set_saliency,
    action_set_variable,
    action_jump_to_node,
};

pub const Step = union(StepType) {
    line: struct {
        expected_text: []const u8,
        expected_hashtags: std.ArrayList([]const u8),
    },
    option: struct {
        expected_text: []const u8,
        expected_hashtags: std.ArrayList([]const u8),
        expected_availability: bool,
    },
    command: struct {
        expected_text: []const u8,
    },
    stop: void,
    action_select: struct {
        selected_index: i32,
    },
    action_set_saliency: struct {
        saliency_mode: []const u8,
    },
    action_set_variable: struct {
        variable_name: []const u8,
        value: []const u8,
    },
    action_jump_to_node: struct {
        node_name: []const u8,
    },

    fn deinit(self: *Step, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .line => |*line_step| {
                line_step.expected_hashtags.deinit(allocator);
            },
            .option => |*option_step| {
                option_step.expected_hashtags.deinit(allocator);
            },
            else => {},
        }
    }
};

/// The entire testplan file read into memory. We're just going
/// to index into this buffer to get the text content for each
/// step, meaning no allocations required.
buffer: []const u8,

/// The list of steps to execute in order
steps: std.ArrayList(Step),

/// The allocator used for the steps list
allocator: std.mem.Allocator,

const Self = @This();

/// A typical testplan line looks like:
///
/// command: `param`
/// line: `expected text` #hash1 #hash2
/// stop
///
fn parse_line(line: []const u8, allocator: std.mem.Allocator) !?Step {
    // Skip empty lines and comments
    if (line.len == 0 or std.mem.startsWith(u8, line, "#")) {
        return null;
    }

    // Check for the "run again" command. It's three dashes
    if (std.mem.eql(u8, line, "---")) {
        return error.RunAgain; // uh oh, fix it later
    }

    // Check for the "stop" command. It doesn't have any
    // parameters, so we can just check the first 4 characters.
    if (std.mem.eql(u8, line[0..4], "stop")) {
        return Step{ .stop = {} };
    }

    // The typical line format is:
    // <command>: `<expected_text>` #hash1 #hash2

    // Extract command
    const command = extract_command: {
        var index: usize = 0;
        while (index < line.len and line[index] != ':') : (index += 1) {}
        if (index == line.len) {
            std.log.err("Could not find ':' character. Malformed testplan line: {s}", .{line});
            return error.ParseError;
        }
        break :extract_command line[0..index];
    };

    // Extract expected_text
    const expected_text = extract_expected_text: {
        const first_backtick_index = std.mem.indexOf(u8, line, "`") orelse {
            std.log.err("Could not find first backtick. Malformed testplan line: {s}", .{line});
            return error.ParseError;
        };
        const second_backtick_index = std.mem.indexOf(u8, line[first_backtick_index + 1 ..], "`") orelse {
            std.log.err("Could not find second backtick. Malformed testplan line: {s}", .{line});
            return error.ParseError;
        };
        break :extract_expected_text line[(first_backtick_index + 1)..(first_backtick_index + 1 + second_backtick_index)];
    };

    const hashtags = extract_hashtags: {
        var hashtag_list = try std.ArrayList([]const u8).initCapacity(allocator, 0);
        const hashtag_start_index = std.mem.indexOf(u8, line, "#") orelse {
            break :extract_hashtags hashtag_list;
        };
        const hashtags_slice = line[hashtag_start_index..];
        var hashtag_iter = std.mem.splitAny(u8, hashtags_slice, " \t\r");

        while (hashtag_iter.next()) |hashtag| {
            if (hashtag.len > 1) {
                try hashtag_list.append(allocator, hashtag[1..]);
            }
        }

        break :extract_hashtags hashtag_list;
    };

    if (std.mem.eql(u8, command, "line")) {
        return Step{ .line = .{
            .expected_text = expected_text,
            .expected_hashtags = hashtags,
        } };
    } else if (std.mem.eql(u8, command, "option")) {
        return Step{ .option = .{
            .expected_text = expected_text,
            .expected_hashtags = hashtags,
            .expected_availability = true,
        } };
    } else if (std.mem.eql(u8, command, "command")) {
        return Step{ .command = .{
            .expected_text = expected_text,
        } };
    } else if (std.mem.eql(u8, command, "set")) {
        return error.NotImplemented;
    } else {
        std.log.err("Unknown command: {s}. Malformed testplan line: {s}", .{ command, line });
        return error.ParseError;
    }
}

/// Assumes ownership of the buffer, will be freed by deinit(). Pass in the
/// same allocator used to allocate the buffer.
pub fn init_from_buffer(allocator: std.mem.Allocator, buffer: []const u8) !Self {
    var steps = try std.ArrayList(Step).initCapacity(allocator, 10);

    var line_iter = std.mem.splitAny(u8, buffer, "\n");
    while (line_iter.next()) |line| {
        const step = try parse_line(line, allocator) orelse continue;
        try steps.append(allocator, step);
    }

    return Self{
        .steps = steps,
        .buffer = buffer,
        .allocator = allocator,
    };
}

pub fn init_from_file(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !Self {
    const buffer = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .unlimited);
    return Self.init_from_buffer(allocator, buffer);
}

pub fn deinit(self: *Self) void {
    for (self.steps.items) |*step| {
        step.deinit(self.allocator);
    }
    self.steps.deinit(self.allocator);
    self.allocator.free(self.buffer);
}

test "parse testplan from buffer" {
    const allocator = std.testing.allocator;

    const buffer = try allocator.dupe(u8, @embedFile("cases/Lines.testplan"));

    var testplan = try Self.init_from_buffer(allocator, buffer);
    defer testplan.deinit();
}
