const std = @import("std");

const Yarn = @import("proto/Yarn.pb.zig");

program: []Yarn.Instruction,
pc: usize,

const Self = @This();

pub fn init(program: []Yarn.Instruction) Self {
    std.debug.assert(program.len > 0);
    return Self{
        .program = program,
        .pc = 0,
    };
}

fn traceInstruction(instruction: Yarn.Instruction) void {
    std.log.debug("Executing instruction: {s} with payload {any}", .{ @tagName(instruction.InstructionType.?), instruction.InstructionType.? });
}

pub const RunOpts = struct {
    tracing: bool = false,
};

pub fn run(vm: *Self, opts: RunOpts) !void {
    while (true) {
        const instruction = vm.program[vm.pc];

        if (opts.tracing) {
            traceInstruction(instruction);
        }

        switch (instruction.InstructionType.?) {
            .addOption => |addOption| {
                _ = addOption;
            },
            .jumpTo => |jumpTo| {
                _ = jumpTo;
            },
            .@"return" => return,
            else => |inst| {
                std.log.warn("Unsupported instruction: {s}", .{@tagName(inst)});
            },
        }

        vm.pc = vm.pc + 1;
    }
}
