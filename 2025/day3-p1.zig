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

    while (true) {
        // read a line
        const line = reader.takeDelimiterExclusive('\n') catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        // skip '\n' and possible eof
        _ = reader.takeByte() catch |err| switch (err) {
            error.EndOfStream => {},
            else => return err,
        };

        sum += findLargestDigitPair(line);
    }

    try stdout.print("{d}\n", .{sum});
    try stdout.flush();
}

fn findLargestDigitPair(line: []u8) u64 {
    var max_index: usize = 0;
    var sub_max_index: usize = 0;
    for (0.., line[0 .. line.len - 1]) |i, c| {
        if (c > line[max_index]) {
            max_index = i;
            sub_max_index = 0;
        } else if (i != 0 and (sub_max_index == 0 or c > line[sub_max_index])) {
            sub_max_index = i;
        }
    }

    const first_digit = line[max_index] - '0';
    const second_digit = if (sub_max_index != 0 and line[sub_max_index] > line[line.len - 1])
        line[sub_max_index] - '0'
    else
        line[line.len - 1] - '0';
    return 10 * @as(u64, first_digit) + second_digit;
}
