const std = @import("std");

// stdout
var stdout_buffer: [64]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

pub fn main() !void {
    // file reader
    const input_file = try std.fs.cwd().openFile("./input/day6.txt", .{});
    defer input_file.close();
    var file_buffer: [4096]u8 = undefined;
    var file_reader = input_file.reader(&file_buffer);
    const reader = &file_reader.interface;

    // allocator
    const allocator = std.heap.smp_allocator;

    // answer
    var sum: u64 = 0;

    var lines_arr = try std.ArrayList([]const u8).initCapacity(allocator, 16);

    // inputs
    while (try reader.takeDelimiter('\n')) |line| {
        try lines_arr.append(allocator, try allocator.dupe(u8, line));
    }

    const lines = try lines_arr.toOwnedSlice(allocator);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
        allocator.free(lines);
    }
    const symbol_line = lines[lines.len - 1];

    var curr: usize = 0;
    while (curr < symbol_line.len) {
        const next = std.mem.indexOfAnyPos(u8, symbol_line, curr + 1, "*+") orelse symbol_line.len + 1;
        var calc: usize = switch (symbol_line[curr]) {
            '+' => 0,
            '*' => 1,
            else => @panic("Invalid input"),
        };
        for (curr..next - 1) |index| {
            // composing a num
            var num: usize = 0;
            for (lines[0 .. lines.len - 1]) |line| {
                switch (line[index]) {
                    '0'...'9' => |c| {
                        num *= 10;
                        num += c - '0';
                    },
                    else => {},
                }
            }
            switch (symbol_line[curr]) {
                '+' => calc += num,
                '*' => calc *= num,
                else => unreachable,
            }
        }

        sum += calc;
        curr = next;
    }

    try stdout.print("{d}\n", .{sum});
    try stdout.flush();
}
