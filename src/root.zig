//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

pub const Yarn = @import("proto/Yarn.pb.zig");
pub const VirtualMachine = @import("runtime/vm.zig");
pub const Dialogue = @import("runtime/dialogue.zig");
pub const Option = VirtualMachine.Option;

pub fn parseProtobuf(path: []const u8, io: std.Io, allocator: std.mem.Allocator) !Yarn.Program {
    std.log.debug("Parsing protobuf file: {s}", .{path});
    const file = try std.Io.Dir.cwd().openFile(io, path, .{});
    defer file.close(io);

    var file_buffer: [1024]u8 = undefined;
    var file_reader = file.reader(io, &file_buffer);
    return try Yarn.Program.decode(&file_reader.interface, allocator);
}

/// This is a documentation comment to explain the `printAnotherMessage` function below.
///
/// Accepting an `Io.Writer` instance is a handy way to write reusable code.
pub fn printAnotherMessage(writer: *Io.Writer) Io.Writer.Error!void {
    try writer.print("Run `zig build test` to run the tests.\n", .{});
}

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}
