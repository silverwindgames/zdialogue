const std = @import("std");
const Io = std.Io;

const zdialogue = @import("zdialogue");
const Yarn = zdialogue.Yarn;

var lines: std.StringHashMap(zdialogue.Dialogue.Line) = undefined;

const Context = struct {
    allocator: std.mem.Allocator,
};

fn lineHandler(ctx: ?*anyopaque, line_id: []const u8, substitutions: []const []const u8) void {
    const self: *Context = @ptrCast(@alignCast(ctx.?));

    const unsubstituted_line_data = lines.get(line_id) orelse {
        std.log.err("Line ID not found: {s}", .{line_id});
        return;
    };

    const line_data = zdialogue.Dialogue.substituteLineData(self.allocator, unsubstituted_line_data.text, substitutions) catch {
        std.log.err("Couldn't substitute line data", .{});
        return;
    };
    defer self.allocator.free(line_data);

    std.log.info("[LineHandler] {s}", .{line_data});
}

fn optionHandler(_: ?*anyopaque, options: []zdialogue.Option) void {
    for (options) |opt| {
        const line_data = lines.get(opt.line_id) orelse {
            std.log.err("Line ID not found: {s}", .{opt.line_id});
            return;
        };

        std.log.info("[OptionHandler] {d}. {s}", .{ opt.index, line_data.text });
    }
}

pub fn main(init: std.process.Init) !void {
    // Prints to stderr, unbuffered, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    // In order to do I/O operations need an `Io` instance.
    const io = init.io;

    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    try zdialogue.printAnotherMessage(stdout_writer);

    try stdout_writer.flush(); // Don't forget to flush!

    const program: Yarn.Program = zdialogue.parseProtobuf("demo/Project.yarnc", io, arena) catch |err| {
        std.log.err("Failed to parse protobuf: {any}", .{err});
        return err;
    };

    lines = zdialogue.Dialogue.parseDialogueFromCsv(io, arena, "demo/Project-Lines.csv") catch |err| {
        std.log.err("Failed to parse dialogue CSV: {any}", .{err});
        return err;
    };

    std.log.info("[!] Program started", .{});

    var ctx = Context{
        .allocator = arena,
    };

    var vm = zdialogue.VirtualMachine.init(&program, arena, .{
        .context = &ctx,
        .line_handler = lineHandler,
        .option_handler = optionHandler,
    });
    defer vm.deinit();

    var stdin_buffer: [256]u8 = undefined;
    var stdin_reader = std.Io.File.stdin().reader(io, &stdin_buffer);

    loop: while (true) {
        try switch (vm.state) {
            .running, .waitingForContinue => {
                try vm.run(.{ .tracing = false });
            },
            .waitingOnOptionSelection => {
                // Ask user for option
                std.debug.print("Select an option (0-{d}): ", .{vm.options.count});
                if (try stdin_reader.interface.takeDelimiter('\n')) |line| {
                    const user_input = std.fmt.parseInt(usize, line, 10) catch |err| {
                        std.log.err("Failed to parse user input: {any}", .{err});
                        continue;
                    };
                    try vm.setSelectedOption(user_input);
                } else {
                    std.log.err("Failed to read user input.", .{});
                }
            },
            .deliveringContent => error.NotImplemented,
            .stopped => break :loop,
        };
    }

    std.log.info("[!] Program ended", .{});
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    try std.testing.fuzz({}, testOne, .{});
}

fn testOne(context: void, smith: *std.testing.Smith) !void {
    _ = context;
    // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!

    const gpa = std.testing.allocator;
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(gpa);
    while (!smith.eos()) switch (smith.value(enum { add_data, dup_data })) {
        .add_data => {
            const slice = try list.addManyAsSlice(gpa, smith.value(u4));
            smith.bytes(slice);
        },
        .dup_data => {
            if (list.items.len == 0) continue;
            if (list.items.len > std.math.maxInt(u32)) return error.SkipZigTest;
            const len = smith.valueRangeAtMost(u32, 1, @min(32, list.items.len));
            const off = smith.valueRangeAtMost(u32, 0, @intCast(list.items.len - len));
            try list.appendSlice(gpa, list.items[off..][0..len]);
            try std.testing.expectEqualSlices(
                u8,
                list.items[off..][0..len],
                list.items[list.items.len - len ..],
            );
        },
    };
}

test "Commands.yarn" {
    const commands_yarn = @embedFile("CompiledTestCases/Commands.yarnc");
    const commands_testplan = @embedFile("CompiledTestCases/Commands-Lines.csv");
    _ = commands_yarn;
    _ = commands_testplan;

    // TODO:
    //  - Load the protobuf and CSV into memory
    //  - Run the VM with the loaded data
    //  - Somehow add stub test methods which can verify against the testplan
    //  - Use this as an integration testing suite??

    std.debug.assert(1 == 1);
}
