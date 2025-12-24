const std = @import("std");

// stdout
var stdout_buffer: [64]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

const INPUT_PATH = "./input/day10.txt";

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
    var res: u64 = 0;

    while (try reader.takeDelimiter('\n')) |line| {
        // linear equations
        var target_mask = Mask.initEmpty();
        var button_mask_arr = try std.ArrayList(Mask).initCapacity(allocator, 64);
        var n: usize = undefined; // num of variables

        // parsing input
        var iter = std.mem.splitScalar(u8, line, ' ');
        // parsing target [.##..]
        var str = iter.next().?;
        n = str.len - 2;
        for (str[1 .. str.len - 1], 0..) |c, i| switch (c) {
            '#' => target_mask.set(i),
            '.' => {},
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
            var it = std.mem.splitScalar(u8, button_str[1 .. button_str.len - 1], ',');
            while (it.next()) |index_str| {
                const i = try std.fmt.parseInt(usize, index_str, 10);
                button_mask.set(i);
            }
            try button_mask_arr.append(allocator, button_mask);
        }

        // gaussian elimination
        const solution = try gaussianEliminationGF2(allocator, n, button_mask_arr.items, target_mask);
        switch (solution) {
            .no_solution => {
                std.debug.print("line: {s}\n", .{line});
                @panic("Invalid input, no solution");
            },
            .infinite => |s| {
                res += s.count();
            },
            .unique => |s| {
                res += s.count();
            },
        }
    }

    try stdout.print("{d}\n", .{res});
    try stdout.flush();
}

const Mask = std.bit_set.IntegerBitSet(32);

fn SolveResult(comptime T: type) type {
    return union(enum) { no_solution, unique: T, infinite: T };
}

fn gaussianEliminationGF2(allocator: std.mem.Allocator, n: usize, buttons: []const Mask, target: Mask) !SolveResult(Mask) {
    // transpose it to mxn
    const m = buttons.len;
    const augmented_matrix = try allocator.alloc(Mask, n);
    defer allocator.free(augmented_matrix);
    for (0..n) |row| {
        var mask = Mask.initEmpty();

        for (0..m) |col| if (buttons[col].isSet(row)) mask.set(col);

        if (target.isSet(row)) mask.set(m);

        augmented_matrix[row] = mask;
    }

    var arr_buffer: [Mask.bit_length]usize = undefined;
    var pivot_cols_arr = std.ArrayList(usize).initBuffer(&arr_buffer);
    var free_col_buffer: [Mask.bit_length]usize = undefined;
    var free_col_arr = std.ArrayList(usize).initBuffer(&free_col_buffer);

    // elimination
    var pivot_row: usize = 0;
    for (0..m) |col| {
        const target_pivot_row = for (pivot_row..augmented_matrix.len) |j| {
            if (augmented_matrix[j].isSet(col)) break j;
        } else {
            try free_col_arr.appendBounded(col);
            continue;
        };
        // printMatrix(augmented_matrix, m);

        // swap
        if (target_pivot_row != pivot_row) {
            const temp = augmented_matrix[pivot_row];
            augmented_matrix[pivot_row] = augmented_matrix[target_pivot_row];
            augmented_matrix[target_pivot_row] = temp;
        }

        // forward elimination
        for (augmented_matrix, 0..) |*bs, i| {
            if (i != pivot_row and bs.isSet(col)) bs.toggleSet(augmented_matrix[pivot_row]);
        }

        try pivot_cols_arr.appendBounded(col);
        pivot_row += 1;
    }
    // printMatrix(augmented_matrix, m);

    // check no solution
    for (augmented_matrix[pivot_row..]) |bs| {
        if (bs.isSet(m)) return .no_solution;
    }

    var best_solution = Mask.initEmpty();
    for (0..pivot_cols_arr.items.len) |i| {
        if (augmented_matrix[i].isSet(m)) best_solution.set(pivot_cols_arr.items[i]);
    }

    // unique solution
    if (free_col_arr.items.len == 0) return .{ .unique = best_solution };

    // infinite solution, find one with smallest weight
    var min_weight = m + 1;
    const particular_solution = best_solution;
    for (0..@as(usize, 1) << @intCast(free_col_arr.items.len)) |i| {
        var solution = particular_solution;
        for (0..free_col_arr.items.len) |j| {
            // apply homogenerous solution
            if ((i >> @intCast(j)) & 1 == 1) {
                solution.set(free_col_arr.items[j]);
                for (0..augmented_matrix.len) |row| {
                    if (augmented_matrix[row].isSet(free_col_arr.items[j])) solution.toggle(pivot_cols_arr.items[row]);
                }
            }
        }

        const weight = solution.count();
        if (weight < min_weight) {
            best_solution = solution;
            min_weight = weight;
        }
    }
    return .{ .infinite = best_solution };
}

fn printMatrix(m: []const Mask, n: usize) void {
    std.debug.print("matrix:\n", .{});
    for (m) |bs| {
        std.debug.print("[", .{});
        for (0..n + 1) |i| {
            const c: u8 = if (bs.isSet(i)) '1' else '0';
            std.debug.print("{c}", .{c});
            if (i < n) std.debug.print(", ", .{});
        }
        std.debug.print("]\n", .{});
    }
}
