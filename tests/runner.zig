const std = @import("std");

const TestPlan = @import("testplan.zig");
const StepType = TestPlan.StepType;

const zdialogue = @import("zdialogue");
const VirtualMachine = zdialogue.VirtualMachine;
const Yarn = zdialogue.Yarn;

const Runner = struct {
    test_plan: TestPlan,
    lines: std.StringHashMap(zdialogue.Dialogue.Line),
    metadata: std.StringHashMap(zdialogue.Dialogue.Metadata),
    step_index: usize = 0,
    had_error: bool = false,
    allocator: std.mem.Allocator,

    const Self = @This();

    fn lineHandler(context: ?*anyopaque, line_id: []const u8, substitutions: []const []const u8) void {
        const self: *Self = @ptrCast(@alignCast(context.?));
        self.assertLine(line_id, substitutions) catch |err| {
            std.log.err("Unrecoverable failure in line handler {any}", .{err});
            self.had_error = true;
        };
    }

    fn optionHandler(context: ?*anyopaque, options: []zdialogue.Option) void {
        const self: *Self = @ptrCast(@alignCast(context.?));
        for (options) |opt| {
            self.assertOption(opt);
        }
    }

    fn assertLine(self: *Self, line_id: []const u8, substitutions: []const []const u8) !void {
        const unsubstituted_line_data = self.lines.get(line_id) orelse {
            std.log.err("Line ID not found: `{s}`", .{line_id});
            self.had_error = true;
            return;
        };

        // const maybe_meta_data = self.metadata.get(line_id);
        const line_data = try zdialogue.Dialogue.substituteLineData(self.allocator, unsubstituted_line_data.text, substitutions);
        defer self.allocator.free(line_data);

        std.log.info("Matching line: {s}", .{line_data});

        const current_test_plan_step = self.test_plan.steps.items[self.step_index];
        if (current_test_plan_step != .line) {
            std.log.err("Expected a line step in the test plan, but found a different step type at index {d}.", .{self.step_index});
            self.had_error = true;
            return;
        }

        const step = self.test_plan.steps.items[self.step_index];
        if (!std.mem.eql(u8, line_data, step.line.expected_text)) {
            std.log.err("Line text does not match expected text. Expected: {s}, Got: {s}", .{ step.line.expected_text, line_data });
            self.had_error = true;
        }

        // if (maybe_meta_data) |metadata| {
        //     const expected_hashtags = step.line.expected_hashtags.items;
        //     const actual_hashtags = metadata.tags.items;

        //     if (expected_hashtags.len != actual_hashtags.len) {
        //         std.log.err("Line hashtags count does not match expected count. Expected: {d}, Got: {d}", .{ expected_hashtags.len, actual_hashtags.len });
        //         self.had_error = true;
        //     } else {
        //         for (expected_hashtags, 0..) |expected_tag, index| {
        //             const actual_tag = actual_hashtags[index];
        //             if (!std.mem.eql(u8, expected_tag, actual_tag)) {
        //                 std.log.err("Line hashtag at index {d} does not match expected hashtag. Expected: {s}, Got: {s}", .{ index, expected_tag, actual_tag });
        //                 self.had_error = true;
        //             }
        //         }
        //     }
        // }

        // const expected_hashtags_match = std.mem.eql(u8, line_data.hashtags, step.line.expected_hashtags);
        // if (!expected_hashtags_match) {
        //     std.log.err("Line hashtags do not match expected hashtags. Expected: {s}, Got: {s}", .{ step.line.expected_hashtags, line_data.hashtags });
        //     self.had_error = true;
        // }
        std.log.warn("Haven't implemented metadata yet, so skipping hashtag comparison for now.", .{});

        self.step_index += 1;
    }

    fn assertOption(self: *Self, option: zdialogue.Option) void {
        const line_data = self.lines.get(option.line_id) orelse {
            std.log.err("Line ID not found: {s}", .{option.line_id});
            self.had_error = true;
            return;
        };

        std.log.info("Matching option: `{s}`", .{line_data.text});

        const current_test_plan_step = self.test_plan.steps.items[self.step_index];
        if (current_test_plan_step != .option) {
            std.log.err("Expected an option step in the test plan, but found a different step type at index {d}.", .{self.step_index});
            self.had_error = true;
            return;
        }

        const step = self.test_plan.steps.items[self.step_index];
        if (!std.mem.eql(u8, line_data.text, step.option.expected_text)) {
            std.log.err("Option text does not match expected text. Expected: {s}, Got: {s}", .{ step.option.expected_text, line_data.text });
            self.had_error = true;
        }

        // const expected_hashtags_match = std.mem.eql(u8, line_data.hashtags, step.option.expected_hashtags);
        // if (!expected_hashtags_match) {
        //     std.log.err("Option hashtags do not match expected hashtags. Expected: {s}, Got: {s}", .{ step.option.expected_hashtags, line_data.hashtags });
        //     self.had_error = true;
        // }
        std.log.warn("Haven't implemented metadata yet, so skipping hashtag comparison for now.", .{});

        if (option.enabled != step.option.expected_availability) {
            std.log.err("Option availability does not match expected availability. Expected: {}, Got: {}", .{ step.option.expected_availability, option.enabled });
            self.had_error = true;
        }

        self.step_index += 1;
    }
};

const TestParams = struct {
    yarnc: []const u8,
    lines_csv: []const u8,
    metadata_csv: []const u8,
    testplan: []const u8,
};

fn debugProgram(program: *const Yarn.Program) void {
    for (program.nodes.items) |node| {
        std.log.info("Node: {s}", .{node.value.?.name});
        for (node.value.?.instructions.items) |instruction| {
            std.log.info("  Instruction: {any}", .{instruction.InstructionType.?});
        }
    }
}

