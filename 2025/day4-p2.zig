const std = @import("std");

const MAX_COL: usize = 136;
const MAX_ROW: usize = 136;

pub fn main() !void {
    // file reader
    const input_file = try std.fs.cwd().openFile("./input/day4.txt", .{});
    defer input_file.close();
    var file_buffer: [256]u8 = undefined;
    var file_reader = input_file.reader(&file_buffer);
    const reader = &file_reader.interface;

    // stdout
    var stdout_buffer: [16]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // answer
    var sum: u64 = 0;

    // rolls map
    var rolls: [MAX_ROW][MAX_COL]u8 = undefined;
    var i: usize = 0;
    while (try reader.takeDelimiter('\n')) |line| : (i += 1) {
        @memcpy(&rolls[i], line);
    }

    // mines map
    var mines: [MAX_ROW][MAX_COL]u8 = undefined;
    initMineMap(&rolls, &mines);

    var clear_count = shrinkMineMap(&mines);
    while (clear_count != 0) : (clear_count = shrinkMineMap(&mines)) {
        sum += clear_count;
    }

    try stdout.print("{d}\n", .{sum});
    try stdout.flush();
}

const Position = enum {
    start,
    mid,
    end,
};

fn initMineMap(rolls: *[MAX_COL][MAX_COL]u8, target: *[MAX_COL][MAX_COL]u8) void {
    for (rolls, 0..) |row, i| {
        for (row, 0..) |item, j| {
            target[i][j] = if (item != '@')
                255
            else
                findRolls(rolls, i, j, if (i == 0)
                    .start
                else if (i == rolls.len - 1)
                    .end
                else
                    .mid);
        }
    }
}

fn shrinkMineMap(mines: *[MAX_ROW][MAX_COL]u8) u64 {
    var count: usize = 0;
    for (mines, 0..) |row, i| {
        for (row, 0..) |item, j| {
            if (item != 255) if (sweepMine(mines, i, j)) {
                count += 1;
            };
        }
    }
    return count;
}

/// try sweep mine in (row_num, col_num)
fn sweepMine(mines: *[MAX_ROW][MAX_COL]u8, row_num: usize, col_num: usize) bool {
    if (mines[row_num][col_num] < 4) {
        const pos: Position = if (row_num == 0) .start else if (row_num == mines.len - 1) .end else .mid;
        switch (pos) {
            .start => switch (col_num) {
                0 => {
                    mines[row_num][col_num] = 255;

                    if (mines[row_num][1] != 255) mines[row_num][1] -= 1;
                    if (mines[row_num + 1][0] != 255) mines[row_num + 1][0] -= 1;
                    if (mines[row_num + 1][1] != 255) mines[row_num + 1][1] -= 1;
                },
                MAX_COL - 1 => {
                    mines[row_num][col_num] = 255;

                    if (mines[row_num][MAX_COL - 2] != 255) mines[row_num][MAX_COL - 2] -= 1;
                    if (mines[row_num + 1][MAX_COL - 2] != 255) mines[row_num + 1][MAX_COL - 2] -= 1;
                    if (mines[row_num + 1][MAX_COL - 1] != 255) mines[row_num + 1][MAX_COL - 1] -= 1;
                },
                else => {
                    mines[row_num][col_num] = 255;

                    if (mines[row_num][col_num - 1] != 255) mines[row_num][col_num - 1] -= 1;
                    if (mines[row_num][col_num + 1] != 255) mines[row_num][col_num + 1] -= 1;
                    for (mines[row_num + 1][col_num - 1 .. col_num + 2]) |*item| {
                        if (item.* != 255) item.* -= 1;
                    }
                },
            },
            .mid => switch (col_num) {
                0 => {
                    mines[row_num][col_num] = 255;

                    if (mines[row_num - 1][0] != 255) mines[row_num - 1][0] -= 1;
                    if (mines[row_num - 1][1] != 255) mines[row_num - 1][1] -= 1;
                    if (mines[row_num][1] != 255) mines[row_num][1] -= 1;
                    if (mines[row_num + 1][0] != 255) mines[row_num + 1][0] -= 1;
                    if (mines[row_num + 1][1] != 255) mines[row_num + 1][1] -= 1;
                },
                MAX_COL - 1 => {
                    mines[row_num][col_num] = 255;

                    if (mines[row_num - 1][MAX_COL - 2] != 255) mines[row_num - 1][MAX_COL - 2] -= 1;
                    if (mines[row_num - 1][MAX_COL - 1] != 255) mines[row_num - 1][MAX_COL - 1] -= 1;
                    if (mines[row_num][MAX_COL - 2] != 255) mines[row_num][MAX_COL - 2] -= 1;
                    if (mines[row_num + 1][MAX_COL - 2] != 255) mines[row_num + 1][MAX_COL - 2] -= 1;
                    if (mines[row_num + 1][MAX_COL - 1] != 255) mines[row_num + 1][MAX_COL - 1] -= 1;
                },
                else => {
                    mines[row_num][col_num] = 255;

                    // 上一行
                    for (mines[row_num - 1][col_num - 1 .. col_num + 2]) |*item| {
                        if (item.* != 255) item.* -= 1;
                    }
                    // 同一行左右
                    if (mines[row_num][col_num - 1] != 255) mines[row_num][col_num - 1] -= 1;
                    if (mines[row_num][col_num + 1] != 255) mines[row_num][col_num + 1] -= 1;
                    // 下一行
                    for (mines[row_num + 1][col_num - 1 .. col_num + 2]) |*item| {
                        if (item.* != 255) item.* -= 1;
                    }
                },
            },
            .end => switch (col_num) {
                0 => {
                    mines[row_num][col_num] = 255;

                    if (mines[row_num - 1][0] != 255) mines[row_num - 1][0] -= 1;
                    if (mines[row_num - 1][1] != 255) mines[row_num - 1][1] -= 1;
                    if (mines[row_num][1] != 255) mines[row_num][1] -= 1;
                },
                MAX_COL - 1 => {
                    mines[row_num][col_num] = 255;

                    if (mines[row_num - 1][MAX_COL - 2] != 255) mines[row_num - 1][MAX_COL - 2] -= 1;
                    if (mines[row_num - 1][MAX_COL - 1] != 255) mines[row_num - 1][MAX_COL - 1] -= 1;
                    if (mines[row_num][MAX_COL - 2] != 255) mines[row_num][MAX_COL - 2] -= 1;
                },
                else => {
                    mines[row_num][col_num] = 255;

                    for (mines[row_num - 1][col_num - 1 .. col_num + 2]) |*item| {
                        if (item.* != 255) item.* -= 1;
                    }

                    if (mines[row_num][col_num - 1] != 255) mines[row_num][col_num - 1] -= 1;
                    if (mines[row_num][col_num + 1] != 255) mines[row_num][col_num + 1] -= 1;
                },
            },
        }

        return true;
    }

    return false;
}

