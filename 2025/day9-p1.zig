const std = @import("std");

// stdout
var stdout_buffer: [64]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

const INPUT_PATH = "./input/day9.txt";

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

    // x, y coords
    var coords_arr = try std.ArrayList(Coord).initCapacity(allocator, 1000);
    while (try reader.takeDelimiter('\n')) |line| {
        var iter = std.mem.splitScalar(u8, line, ',');
        const x = try std.fmt.parseInt(i64, iter.next() orelse @panic("Invalid input"), 10);
        const y = try std.fmt.parseInt(i64, iter.next() orelse @panic("Invalid input"), 10);

        try coords_arr.append(allocator, .{ x, y });
    }
    const coords = try coords_arr.toOwnedSlice(allocator);
    defer allocator.free(coords);

    // sort coords by x and y
    const lessThanFn = struct {
        fn func(_: void, a: Coord, b: Coord) bool {
            return if (a.@"0" != b.@"0") a.@"0" < b.@"0" else a.@"1" < b.@"1";
        }
    }.func;
    std.mem.sort(Coord, coords, {}, lessThanFn);

    // min max set
    var min_arr = try std.ArrayList(usize).initCapacity(allocator, coords.len);
    defer min_arr.deinit(allocator);
    var max_arr = try std.ArrayList(usize).initCapacity(allocator, coords.len);
    defer max_arr.deinit(allocator);

    var last_index: usize = 0;
    try min_arr.append(allocator, 0);
    for (1..coords.len) |i| {
        if (coords[last_index].@"0" != coords[i].@"0") {
            // prevent adding a coord twice
            try max_arr.append(allocator, last_index);
            try min_arr.append(allocator, i);
        }
        last_index = i;
    }
    try max_arr.append(allocator, last_index);

    // all pair
    var c0_index: usize = 0;
    var c1_index: usize = 0;
    var max_area: u64 = area(coords[c0_index], coords[c1_index]);
    for (min_arr.items) |i| {
        for (max_arr.items) |j| {
            if (i == j) continue;
            const a = area(coords[i], coords[j]);
            if (max_area < a) {
                max_area = a;
                c0_index = i;
                c1_index = j;
            }
            max_area = @max(max_area, area(coords[i], coords[j]));
        }
    }

    const c0 = coords[c0_index];
    const c1 = coords[c1_index];

    res = area(c0, c1);

    try stdout.print("{}, {}: {d}\n", .{ c0, c1, res });
    try stdout.flush();
}
const Coord = struct { i64, i64 };

const Pair = struct { usize, usize };

fn area(a: Coord, b: Coord) u64 {
    return @intCast((@abs(a.@"0" - b.@"0") + 1) * (@abs(a.@"1" - b.@"1") + 1));
}
