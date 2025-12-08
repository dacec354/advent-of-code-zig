const std = @import("std");

const INIT_POS = 50;
// 0 - 99
const MAX_LENGTH = 100;

pub fn main() !void {
    var curr_pos: i64 = INIT_POS;
    // answer
    var zero_count: u64 = 0;

    // file reader
    const input_file = try std.fs.cwd().openFile("./input/day1.txt", .{});
    defer input_file.close();
    var file_buffer: [16]u8 = undefined;
    var file_reader = input_file.reader(&file_buffer);
    const reader = &file_reader.interface;

    // stdout
    var stdout_buffer: [16]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    while (reader.takeDelimiterInclusive('\n')) |line| {
        if (line.len <= 1) continue;
        const num = try std.fmt.parseInt(u32, line[1..(line.len - 1)], 10);
        // add whole round count
        zero_count += num / MAX_LENGTH;

        switch (line[0]) {
            'R' => {
                const prev_pos = curr_pos;
                curr_pos += num;
                curr_pos = @mod(curr_pos, MAX_LENGTH);
                if (curr_pos < prev_pos) {
                    zero_count += 1;
                }
            },
            'L' => {
                const prev_pos = curr_pos;
                curr_pos -= num;
                curr_pos = @mod(curr_pos, MAX_LENGTH);
                if (prev_pos != 0 and (curr_pos == 0 or curr_pos > prev_pos)) {
                    zero_count += 1;
                }
            },
            else => @panic("Invalid input"),
        }
    } else |_| {}

    try stdout.print("{d}\n", .{zero_count});
    try stdout.flush();
}
