const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: path-out <input_file>\n", .{});
        return;
    }

    const file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();
    var file_buffer: [4096]u8 = undefined;
    var file_reader = file.reader(&file_buffer);
    const reader = &file_reader.interface;

    // shapes
    const shape: Shape = .initReader(reader);

    // solve
    const total = try solve(allocator, shape);

    std.debug.print("\nTotal minimum button presses: {}\n", .{total});
}

const Shape = struct {
    const MAX_WIDTH = 8;
    const MAX_HEIGHT = 8;
    const ShapeVariant = struct {
        const Self = @This();

        cells: [MAX_HEIGHT * MAX_WIDTH][2]i8,
        cell_count: usize,
        width: usize,
        height: usize,

        fn initLines(lines: []const u8) ShapeVariant {
            var cells: [MAX_HEIGHT * MAX_WIDTH][2]i8 = .{};
            var count: usize = 0;
            var width: usize = 0;
            for (lines, 0..) |line, height| {
                if (line.len == 0) break;
                if (width == 0) width = line.len;
                for (line, 0..) |c, i| {
                    switch (c) {
                        '#' => {
                            cells[count] = .{ i, height };
                            count += 1;
                        },
                        else => {},
                    }
                }
            }
            return .{
                .cells = cells,
                .cell_count = count,
                .width = width,
                .height = lines.len,
            };
        }
    };

    variants: [8]ShapeVariant,
    variant_count: usize,

    fn initLines(lines: []const u8) Shape {
        var variants: [8]ShapeVariant = .{};
        variants[0] = .initLines(lines);

        // generate variants
        const transforms: [7][2][2]i8 = .{
            .{
                .{ 1, 0 },
                .{ 0, -1 },
            },
            .{
                .{ -1, 0 },
                .{ 0, 1 },
            },
            .{
                .{ -1, 0 },
                .{ 0, -1 },
            },
            .{
                .{ 0, 1 },
                .{ 1, 0 },
            },
            .{
                .{ 0, 1 },
                .{ -1, 0 },
            },
            .{
                .{ 0, -1 },
                .{ 1, 0 },
            },
            .{
                .{ 0, -1 },
                .{ -1, 0 },
            },
        };

        var count: usize = 0;
        const init = variants[0];
        inline for (transforms) |t| {
            for (variants[count].cells, init.cells) |*c, i| {
                c.* = .{ t[0][0] * i[0] + t[0][1] * i[1], t[1][0] * i[0] + t[1][1] * i[1] };
            }

            if (!eqlShapeVariant(variants[count], init)) count += 1;
        }

        return .{
            .variants = variants,
            .variant_count = count,
        };
    }
};

fn eqlShapeVariant(a: Shape.ShapeVariant, b: Shape.ShapeVariant) bool {
    if (a.cell_count != b.cell_count or a.height != b.height or a.width != b.width) return false;
    for (0..a.cell_count) |i| {
        if (a.cells[i][0] != b.cells[i][0] or a.cells[i][1] != b.cells[i][1]) return false;
    }
    return true;
}

fn parseShapes(allocator: std.mem.Allocator, reader: *std.Io.Reader) ![]const Shape {
    var buffer: [8][]const u8 = undefined;
    var lines_arr: std.ArrayList([]const u8) = .initBuffer(&buffer);
    var shapes_arr: std.ArrayList(Shape) = try .initCapacity(allocator, 8);
    while (try reader.peekDelimiterExclusive('\n')) |line| {
        if (std.mem.endsWith(u8, line, ":")) { // parsing shapes
            _ = try reader.takeDelimiter('\n');
            while (try reader.takeDelimiter('\n')) |l| {
                if (l.len == 0) break;
                try lines_arr.appendBounded(l);
            }
            try shapes_arr.append(allocator, .initLines(lines_arr.items));
        } else break;
    }
    return try shapes_arr.toOwnedSlice(allocator);
}

fn solve(allocator: std.mem.Allocator, shapes: []const Shape) !usize {
    var memory: std.StringHashMap(usize) = .init(allocator);
    defer memory.deinit();

    const dac_to_fft = try dp(&memory, path_graph, "dac", "fft");
    memory.clearRetainingCapacity();
    if (dac_to_fft != 0) {
        const start_to_dac = try dp(&memory, path_graph, "svr", "dac");
        memory.clearRetainingCapacity();
        const fft_to_end = try dp(&memory, path_graph, "fft", "out");

        return start_to_dac * dac_to_fft * fft_to_end;
    } else {
        const fft_to_dac = try dp(&memory, path_graph, "fft", "dac");
        memory.clearRetainingCapacity();
        const start_to_fft = try dp(&memory, path_graph, "svr", "fft");
        memory.clearRetainingCapacity();
        const dac_to_end = try dp(&memory, path_graph, "dac", "out");

        return start_to_fft * fft_to_dac * dac_to_end;
    }
}

fn dp(memory: *std.StringHashMap(usize), graph: std.StringHashMap(std.ArrayList([]const u8)), start: []const u8, end: []const u8) !usize {
    if (std.mem.eql(u8, start, end)) return 1;
    if (memory.get(start)) |total| return total;

    var total: usize = 0;
    const subs = graph.get(start) orelse return 0; // end nodes do not have children
    for (subs.items) |l| {
        total += try dp(memory, graph, l, end);
    }

    try memory.putNoClobber(start, total);

    return total;
}
