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

    // path graph
    var path_graph = try parsePathGraph(allocator, reader);
    defer {
        var iter = path_graph.iterator();
        while (iter.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            for (entry.value_ptr.*.items) |item| {
                allocator.free(item);
            }
            entry.value_ptr.deinit(allocator);
        }
        path_graph.deinit();
    }

    const total = try solve(allocator, path_graph);

    std.debug.print("\nTotal minimum button presses: {}\n", .{total});
}

fn parsePathGraph(allocator: std.mem.Allocator, reader: *std.Io.Reader) !std.StringHashMap(std.ArrayList([]const u8)) {
    var map: std.StringHashMap(std.ArrayList([]const u8)) = .init(allocator);
    while (try reader.takeDelimiter('\n')) |line| {
        var iter = std.mem.tokenizeScalar(u8, line, ' ');
        const first = iter.next().?[0..3];
        var subs: std.ArrayList([]const u8) = try .initCapacity(allocator, 16);
        while (iter.next()) |label| {
            try subs.append(allocator, try allocator.dupe(u8, label));
        }
        try map.putNoClobber(try allocator.dupe(u8, first), subs);
    }
    return map;
}

fn solve(allocator: std.mem.Allocator, path_graph: std.StringHashMap(std.ArrayList([]const u8))) !usize {
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
        memory.clearRetainingCapacity();

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
