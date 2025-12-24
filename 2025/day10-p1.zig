const std = @import("std");

// stdout
var stdout_buffer: [64]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

const INPUT_PATH = "./input/day10t.txt";

pub fn main() !void {
    // file reader
    const input_file = try std.fs.cwd().openFile(INPUT_PATH, .{});
    defer input_file.close();
    var file_buffer: [4096]u8 = undefined;
    var file_reader = input_file.reader(&file_buffer);
    const reader = &file_reader.interface;

    // allocator
    const allocator = std.heap.smp_allocator;

    // answer
    var res: u64 = 1;

    const Mask = std.bit_set.IntegerBitSet(32);

    while (try reader.takeDelimiter('\n')) |line| {
        // linear equations
        const target_mask = Mask.initEmpty();
        var button_mask_arr = try std.ArrayList(Mask).initCapacity(allocator, 64);
        _ = button_mask_arr; // autofix

        // parsing input
        var iter = std.mem.splitScalar(u8, line, ' ');
        // parsing target [.##..]
        var str = iter.next().?;
        for (str[1 .. str.len - 1], 0..) |c, i| switch (c) {
            '#' => target_mask.set(i),
            else => unreachable,
        };

        // parsing buttons
        var last: []const u8 = undefined;
        while (iter.next()) |button_str| {
            if (iter.peek() == null) {
                last = str;
                break;
            }
            var button_mask = Mask.initEmpty();
            var it = std.mem.splitScalar(u8, button_str[1..button_str.len], ',');
            while (it.next()) |index_str| {
                const i = try std.fmt.parseInt(usize, index_str, 10);
                button_mask.set(i);
            }
            button_mask_arr.append(allocator, button_mask);
        }

        // gaussian elimination

    }

    try stdout.print("{d}\n", .{res});
    try stdout.flush();
}

// context must be a struct have functions:
// fn add(a: T, b; T) T
// fn mul(a: T, b: T) T
fn LinearEquationSystem(T: type, comptime context: anytype, equations: []T, target: T) type {
    _ = context; // autofix
    _ = equations; // autofix
    _ = target; // autofix
    return struct {
        equations: []T,
        target: T,
    };
}
