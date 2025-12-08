const std = @import("std");

pub fn main() !void {
    // file reader
    const input_file = try std.fs.cwd().openFile("./input/day3.txt", .{});
    defer input_file.close();
    var file_buffer: [128]u8 = undefined;
    var file_reader = input_file.reader(&file_buffer);
    const reader = &file_reader.interface;

    // stdout
    var stdout_buffer: [16]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // answer
    var sum: u64 = 0;

    while (try reader.takeDelimiter('\n')) |line| {
        findAccumulateLargestDigits(12, line, &sum);
    }

    try stdout.print("{d}\n", .{sum});
    try stdout.flush();
}

fn findAccumulateLargestDigits(n: comptime_int, line: []const u8, sum: *u64) void {
    std.debug.assert(line.len >= n);
    // monotone stack
    var buffer: [n]u8 = [_]u8{0} ** n;
    var stack = std.ArrayList(u8).initBuffer(&buffer);
    var removals_left = line.len - n;

    for (line) |c| {
        while (removals_left > 0 and stack.items.len > 0 and stack.getLast() < c) : (removals_left -= 1) {
            _ = stack.pop();
        }

        stack.appendBounded(c) catch {
            removals_left -= 1;
        };
    }

    var res: u64 = 0;
    for (stack.items) |item| {
        res *= 10;
        res += item - '0';
    }

    sum.* += res;
}
