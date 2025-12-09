const std = @import("std");

// stdout
var stdout_buffer: [64]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

pub fn main() !void {
    // file reader
    const input_file = try std.fs.cwd().openFile("./input/day7.txt", .{});
    defer input_file.close();
    var file_buffer: [4096]u8 = undefined;
    var file_reader = input_file.reader(&file_buffer);
    const reader = &file_reader.interface;

    // allocator
    const allocator = std.heap.smp_allocator;

    // answer
    var sum: u64 = 0;

    var board_arr = try std.ArrayList([]usize).initCapacity(allocator, 16);
    var length: usize = 0;

    // inputs
    while (try reader.takeDelimiter('\n')) |line| {
        length = @max(length, line.len);
        var splitters = try std.ArrayList(usize).initCapacity(allocator, 16);
        for (line, 0..) |c, i| {
            switch (c) {
                'S', '^' => try splitters.append(allocator, i),
                else => {},
            }
        }
        if (splitters.items.len == 0) splitters.deinit(allocator) else try board_arr.append(allocator, try splitters.toOwnedSlice(allocator));
    }

    // layers of splitters
    const board = try board_arr.toOwnedSlice(allocator);
    defer {
        for (board) |line| {
            allocator.free(line);
        }
        allocator.free(board);
    }

    // beams
    const beams = try allocator.alloc(u8, length);
    defer allocator.free(beams);
    for (beams) |*c| c.* = 0; // 0 means no beam
    for (board[0]) |s| beams[s] = 1; // > 0 means has beam

    for (board[1..]) |splitters| {
        // `curr` hits splitters in `splitters`
        for (splitters) |s| {
            if (beams[s] != 0) {
                sum += 1;
                beams[s] = 2; // 2 means beam hit splitter
            }
        }

        // spread beams when hit
        for (beams, 0..) |c, i| {
            if (c == 2) {
                beams[i] = 0;
                if (i - 1 >= 0) beams[i - 1] = 1;
                if (i + 1 < length) beams[i + 1] = 1;
            }
        }
    }

    try stdout.print("{d}\n", .{sum});
    try stdout.flush();
}