pub fn runTest(allocator: std.mem.Allocator, io: std.Io, params: TestParams) !void {
    var runner = Runner{
        .test_plan = try TestPlan.init_from_file(allocator, io, params.testplan),
        .lines = undefined,
        .metadata = undefined,
        .allocator = allocator,
    };

    const program: Yarn.Program = zdialogue.parseProtobuf(params.yarnc, io, allocator) catch |err| {
        std.log.err("Failed to parse protobuf: {any}", .{err});
        return err;
    };

    runner.lines = zdialogue.Dialogue.parseDialogueFromCsv(io, allocator, params.lines_csv) catch |err| {
        std.log.err("Failed to parse dialogue CSV: {any}", .{err});
        return err;
    };

    runner.metadata = zdialogue.Dialogue.parseMetadataFromCsv(io, allocator, params.metadata_csv) catch |err| {
        std.log.err("Failed to parse metadata CSV: {any}", .{err});
        return err;
    };

    std.log.info("[!] Program started", .{});

    var vm = try zdialogue.VirtualMachine.init(&program, allocator, .{
        .context = &runner,
        .line_handler = Runner.lineHandler,
        .option_handler = Runner.optionHandler,
    });
    defer vm.deinit();

    vm.run(.{ .tracing = false }) catch |err| {
        std.log.err("Virtual machine execution failed: {any}", .{err});
        runner.had_error = true;
    };

    if (runner.had_error) {
        std.log.err("[!] Test plan failed", .{});
        debugProgram(&program);
        return error.TestPlanFailed;
    } else {
        std.log.info("[!] Test plan passed", .{});
    }
}

fn printSummary(passed_tests: []const []const u8, failed_tests: []const []const u8) !void {
    std.log.info("Passed Tests:", .{});
    for (passed_tests) |test_case| {
        std.log.info(" - {s}", .{test_case});
    }
    std.log.err("Failed Tests:", .{});
    for (failed_tests) |test_case| {
        std.log.err(" - {s}", .{test_case});
    }
    std.log.info("Summary: {d} passed, {d} failed", .{ passed_tests.len, failed_tests.len });
}

pub fn runAll(allocator: std.mem.Allocator, io: std.Io) !void {
    const dir = std.Io.Dir.cwd().openDir(io, "tests/compiled", .{}) catch |err| {
        std.log.err("Failed to open directory: {any}", .{err});
        return err;
    };
    defer dir.close(io);

    var list_of_failed_tests = try std.ArrayList([]const u8).initCapacity(allocator, 10);
    defer list_of_failed_tests.deinit(allocator);

    var list_of_passed_tests = try std.ArrayList([]const u8).initCapacity(allocator, 10);
    defer list_of_passed_tests.deinit(allocator);

    var walk_iter = try std.Io.Dir.walk(dir, allocator);
    while (try walk_iter.next(io)) |entry| {
        if (!std.mem.endsWith(u8, entry.path, ".yarnc")) {
            continue;
        }

        var yarn_path = try dir.realPathFileAlloc(io, entry.path, allocator);
        defer allocator.free(yarn_path);

        const path_without_extension = yarn_path[0 .. yarn_path.len - 6];

        const lines_csv_path = try std.fmt.allocPrint(allocator, "{s}-Lines.csv", .{path_without_extension});
        const metadata_csv_path = try std.fmt.allocPrint(allocator, "{s}-Metadata.csv", .{path_without_extension});
        const testplan_path = try std.fmt.allocPrint(allocator, "{s}.testplan", .{path_without_extension});

        std.log.info("Running test for file: {s}", .{testplan_path});

        runTest(allocator, io, .{
            .yarnc = yarn_path,
            .lines_csv = lines_csv_path,
            .metadata_csv = metadata_csv_path,
            .testplan = testplan_path,
        }) catch |err| {
            std.log.err("Test failed for file: {s} with error: {any}\n\n", .{ entry.path, err });
            try list_of_failed_tests.append(allocator, try allocator.dupe(u8, entry.path));
            continue;
        };

        std.log.info("Test passed for file: {s}\n\n", .{entry.path});
        try list_of_passed_tests.append(allocator, try allocator.dupe(u8, entry.path));
    }

    // Summarise results
    try printSummary(list_of_passed_tests.items, list_of_failed_tests.items);

    if (list_of_failed_tests.items.len > 0) {
        return error.NotAllTestsPassed;
    }
}

pub fn runOne(allocator: std.mem.Allocator, io: std.Io, yarnc_path: []const u8) !void {
    const base_path = yarnc_path[0 .. yarnc_path.len - 6]; // Remove the ".yarnc" extension
    const testplan_path = try std.fmt.allocPrint(allocator, "{s}.testplan", .{base_path});
    const lines_csv_path = try std.fmt.allocPrint(allocator, "{s}-Lines.csv", .{base_path});
    const metadata_csv_path = try std.fmt.allocPrint(allocator, "{s}-Metadata.csv", .{base_path});

    std.log.info("Running single test for file: {s}", .{testplan_path});

    runTest(allocator, io, .{
        .yarnc = yarnc_path,
        .lines_csv = lines_csv_path,
        .metadata_csv = metadata_csv_path,
        .testplan = testplan_path,
    }) catch |err| {
        std.log.err("Test failed for file: {s} with error: {any}\n\n", .{ testplan_path, err });
        return err;
    };

    std.log.info("Test passed for file: {s}\n\n", .{testplan_path});
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;

    const args = try init.minimal.args.toSlice(allocator);

    if (args.len < 2) {
        std.log.info("No testplan specified, running all tests in `tests/compiled`.", .{});
        try runAll(allocator, io);
        return;
    }

    const testplan_path = args[1];
    try runOne(allocator, io, testplan_path);
}
