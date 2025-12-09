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

    // first line
    const line = try reader.takeDelimiter('\n') orelse @panic("Invalid input");
    var nums_arr = try std.ArrayList(u64).initCapacity(allocator, 200);

    // initialize
    var iter = std.mem.splitScalar(u8, line, ' ');
    while (iter.next()) |num_str| {
        if (num_str.len == 0) continue;
        const num = try std.fmt.parseInt(u64, num_str, 10);
        try nums_arr.append(allocator, num);
    }
    var adds = try nums_arr.toOwnedSlice(allocator);
    defer allocator.free(adds);
    var muls = try allocator.alloc(u64, adds.len);
    defer allocator.free(muls);
    @memcpy(muls, adds);

    var i: usize = 0;
    while (try reader.takeDelimiter('\n')) |l| {
        const trim = std.mem.trimStart(u8, l, " ");
        if (trim[0] == '+' or trim[0] == '*') {
            iter = std.mem.splitScalar(u8, l, ' ');
            i = 0;
            while (iter.next()) |sym_str| {
                if (sym_str.len == 0) continue else if (sym_str[0] == '+') sum += adds[i] else sum += muls[i];
                i += 1;
            }
            break;
        }

        iter = std.mem.splitScalar(u8, l, ' ');
        i = 0;
        while (iter.next()) |num_str| {
            if (num_str.len == 0) continue;
            const num = try std.fmt.parseInt(u64, num_str, 10);
            adds[i] += num;
            muls[i] *= num;
            i += 1;
        }
    }

    try stdout.print("{d}\n", .{sum});
    try stdout.flush();
}
