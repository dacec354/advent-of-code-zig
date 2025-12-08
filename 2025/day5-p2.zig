const std = @import("std");

// stdout
var stdout_buffer: [64]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

pub fn main() !void {
    // file reader
    const input_file = try std.fs.cwd().openFile("./input/day5.txt", .{});
    defer input_file.close();
    var file_buffer: [256]u8 = undefined;
    var file_reader = input_file.reader(&file_buffer);
    const reader = &file_reader.interface;

    // allocator
    const allocator = std.heap.smp_allocator;

    // answer
    var sum: u64 = 0;

    // ranges
    var ranges = try std.ArrayList(Range).initCapacity(allocator, 200);
    while (try reader.takeDelimiter('\n')) |line| {
        if (line.len == 0) break;

        const sep = std.mem.indexOf(u8, line, &.{'-'}) orelse @panic("Invalid input");
        try ranges.append(allocator, Range{
            .start = try std.fmt.parseInt(usize, line[0..sep], 0),
            .end = try std.fmt.parseInt(usize, line[sep + 1 ..], 0),
        });
    }

    sum = try findInRangeCount(&ranges);

    try stdout.print("{d}\n", .{sum});
    try stdout.flush();
}

fn findInRangeCount(ranges: *std.ArrayList(Range)) !usize {
    mergeRanges(ranges);

    var sum: usize = 0;
    for (ranges.items) |r| {
        sum += r.end - r.start + 1;
    }
    return sum;
}

/// closed range
const Range = struct {
    start: usize,
    end: usize,
};

fn mergeRanges(ranges: *std.ArrayList(Range)) void {
    const lessThen = struct {
        pub fn func(_: void, a: Range, b: Range) bool {
            return a.start < b.start;
        }
    }.func;
    std.mem.sort(
        Range,
        ranges.items,
        {},
        lessThen,
    );

    var curr_index: usize = 0;
    for (ranges.items, 0..) |r, i| {
        const c = &ranges.items[curr_index];
        if (r.start <= c.end) c.end = @max(r.end, c.end) else {
            curr_index += 1;
            if (i != curr_index) ranges.items[curr_index] = r;
        }
    }

    ranges.items.len = curr_index + 1;
}
