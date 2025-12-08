const std = @import("std");

pub fn main() !void {
    // answer
    var sum: u64 = 0;

    // closed range [start, end]
    var start: u64 = 0;
    var end: u64 = 0;

    // file reader
    const input_file = try std.fs.cwd().openFile("./input/day2.txt", .{});
    defer input_file.close();
    var file_buffer: [32]u8 = undefined;
    var file_reader = input_file.reader(&file_buffer);
    const reader = &file_reader.interface;

    // stdout
    var stdout_buffer: [16]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    while (true) {
        // read a range
        const start_str = reader.takeDelimiterExclusive('-') catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        start = try std.fmt.parseInt(u64, start_str, 0);
        _ = reader.takeByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        }; // skip '-'

        var end_str = reader.takeDelimiterExclusive(',') catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        if (end_str[end_str.len - 1] == '\n') {
            end_str = end_str[0..(end_str.len - 1)];
        }
        end = try std.fmt.parseInt(u64, end_str, 0);
        _ = reader.takeByte() catch |err| switch (err) {
            error.EndOfStream => {},
            else => return err,
        }; // skip ',' and possible eof

        try findAccumulateInvalidIds(start, end, &sum);
    }

    try stdout.print("{d}\n", .{sum});
    try stdout.flush();
}

/// multi repeat patterns are also invalid
fn findAccumulateInvalidIds(start: u64, end: u64, sum: *u64) !void {
    var buffer: [32]u8 = undefined;
    // std.debug.print("[{d}, {d}]\n", .{ start, end });
    validate_nums: for (start..end + 1) |id| {
        const num_str = try std.fmt.bufPrint(&buffer, "{d}", .{id});

        var index = num_str.len / 2;
        // try different split length
        try_patterns: while (index > 0) : (index -= 1) {
            if (num_str.len % index != 0) continue;
            // compare divisions
            for (1..@divExact(num_str.len, index)) |i| {
                // find unmatched
                if (!std.mem.eql(u8, num_str[0..index], num_str[i * index .. (i + 1) * index]))
                    continue :try_patterns;
            } else { // fits the pattern
                break :try_patterns;
            }
        } else { // no any fits of the pattern, so it is a valid id.
            continue :validate_nums;
        }
        // Invalid id
        // std.debug.print("{s} ", .{num_str});
        sum.* += @intCast(id);
    }
}
