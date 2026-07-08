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
    bool_value: bool,
    float_value: f32,
    string_value: *String,
};

const Stack = struct {
    items: [MAX_STACK]Value,
    top: usize,

    pub fn init() Stack {
        return Stack{
            .items = undefined,
            .top = 0,
        };
    }

    pub fn push(self: *Stack, value: Value) !void {
        if (self.top >= MAX_STACK) {
            return error.StackOverflow;
        }
        self.items[self.top] = value;
        self.top += 1;
    }

    pub fn pop(self: *Stack) !Value {
        if (self.top == 0) {
            return error.StackUnderflow;
        }
        self.top -= 1;
        return self.items[self.top];
    }

    pub fn peek(self: *Stack) !Value {
        if (self.top == 0) {
            return error.StackUnderflow;
        }
        return self.items[self.top - 1];
    }
};

const OptionSet = struct {
    options: [MAX_OPTIONS]Option,
    count: usize,

    pub fn init() OptionSet {
        return .{
            .options = undefined,
            .count = 0,
        };
    }

    pub fn add(self: *OptionSet, line_id: []const u8, destination: i32, enabled: bool) !void {
        if (self.count >= MAX_OPTIONS) {
            return error.MaxOptionsReached;
        }

        self.options[self.count] = Option{
            .index = self.count,
            .line_id = line_id,
            .destination = destination,
            .enabled = enabled,
        };
        self.count += 1;
    }

    pub fn get(self: *OptionSet, index: usize) !Option {
        if (index >= self.count) {
            return error.InvalidOptionIndex;
        }
        return self.options[index];
    }

    pub fn items(self: *OptionSet) []Option {
        return self.options[0..self.count];
    }

    pub fn clear(self: *OptionSet) void {
        self.count = 0;
    }
};

