const std = @import("std");

pub fn main() !void {
    const init_pos = 50;
    // 0 - 99
    const length = 100;
    var curr_pos: i64 = init_pos;
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
        switch (line[0]) {
            'R' => curr_pos += num,
            'L' => curr_pos -= num,
            else => @panic("Invalid input"),
        }
        curr_pos = @mod(curr_pos, length);
        if (curr_pos == 0) {
            zero_count += 1;
        }
    } else |_| {}

    try stdout.print("{d}\n", .{zero_count});
    try stdout.flush();
}
