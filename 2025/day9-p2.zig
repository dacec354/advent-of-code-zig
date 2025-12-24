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

    // parsing input
    var points_arr, var unique_xs_arr, var unique_ys_arr = blk: {
        // points
        var points_arr = try std.ArrayList(Point).initCapacity(allocator, 1000);

        // x and y collection
        var xs_arr = try std.ArrayList(i64).initCapacity(allocator, 1000);
        defer xs_arr.deinit(allocator);
        var ys_arr = try std.ArrayList(i64).initCapacity(allocator, 1000);
        defer ys_arr.deinit(allocator);
        while (try reader.takeDelimiter('\n')) |line| {
            var iter = std.mem.splitScalar(u8, line, ',');
            const x = try std.fmt.parseInt(i64, iter.next() orelse @panic("Invalid input"), 10);
            const y = try std.fmt.parseInt(i64, iter.next() orelse @panic("Invalid input"), 10);

            try points_arr.append(allocator, .{ .x = x, .y = y });
            try xs_arr.append(allocator, x);
            try ys_arr.append(allocator, y);
        }

        std.mem.sort(i64, xs_arr.items, {}, std.sort.asc(i64));
        std.mem.sort(i64, ys_arr.items, {}, std.sort.asc(i64));

        // unique x and y for grid
        var unique_xs_arr = try std.ArrayList(i64).initCapacity(allocator, 1000);
        var unique_ys_arr = try std.ArrayList(i64).initCapacity(allocator, 1000);

        var last_x = xs_arr.items[0];
        var last_y = ys_arr.items[1];
        try unique_xs_arr.append(allocator, last_x);
        try unique_ys_arr.append(allocator, last_y);
        for (xs_arr.items[1..], ys_arr.items[1..]) |x, y| {
            if (x != last_x) try unique_xs_arr.append(allocator, x);
            if (y != last_y) try unique_ys_arr.append(allocator, y);
            last_x = x;
            last_y = y;
        }

        break :blk .{ points_arr, unique_xs_arr, unique_ys_arr };
    };
    defer points_arr.deinit(allocator);
    defer unique_xs_arr.deinit(allocator);
    defer unique_ys_arr.deinit(allocator);

    const grid_w = unique_xs_arr.items.len;
    const grid_h = unique_ys_arr.items.len;

    // position map
    var x_to_index = std.AutoHashMap(i64, usize).init(allocator);
    defer x_to_index.deinit();
    var y_to_index = std.AutoHashMap(i64, usize).init(allocator);
    defer y_to_index.deinit();

    for (unique_xs_arr.items, 0..) |x, i| try x_to_index.put(x, i);
    for (unique_ys_arr.items, 0..) |y, i| try y_to_index.put(y, i);

    // compression grid
    const grid_storage = try allocator.alloc(bool, grid_h * grid_w);
    defer allocator.free(grid_storage);
    @memset(grid_storage, false);

    var grid = try allocator.alloc([]bool, grid_h);
    defer allocator.free(grid);
    for (0..grid_h) |i| {
        grid[i] = grid_storage[grid_w * i .. grid_w * (i + 1)];
    }

    // mark line of grid
    for (0..points_arr.items.len) |i| {
        const p0 = points_arr.items[i];
        const p1 = points_arr.items[(i + 1) % points_arr.items.len];

        const p0x_index = x_to_index.get(p0.x).?;
        const p0y_index = y_to_index.get(p0.y).?;
        const p1x_index = x_to_index.get(p1.x).?;
        const p1y_index = y_to_index.get(p1.y).?;

        if (p0.y == p1.y) { // horizonal
            const y_index = p0y_index;
            const start: usize = @min(p0x_index, p1x_index);
            const end: usize = @max(p0x_index, p1x_index) + 1;
            for (start..end) |x_index| grid[y_index][x_index] = true;
        } else { // vertical
            const x_index = p0x_index;
            const start: usize = @min(p0y_index, p1y_index);
            const end: usize = @max(p0y_index, p1y_index) + 1;
            for (start..end) |y_index| grid[y_index][x_index] = true;
        }
    }

    // mark internal space of grid, horizonal scanning
    const buffer = try allocator.alloc(usize, @divExact(points_arr.items.len, 2));
    defer allocator.free(buffer);
    for (0..grid_h) |y_index| {
        const y = unique_ys_arr.items[y_index];
        // vertical line's x that crosses current horizonal line
        var crossings_arr = std.ArrayList(usize).initBuffer(buffer);

        for (0..points_arr.items.len) |i| {
            const p0 = points_arr.items[i];
            const p1 = points_arr.items[(i + 1) % points_arr.items.len];

            if (p0.x == p1.x) {
                const min_y = @min(p0.y, p1.y);
                const max_y = @max(p0.y, p1.y);
                if (y < max_y and y >= min_y) {
                    const x_index = x_to_index.get(p0.x).?;
                    try crossings_arr.appendBounded(x_index);
                }
            }
        }
        std.mem.sort(usize, crossings_arr.items, {}, std.sort.asc(usize));

        {
            var i: usize = 0;
            while (i < crossings_arr.items.len) : (i += 2) {
                const start = crossings_arr.items[i] + 1;
                const end = crossings_arr.items[i + 1];
                for (start..end) |x_index| {
                    grid[y_index][x_index] = true;
                }
            }
        }
    }

    // prefix sum of left-up marked count
    const prefix_storage = try allocator.alloc(u64, (grid_w + 1) * (grid_h + 1));
    defer allocator.free(prefix_storage);
    @memset(prefix_storage, 0);

    var prefix = try allocator.alloc([]u64, grid_h + 1);
    for (0..grid_h + 1) |y_index| {
        prefix[y_index] = prefix_storage[(grid_w + 1) * y_index .. (grid_w + 1) * (y_index + 1)];
    }

    for (0..grid_h) |y_index| {
        for (0..grid_w) |x_index| {
            const cell: u64 = @intFromBool(grid[y_index][x_index]);
            prefix[y_index + 1][x_index + 1] = prefix[y_index + 1][x_index] + prefix[y_index][x_index + 1] - prefix[y_index][x_index] + cell;
        }
    }

    // query function: if any points in rectangle
    const query = struct {
        fn f(prefix_: []const []const u64, y0: usize, x0: usize, y1: usize, x1: usize) u64 {
            return prefix_[y1 + 1][x1 + 1] + prefix_[y0][x0] - prefix_[y1 + 1][x0] - prefix_[y0][x1 + 1];
        }
    }.f;

    // enumerate point pairs
    var max_area: i64 = 0;
    var point0: Point = undefined;
    var point1: Point = undefined;
    for (0..points_arr.items.len) |i| {
        for (i + 1..points_arr.items.len) |j| {
            const p0 = points_arr.items[i];
            const p1 = points_arr.items[j];

            const x_l = @min(p0.x, p1.x);
            const x_r = @max(p0.x, p1.x);
            const y_t = @min(p0.y, p1.y);
            const y_b = @max(p0.y, p1.y);

            // compressed position
            const x_l_index = x_to_index.get(x_l).?;
            const x_r_index = x_to_index.get(x_r).?;
            const y_t_index = y_to_index.get(y_t).?;
            const y_b_index = y_to_index.get(y_b).?;

            const grid_area = area(usize, y_t_index, x_l_index, y_b_index, x_r_index);
            const expected_grid_area = query(prefix, y_t_index, x_l_index, y_b_index, x_r_index);
            if (grid_area == expected_grid_area) {
                const actual_area = area(i64, y_t, x_l, y_b, x_r);
                if (actual_area < max_area) continue;
                max_area = actual_area;
                point0 = p0;
                point1 = p1;
            }
        }
    }

    const x_l = @min(point0.x, point1.x);
    const x_r = @max(point0.x, point1.x);
    const y_t = @min(point0.y, point1.y);
    const y_b = @max(point0.y, point1.y);
    res = @intCast(area(i64, y_t, x_l, y_b, x_r));

    try stdout.print("{}, {}: {d}\n", .{ point0, point1, res });
    try stdout.flush();
}

const Point = struct {
    x: i64,
    y: i64,
};

fn area(IntType: type, y0: IntType, x0: IntType, y1: IntType, x1: IntType) IntType {
    return (y1 - y0 + 1) * (x1 - x0 + 1);
}