// TODO: This needs to be a VTable so consuming code can
// provide their own storage. As far as we're concerned, it's
// pretty much read-only.
const VariablesTable = struct {
    hash_map: std.StringHashMap(Value),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) VariablesTable {
        return VariablesTable{
            .hash_map = std.StringHashMap(Value).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn getVariable(self: *VariablesTable, name: []const u8) ?Value {
        return self.hash_map.get(name);
    }

    pub fn deinit(self: *VariablesTable) void {
        self.hash_map.deinit();
    }
};

const String = struct {
    str: []u8,
    next: ?*String,
};

// VM State
state: ExecutionState,
program: *const Yarn.Program,
node: *const Yarn.Node,
pc: usize,
stack: Stack,

// Heap
allocator: std.mem.Allocator,
strings: ?*String,

// Options
options: OptionSet,

// Callbacks
variables: VariablesTable,
context: ?*anyopaque,
line_handler: LineHandler,
option_handler: OptionHandler,

const Self = @This();

pub fn init(program: *const Yarn.Program, allocator: std.mem.Allocator, callbacks: Callbacks) Self {
    std.debug.assert(program.nodes.items.len > 0);
    return Self{
        // VM State
        .state = .running,
        .program = program,
        .node = &program.nodes.items[0].value.?,
        .pc = 0,
        .stack = Stack.init(),
        .variables = VariablesTable.init(allocator),
        .strings = null,
        .allocator = allocator,

        // Options
        .options = OptionSet.init(),

        // Callbacks
        .context = callbacks.context,
        .line_handler = if (callbacks.line_handler) |cb| cb else defaultLineHandler,
        .option_handler = if (callbacks.option_handler) |cb| cb else defaultOptionHandler,
    };
}

pub fn deinit(self: *Self) void {
    self.variables.deinit();
}

fn allocString(self: *Self, text: []const u8) !*String {
    var str_obj = try self.allocator.create(String);
    const str_contents = try self.allocator.dupe(u8, text);

    const current_head = self.strings;

    str_obj.str = str_contents;
    str_obj.next = null;
    str_obj.next = current_head;

    self.strings = str_obj;

    return str_obj;
}

fn traceInstruction(instruction: Yarn.Instruction) void {
    std.log.debug("Executing instruction: {s} with payload {any}", .{ @tagName(instruction.InstructionType.?), instruction.InstructionType.? });
}

/// Sets the selected option. Pass null if no option is selected.
pub fn setSelectedOption(self: *Self, maybe_index: ?usize) !void {
    if (self.state != .waitingOnOptionSelection) {
        std.log.err("Cannot set selected option when not in 'waitingOnOptionSelection' state. Current state: {s}", .{@tagName(self.state)});
        return error.InvalidState;
    }

    if (maybe_index) |index| {
        const selected_option = self.options.get(index) catch {
            std.log.err("Invalid option index: {d}. Number of options available: {d}", .{ index, self.options.count });
            return error.InvalidOptionIndex;
        };

        try self.stack.push(Value{ .float_value = @floatFromInt(selected_option.destination) });
        try self.stack.push(Value{ .bool_value = true });
    } else {
        try self.stack.push(Value{ .bool_value = false });
    }

    self.state = .waitingForContinue;
    self.options.clear();
}

pub const RunOpts = struct {
    tracing: bool = false,
};

pub fn run(self: *Self, opts: RunOpts) !void {
    self.state = .running;

    while (self.state == .running) {
        const instruction = self.node.instructions.items[self.pc];

        if (opts.tracing) {
            traceInstruction(instruction);
        }

        run_instruction: switch (instruction.InstructionType.?) {
            .runLine => |runLine| {
                self.line_handler(self.context, runLine.lineID);
            },
            .addOption => |addOption| {
                // TODO: Condition stuff
                self.options.add(addOption.lineID, addOption.destination, true) catch {
                    std.log.err("Maximum number of options reached, cannot add: {s}", .{addOption.lineID});
                    return error.MaxOptionsReached;
                };
            },
            .showOptions => {
                self.option_handler(self.context, self.options.items());
                self.state = .waitingOnOptionSelection;
            },
            .runNode => |runNode| {
                // TODO: Detours and branching and stuff
                const nodeName = runNode.nodeName;
                for (self.program.nodes.items) |*node_pair| {
                    if (std.mem.eql(u8, node_pair.key, nodeName)) {
                        self.node = &node_pair.value.?;
                        self.pc = 0;
                        break;
                    }
                }
            },
            .pop => {
                _ = try self.stack.pop();
            },
            .pushBool => |pushBool| {
                try self.stack.push(Value{ .bool_value = pushBool.value });
            },
            .pushFloat => |pushFloat| {
                try self.stack.push(Value{ .float_value = pushFloat.value });
            },
            .pushString => |pushString| {
                const str_object = try self.allocString(pushString.value);
                try self.stack.push(Value{ .string_value = str_object });
            },
            .pushVariable => |pushVariable| {
                if (opts.tracing) std.log.debug("Looking up variable `{s}`", .{pushVariable.variableName});

                // Try get from variable storage
                if (self.variables.getVariable(pushVariable.variableName)) |value| {
                    try self.stack.push(value);
                    break;
                }

                // Try get from initial values
                for (self.program.initial_values.items) |*var_pair| {
                    if (opts.tracing) std.log.debug("Comparing val: {s}", .{var_pair.key});
                    if (std.mem.eql(u8, var_pair.key, pushVariable.variableName)) {
                        if (opts.tracing) std.log.debug("Found val: {s}", .{var_pair.key});
                        if (var_pair.value == null or var_pair.value.?.value == null) {
                            return error.ValueCannotBeEmpty;
                        }

                        switch (var_pair.value.?.value.?) {
                            .bool_value => |bv| {
                                try self.stack.push(Value{ .bool_value = bv });
                            },
                            .float_value => |fv| {
                                try self.stack.push(Value{ .float_value = fv });
                            },
                            else => {
                                std.log.err("Unsupported variable type for variable: {s}", .{pushVariable.variableName});
                                return error.UnsupportedVariableType;
                            },
                        }

                        break :run_instruction;
                    }
                }

                return error.ValueNotFound;
            },
            .jumpTo => |jumpTo| {
                self.pc = @as(usize, @intCast(jumpTo.destination)) - 1;
            },
            .jumpIfFalse => |jumpIfFalse| {
                const value = try self.stack.peek();

                if (!value.bool_value) {
                    self.pc = @as(usize, @intCast(jumpIfFalse.destination)) - 1;
                }
            },
            .@"return" => return,
            else => |inst| {
                std.log.warn("Unsupported instruction: {s}", .{@tagName(inst)});
                return error.UnsupportedInstruction;
            },
        }

        self.pc += 1;

        std.log.debug("PC after execution: {d}, Node: {s}", .{ self.pc, self.node.name });

        if (self.pc >= self.node.instructions.items.len) {
            // TODO: Handle node completion properly, including detours and branching
            self.state = .stopped;
        }
    }
}
