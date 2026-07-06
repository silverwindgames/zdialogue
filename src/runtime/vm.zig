//! The Virtual Machine
//! Executes a Yarn program, using callbacks to the client game to deliver content and receive input
//! Adapted from https://github.com/YarnSpinnerTool/YarnSpinner/blob/main/YarnSpinner/VirtualMachine.cs

const std = @import("std");
const Yarn = @import("../proto/Yarn.pb.zig");

pub const LineHandler = *const fn (lineID: []const u8) void;

const ExecutionState = enum {
    /// The VirtualMachine is not running a node.
    stopped,

    /// The VirtualMachine is waiting on option selection. Call
    /// setSelectedOption(int) before calling continue()
    waitingOnOptionSelection,

    /// The VirtualMachine has finished delivering content to the
    /// client game, and is waiting for continue() to
    /// be called.
    waitingForContinue,

    /// The VirtualMachine is delivering a line, options, or a
    /// commmand to the client game.
    deliveringContent,

    /// The VirtualMachine is in the middle of executing code.
    running,
};

const Callbacks = struct {
    lineHandler: ?LineHandler,
};

pub fn defaultLineHandler(lineID: []const u8) void {
    std.log.info("[LineHandler] {s}", .{lineID});
}

state: ExecutionState,
program: *const Yarn.Program,
node: *const Yarn.Node,
pc: usize,
lineHandler: LineHandler,

const Self = @This();

pub fn init(program: *const Yarn.Program, callbacks: Callbacks) Self {
    std.debug.assert(program.nodes.items.len > 0);
    return Self{
        .state = .running,
        .program = program,
        .node = &program.nodes.items[0].value.?,
        .pc = 0,
        .lineHandler = if (callbacks.lineHandler) |cb| cb else defaultLineHandler,
    };
}

fn traceInstruction(instruction: Yarn.Instruction) void {
    std.log.debug("Executing instruction: {s} with payload {any}", .{ @tagName(instruction.InstructionType.?), instruction.InstructionType.? });
}

pub const RunOpts = struct {
    tracing: bool = false,
};

pub fn run(self: *Self, opts: RunOpts) !void {
    while (true) {
        const instruction = self.node.instructions.items[self.pc];

        if (opts.tracing) {
            traceInstruction(instruction);
        }

        switch (instruction.InstructionType.?) {
            .runLine => |runLine| {
                self.lineHandler(runLine.lineID);
            },
            .showOptions => |showOptions| {
                _ = showOptions;
                break;
            },
            .runNode => |runNode| {
                // TODO: Detours and branching and stuff
                const nodeName = runNode.nodeName;
                for (self.program.nodes.items) |node_pair| {
                    if (std.mem.eql(u8, node_pair.key, nodeName)) {
                        self.node = &node_pair.value.?;
                        self.pc = 0;
                        continue;
                    }
                }
            },
            .@"return" => return,
            else => |inst| {
                std.log.warn("Unsupported instruction: {s}", .{@tagName(inst)});
            },
        }

        self.pc = self.pc + 1;
    }
}
