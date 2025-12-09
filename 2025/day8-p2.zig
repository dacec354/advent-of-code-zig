const std = @import("std");

// stdout
var stdout_buffer: [64]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

pub fn main() !void {
    // file reader
    const input_file = try std.fs.cwd().openFile("./input/day8.txt", .{});
    defer input_file.close();
    var file_buffer: [4096]u8 = undefined;
    var file_reader = input_file.reader(&file_buffer);
    const reader = &file_reader.interface;

    // allocator
    const allocator = std.heap.smp_allocator;

    // answer
    var res: u64 = 1;

    // x, y, z coords
    var coords_arr = try std.ArrayList(Coord).initCapacity(allocator, 1000);
    while (try reader.takeDelimiter('\n')) |line| {
        var iter = std.mem.splitScalar(u8, line, ',');
        const x = try std.fmt.parseInt(i64, iter.next() orelse @panic("Invalid input"), 10);
        const y = try std.fmt.parseInt(i64, iter.next() orelse @panic("Invalid input"), 10);
        const z = try std.fmt.parseInt(i64, iter.next() orelse @panic("Invalid input"), 10);

        try coords_arr.append(allocator, .{ .x = x, .y = y, .z = z });
    }
    const coords: []const Coord = try coords_arr.toOwnedSlice(allocator);
    defer allocator.free(coords);

    // distance table
    const distances: Distances(i64) = try .init(allocator, coords);
    defer distances.deinit(allocator);

    // all pair
    var pairs_arr = try std.ArrayList(Pair).initCapacity(allocator, coords.len * (coords.len - 1) / 2);
    for (0..coords.len) |i| {
        for (i + 1..coords.len) |j| {
            try pairs_arr.append(allocator, .{ i, j });
        }
    }
    const pairs = try pairs_arr.toOwnedSlice(allocator);
    defer allocator.free(pairs);

    // sort
    const SortContext = struct { coords: []const Coord };
    const lessThanFn = struct {
        fn func(ctx: SortContext, lhs: Pair, rhs: Pair) bool {
            return Distances(i64).distance(ctx.coords[lhs.@"0"], ctx.coords[lhs.@"1"]) <
                Distances(i64).distance(ctx.coords[rhs.@"0"], ctx.coords[rhs.@"1"]);
        }
    }.func;
    std.mem.sort(Pair, pairs, SortContext{ .coords = coords }, lessThanFn);

    // union set
    var set = try UnionFindSet(i16).init(allocator, coords.len);

    var count: usize = 0;
    for (0..pairs.len) |i| {
        // connect coords.len - 1 times to connect all points
        if (count >= coords.len - 1) break;
        const p = pairs[i];
        if (set.isConnected(p.@"0", p.@"1")) continue;

        set.@"union"(p.@"0", p.@"1");

        count += 1;

        // last time of connection
        if (count == coords.len - 1) {
            res = @as(u64, @intCast(coords[p.@"0"].x)) * @as(u64, @intCast(coords[p.@"1"].x));
        }
    }

    try stdout.print("{d}\n", .{res});
    try stdout.flush();
}

fn UnionFindSet(comptime signed_int_type: type) type {
    const type_info = @typeInfo(signed_int_type);
    if (type_info != .int or type_info.int.signedness == .unsigned) {
        @compileError("Union-Find requires signed integer type");
    }

    return struct {
        data: []signed_int_type,
        const This = @This();

        pub fn init(allocator: std.mem.Allocator, size: usize) !This {
            const data = try allocator.alloc(signed_int_type, size);
            @memset(data, -1);
            return This{ .data = data };
        }

        pub fn deinit(self: This, allocator: std.mem.Allocator) void {
            allocator.free(self.data);
        }

        pub fn find(self: *This, x: usize) usize {
            if (self.data[x] < 0) return x;

            const root = self.find(@intCast(self.data[x]));
            self.data[x] = @intCast(root);
            return root;
        }

        pub fn @"union"(self: *This, a: usize, b: usize) void {
            const root_a = self.find(a);
            const root_b = self.find(b);

            if (root_a == root_b) return;

            if (self.data[root_a] < self.data[root_b]) {
                self.data[root_a] += self.data[root_b];
                self.data[root_b] = @intCast(root_a);
            } else {
                self.data[root_b] += self.data[root_a];
                self.data[root_a] = @intCast(root_b);
            }
        }

        pub fn isConnected(self: *This, a: usize, b: usize) bool {
            return self.find(a) == self.find(b);
        }
    };
}

const Pair = struct { usize, usize };

const Coord = struct {
    x: i64,
    y: i64,
    z: i64,
};

/// square of 2-th norm which is sufficient for comparision
fn Distances(int_type: type) type {
    return struct {
        size: usize,
        data: []int_type,

        fn init(allocator: std.mem.Allocator, coords: []const Coord) !Distances(int_type) {
            const size = coords.len;
            const data = try allocator.alloc(int_type, size * size);
            for (coords, 0..) |c1, i| {
                for (coords, 0..) |c2, j| {
                    data[i * size + j] = Distances(int_type).distance(c1, c2);
                }
            }
            return .{
                .size = size,
                .data = data,
            };
        }

        fn deinit(this: *const @This(), allocator: std.mem.Allocator) void {
            allocator.free(this.data);
        }

        fn get(this: @This(), i: usize, j: usize) int_type {
            return this.data[i * this.size + j];
        }

        inline fn distance(a: Coord, b: Coord) int_type {
            const x_square = std.math.pow(u64, @abs(a.x - b.x), 2);
            const y_square = std.math.pow(u64, @abs(a.y - b.y), 2);
            const z_square = std.math.pow(u64, @abs(a.z - b.z), 2);
            return @intCast(x_square + y_square + z_square);
        }
    };
}
