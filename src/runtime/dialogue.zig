const std = @import("std");
const csvz = @import("csvzero");

pub const LineParseResult = struct {
    field_id: []const u8,
    line: Line,
};

pub const Line = struct {
    id: []const u8,
    text: []const u8,
    file: []const u8,
    node: []const u8,
    line_number: u32,
};

/// Caller is responsible for freeing the returned StringHashMap when done with it.
pub fn parseDialogueFromCsv(io: std.Io, allocator: std.mem.Allocator, path: []const u8) !std.StringHashMap(Line) {
    var csv_file = try std.Io.Dir.cwd().openFile(io, path, .{});
    defer csv_file.close(io);

    var file_buffer: [1024]u8 = undefined;
    var file_reader = csv_file.reader(io, &file_buffer);

    var it = csvz.Iterator.init(&file_reader.interface);

    var dialogue_map = std.StringHashMap(Line).init(allocator);

    // Skip header row
    for (0..5) |_| {
        _ = it.next() catch |err| switch (err) {
            csvz.Iterator.Error.EOF => return error.UnexpectedEOF,
            else => return err,
        };
    }

    // Parse line info
    while (true) {
        var field = it.next() catch |err| switch (err) {
            csvz.Iterator.Error.EOF => break,
            else => return err,
        };

        const field_id = try allocator.dupe(u8, field.unescaped());

        field = it.next() catch |err| switch (err) {
            csvz.Iterator.Error.EOF => break,
            else => return err,
        };

        const text = try allocator.dupe(u8, field.unescaped());

        field = it.next() catch |err| switch (err) {
            csvz.Iterator.Error.EOF => break,
            else => return err,
        };

        const file = try allocator.dupe(u8, field.unescaped());

        field = it.next() catch |err| switch (err) {
            csvz.Iterator.Error.EOF => break,
            else => return err,
        };

        const node = try allocator.dupe(u8, field.unescaped());

        field = it.next() catch |err| switch (err) {
            csvz.Iterator.Error.EOF => break,
            else => return err,
        };

        const line_number_str = try allocator.dupe(u8, field.unescaped());
        const line_number = try std.fmt.parseInt(u32, line_number_str, 10);

        const line = Line{
            .id = field_id,
            .text = text,
            .file = file,
            .node = node,
            .line_number = line_number,
        };

        try dialogue_map.put(line.id, line);
    }

    return dialogue_map;
}
