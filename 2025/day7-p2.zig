const std = @import("std");

// stdout
var stdout_buffer: [64]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

// width
var MAX_COL: usize = 0;

pub fn main() !void {
    // file reader
    const input_file = try std.fs.cwd().openFile("./input/day7.txt", .{});
    defer input_file.close();
    var file_buffer: [4096]u8 = undefined;
    var file_reader = input_file.reader(&file_buffer);
    const reader = &file_reader.interface;

    // allocator
    const allocator = std.heap.smp_allocator;

    // answer
    var sum: u64 = 0;

    var board_arr = try std.ArrayList([]usize).initCapacity(allocator, 16);

    // inputs
    while (try reader.takeDelimiter('\n')) |line| {
        MAX_COL = @max(MAX_COL, line.len);
        var splitters = try std.ArrayList(usize).initCapacity(allocator, 16);
        for (line, 0..) |c, i| {
            switch (c) {
                'S', '^' => try splitters.append(allocator, i),
                else => {},
            }
        }
        if (splitters.items.len == 0) splitters.deinit(allocator) else try board_arr.append(allocator, try splitters.toOwnedSlice(allocator));
    }

    // layers of splitters
    const board = try board_arr.toOwnedSlice(allocator);
    defer {
        for (board) |line| {
            allocator.free(line);
        }
        allocator.free(board);
    }

    // beams
    const beam_pos = board[0][0];
    var memory = std.AutoHashMap(Key, usize).init(allocator);
    defer memory.deinit();

    sum = try beamHitBoard(&memory, board, 1, beam_pos);

    try stdout.print("{d}\n", .{sum});
    try stdout.flush();
}

const Key = struct { row_start: usize, col: usize };

// returns the posibilities
fn beamHitBoard(memo: *std.AutoHashMap(Key, usize), board: []const []const usize, row_start: usize, beam_pos: usize) !usize {
    if (memo.get(.{
        .row_start = row_start,
        .col = beam_pos,
    })) |v| return v;

    if (board.len == row_start) return 1;

    for (board[row_start..], row_start..) |splitters, index| {
        // if hit;
        if (std.mem.indexOfScalar(usize, splitters, beam_pos) != null) {
            const left = if (beam_pos > 0) try beamHitBoard(memo, board, index + 1, beam_pos - 1) else 0;
            const right = if (beam_pos < MAX_COL - 1) try beamHitBoard(memo, board, index + 1, beam_pos + 1) else 0;

            try memo.put(.{ .row_start = row_start, .col = beam_pos }, left + right);
            return left + right;
        }
    }
    return 1;
}
