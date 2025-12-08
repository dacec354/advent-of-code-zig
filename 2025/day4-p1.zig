const std = @import("std");

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

    // init buffer
    var buffer = Buffer{};
    for (0..2) |_| {
        const line = try reader.takeDelimiter('\n') orelse @panic("Insuffcient input");
        buffer.addLine(line);
    }

    // handle buffer starts
    for (0..Buffer.MAX_COL) |col| {
        if (buffer.window[buffer.curr][col] != '@') continue;

        const rolls_count = buffer.findRolls(col, .start);
        if (rolls_count < 4) {
            sum += 1;
        }
    }

    // handle buffer full
    while (try reader.takeDelimiter('\n')) |line| {
        buffer.addLine(line);

        for (0..Buffer.MAX_COL) |col| {
            if (buffer.window[buffer.curr][col] != '@') continue;

            const rolls_count = buffer.findRolls(col, .mid);
            if (rolls_count < 4) {
                sum += 1;
            }
        }
    }

    // handle buffer ends
    buffer.removeLast();
    for (0..Buffer.MAX_COL) |col| {
        if (buffer.window[buffer.curr][col] != '@') continue;

        const rolls_count = buffer.findRolls(col, .end);
        if (rolls_count < 4) {
            sum += 1;
        }
    }

    try stdout.print("{d}\n", .{sum});
    try stdout.flush();
}

const Buffer = struct {
    const MAX_COL = 136;
    window: [3][MAX_COL]u8 = undefined,

    prev: u2 = 0,
    curr: u2 = 1,
    next: u2 = 2,

    fn rotate_ptr(this: *@This()) void {
        // rotate curr -> prev -> next -> curr
        const temp = this.curr;
        this.curr = this.next;
        this.next = this.prev;
        this.prev = temp;
    }

    fn addLine(this: *@This(), line: []const u8) void {
        std.debug.assert(line.len == MAX_COL);
        @memcpy(&this.window[this.prev], line);
        rotate_ptr(this);
    }

    fn removeLast(this: *@This()) void {
        rotate_ptr(this);
    }

    fn findRolls(this: *const @This(), col: usize, pos: enum { start, mid, end }) u4 {
        std.debug.assert(col >= 0 and col < MAX_COL);

        var sum: u4 = 0;
        switch (pos) {
            .start => switch (col) {
                0 => {
                    if (this.window[this.curr][1] == '@') sum += 1;
                    if (this.window[this.next][0] == '@') sum += 1;
                    if (this.window[this.next][1] == '@') sum += 1;
                },
                MAX_COL - 1 => {
                    if (this.window[this.curr][MAX_COL - 2] == '@') sum += 1;
                    if (this.window[this.next][MAX_COL - 2] == '@') sum += 1;
                    if (this.window[this.next][MAX_COL - 1] == '@') sum += 1;
                },
                else => {
                    if (this.window[this.curr][col - 1] == '@') sum += 1;
                    if (this.window[this.curr][col + 1] == '@') sum += 1;
                    for (this.window[this.next][col - 1 .. col + 2]) |item| {
                        if (item == '@') sum += 1;
                    }
                },
            },
            .mid => switch (col) {
                0 => {
                    if (this.window[this.prev][0] == '@') sum += 1;
                    if (this.window[this.prev][1] == '@') sum += 1;
                    if (this.window[this.curr][1] == '@') sum += 1;
                    if (this.window[this.next][0] == '@') sum += 1;
                    if (this.window[this.next][1] == '@') sum += 1;
                },
                MAX_COL - 1 => {
                    if (this.window[this.prev][MAX_COL - 2] == '@') sum += 1;
                    if (this.window[this.prev][MAX_COL - 1] == '@') sum += 1;
                    if (this.window[this.curr][MAX_COL - 2] == '@') sum += 1;
                    if (this.window[this.next][MAX_COL - 2] == '@') sum += 1;
                    if (this.window[this.next][MAX_COL - 1] == '@') sum += 1;
                },
                else => {
                    for (this.window[this.prev][col - 1 .. col + 2]) |item| {
                        if (item == '@') sum += 1;
                    }
                    if (this.window[this.curr][col - 1] == '@') sum += 1;
                    if (this.window[this.curr][col + 1] == '@') sum += 1;
                    for (this.window[this.next][col - 1 .. col + 2]) |item| {
                        if (item == '@') sum += 1;
                    }
                },
            },
            .end => switch (col) {
                0 => {
                    if (this.window[this.prev][0] == '@') sum += 1;
                    if (this.window[this.prev][1] == '@') sum += 1;
                    if (this.window[this.curr][1] == '@') sum += 1;
                },
                MAX_COL - 1 => {
                    if (this.window[this.prev][MAX_COL - 2] == '@') sum += 1;
                    if (this.window[this.prev][MAX_COL - 1] == '@') sum += 1;
                    if (this.window[this.curr][MAX_COL - 2] == '@') sum += 1;
                },
                else => {
                    for (this.window[this.prev][col - 1 .. col + 2]) |item| {
                        if (item == '@') sum += 1;
                    }
                    if (this.window[this.curr][col - 1] == '@') sum += 1;
                    if (this.window[this.curr][col + 1] == '@') sum += 1;
                },
            },
        }

        return sum;
    }
};
