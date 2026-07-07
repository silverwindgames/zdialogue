//! The Virtual Machine
//! Executes a Yarn program, using callbacks to the client game to deliver content and receive input
//! Adapted from https://github.com/YarnSpinnerTool/YarnSpinner/blob/main/YarnSpinner/VirtualMachine.cs

const std = @import("std");
const Yarn = @import("../proto/Yarn.pb.zig");

const MAX_OPTIONS = 12;
const MAX_STACK = 256; // probably enough right?

pub const LineHandler = *const fn (context: ?*anyopaque, lineID: []const u8) void;
pub const OptionHandler = *const fn (context: ?*anyopaque, options: []Option) void;

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

pub const Option = struct {
    index: usize,
    line_id: []const u8,
    destination: i32,
    enabled: bool,
};

pub const Callbacks = struct {
    context: ?*anyopaque = null,
    line_handler: ?LineHandler = null,
    option_handler: ?OptionHandler = null,
};

pub fn defaultLineHandler(_: ?*anyopaque, lineID: []const u8) void {
    std.log.info("[Default Line Handler] {s}", .{lineID});
}

pub fn defaultOptionHandler(_: ?*anyopaque, options: []Option) void {
    for (options) |opt| {
        std.log.info("[Default Option Handler] {s} -> {d} (enabled: {})", .{ opt.line_id, opt.destination, opt.enabled });
    }
}

const Value = union(enum) {
    boolValue: bool,
    floatValue: f32,
};

state: ExecutionState,
program: *const Yarn.Program,
node: *const Yarn.Node,
pc: usize,
stack: [MAX_STACK]Value,
stack_top: usize,

options: [MAX_OPTIONS]Option,
num_options: usize,

context: ?*anyopaque,
line_handler: LineHandler,
option_handler: OptionHandler,

const Self = @This();

pub fn init(program: *const Yarn.Program, callbacks: Callbacks) Self {
    std.debug.assert(program.nodes.items.len > 0);
    return Self{
        .state = .running,
        .program = program,
        .node = &program.nodes.items[0].value.?,
        .pc = 0,
        .stack = undefined,
        .stack_top = 0,
        .options = undefined,
        .num_options = 0,
        .context = callbacks.context,
        .line_handler = if (callbacks.line_handler) |cb| cb else defaultLineHandler,
        .option_handler = if (callbacks.option_handler) |cb| cb else defaultOptionHandler,
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
                self.line_handler(self.context, runLine.lineID);
            },
            .addOption => |addOption| {
                if (self.num_options >= MAX_OPTIONS) {
                    std.log.err("Maximum number of options reached, ignoring option: {s}", .{addOption.lineID});
                    break;
                }

                self.options[self.num_options] = Option{
                    .index = self.num_options,
                    .line_id = addOption.lineID,
                    .destination = addOption.destination,
                    .enabled = true, // TODO: Condition stuff
                };

                self.num_options += 1;
            },
            .showOptions => {
                self.option_handler(self.context, self.options[0..self.num_options]);
                self.num_options = 0;
                self.state = .waitingOnOptionSelection;
                return;
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
            .pop => {
                if (self.stack_top == 0) {
                    return error.StackUnderflow;
                }
                self.stack_top -= 1;
            },
            .pushBool => |pushBool| {
                self.stack[self.stack_top] = Value{ .boolValue = pushBool.value };
                self.stack_top += 1;
            },
            .pushFloat => |pushFloat| {
                self.stack[self.stack_top] = Value{ .floatValue = pushFloat.value };
                self.stack_top += 1;
            },
            .jumpTo => |jumpTo| {
                self.pc = @as(usize, @intCast(jumpTo.destination));
                continue;
            },
            .jumpIfFalse => |jumpIfFalse| {
                const value = self.stack[self.stack_top - 1];

                if (!value.boolValue) {
                    self.pc = @as(usize, @intCast(jumpIfFalse.destination));
                    continue;
                }
            },
            .@"return" => return,
            else => |inst| {
                std.log.warn("Unsupported instruction: {s}", .{@tagName(inst)});
                return error.UnsupportedInstruction;
            },
        }

        self.pc += 1;
    }
}
