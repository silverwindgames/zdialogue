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

    std.log.info("[Line] {s}", .{line_data});
}

fn optionHandler(_: ?*anyopaque, options: []zdialogue.Option) void {
    for (options) |opt| {
        const line_data = lines.get(opt.line_id) orelse {
            std.log.err("Line ID not found: {s}", .{opt.line_id});
            return;
        };

        std.log.info("[Option] {d}. {s}", .{ opt.index, line_data.text });
    }
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena: std.mem.Allocator = init.arena.allocator();

    // Parse command line arguments
    const args = try init.minimal.args.toSlice(arena);
    const use_tracing = (args.len >= 2 and std.mem.eql(u8, args[1], "tracing"));
    std.log.info("Use tracing: {}", .{use_tracing});

    // Load sample Yarn program and dialogue lines
    const program: Yarn.Program = zdialogue.parseProtobuf("demo-simple/Project.yarnc", io, arena) catch |err| {
        std.log.err("Failed to parse protobuf: {any}", .{err});
        return err;
    };

    lines = zdialogue.Dialogue.parseDialogueFromCsv(io, arena, "demo-simple/Project-Lines.csv") catch |err| {
        std.log.err("Failed to parse dialogue CSV: {any}", .{err});
        return err;
    };

    // Run program
    std.log.info("[!] Program started", .{});

    var ctx = Context{
        .allocator = arena,
    };

    var vm = try zdialogue.VirtualMachine.init(&program, arena, io, .{
        .context = &ctx,
        .line_handler = lineHandler,
        .option_handler = optionHandler,
    });
    defer vm.deinit();

    var stdin_buffer: [256]u8 = undefined;
    var stdin_reader = std.Io.File.stdin().reader(io, &stdin_buffer);

    loop: while (true) {
        try switch (vm.state) {
            .running => {
                try vm.run(.{ .tracing = use_tracing });
            },
            .waitingForContinue => {
                // Prompt for user input
                std.debug.print("Press Enter to continue...", .{});
                _ = try stdin_reader.interface.takeDelimiter('\n');

                try vm.run(.{ .tracing = use_tracing });
            },
            .waitingOnOptionSelection => {
                // Ask user for option
                std.debug.print("Select an option (0-{d}): ", .{vm.options.count - 1});
                if (try stdin_reader.interface.takeDelimiter('\n')) |line| {
                    const user_input = std.fmt.parseInt(usize, line, 10) catch |err| {
                        std.log.err("Failed to parse user input: {any}", .{err});
                        continue;
                    };
                    try vm.setSelectedOption(user_input);
                    try vm.run(.{ .tracing = use_tracing });
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