/// 255 means empty space
fn findRolls(rolls: *[MAX_ROW][MAX_COL]u8, row_num: usize, col_num: usize, pos: enum { start, mid, end }) u4 {
    std.debug.assert(col_num >= 0 and col_num < MAX_COL);
    std.debug.assert(row_num >= 0 and row_num < MAX_COL);

    var sum: u4 = 0;
    switch (pos) {
        .start => switch (col_num) {
            0 => {
                if (rolls[row_num][1] == '@') sum += 1;
                if (rolls[row_num + 1][0] == '@') sum += 1;
                if (rolls[row_num + 1][1] == '@') sum += 1;
            },
            MAX_COL - 1 => {
                if (rolls[row_num][MAX_COL - 2] == '@') sum += 1;
                if (rolls[row_num + 1][MAX_COL - 2] == '@') sum += 1;
                if (rolls[row_num + 1][MAX_COL - 1] == '@') sum += 1;
            },
            else => {
                if (rolls[row_num][col_num - 1] == '@') sum += 1;
                if (rolls[row_num][col_num + 1] == '@') sum += 1;
                for (rolls[row_num + 1][col_num - 1 .. col_num + 2]) |item| {
                    if (item == '@') sum += 1;
                }
            },
        },
        .mid => switch (col_num) {
            0 => {
                if (rolls[row_num - 1][0] == '@') sum += 1;
                if (rolls[row_num - 1][1] == '@') sum += 1;
                if (rolls[row_num][1] == '@') sum += 1;
                if (rolls[row_num + 1][0] == '@') sum += 1;
                if (rolls[row_num + 1][1] == '@') sum += 1;
            },
            MAX_COL - 1 => {
                if (rolls[row_num - 1][MAX_COL - 2] == '@') sum += 1;
                if (rolls[row_num - 1][MAX_COL - 1] == '@') sum += 1;
                if (rolls[row_num][MAX_COL - 2] == '@') sum += 1;
                if (rolls[row_num + 1][MAX_COL - 2] == '@') sum += 1;
                if (rolls[row_num + 1][MAX_COL - 1] == '@') sum += 1;
            },
            else => {
                for (rolls[row_num - 1][col_num - 1 .. col_num + 2]) |item| {
                    if (item == '@') sum += 1;
                }
                if (rolls[row_num][col_num - 1] == '@') sum += 1;
                if (rolls[row_num][col_num + 1] == '@') sum += 1;
                for (rolls[row_num + 1][col_num - 1 .. col_num + 2]) |item| {
                    if (item == '@') sum += 1;
                }
            },
        },
        .end => switch (col_num) {
            0 => {
                if (rolls[row_num - 1][0] == '@') sum += 1;
                if (rolls[row_num - 1][1] == '@') sum += 1;
                if (rolls[row_num][1] == '@') sum += 1;
            },
            MAX_COL - 1 => {
                if (rolls[row_num - 1][MAX_COL - 2] == '@') sum += 1;
                if (rolls[row_num - 1][MAX_COL - 1] == '@') sum += 1;
                if (rolls[row_num][MAX_COL - 2] == '@') sum += 1;
            },
            else => {
                for (rolls[row_num - 1][col_num - 1 .. col_num + 2]) |item| {
                    if (item == '@') sum += 1;
                }
                if (rolls[row_num][col_num - 1] == '@') sum += 1;
                if (rolls[row_num][col_num + 1] == '@') sum += 1;
            },
        },
    }

    return sum;
}
