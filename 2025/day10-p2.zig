const std = @import("std");
const Allocator = std.mem.Allocator;

const MAX_COUNTERS = 16;
const MAX_BUTTONS = 16;

const Rational = struct {
    num: i64,
    den: i64,

    fn init(n: i64, d: i64) Rational {
        if (d == 0) return .{ .num = 0, .den = 1 };
        var g = gcd(if (n < 0) -n else n, if (d < 0) -d else d);
        if (g == 0) g = 1;
        var num = @divTrunc(n, g);
        var den = @divTrunc(d, g);
        if (den < 0) {
            num = -num;
            den = -den;
        }
        return .{ .num = num, .den = den };
    }

    fn fromInt(n: i64) Rational {
        return .{ .num = n, .den = 1 };
    }

    fn add(a: Rational, b: Rational) Rational {
        return init(a.num * b.den + b.num * a.den, a.den * b.den);
    }

    fn sub(a: Rational, b: Rational) Rational {
        return init(a.num * b.den - b.num * a.den, a.den * b.den);
    }

    fn mul(a: Rational, b: Rational) Rational {
        return init(a.num * b.num, a.den * b.den);
    }

    fn div(a: Rational, b: Rational) Rational {
        return init(a.num * b.den, a.den * b.num);
    }

    fn isZero(self: Rational) bool {
        return self.num == 0;
    }

    fn isInteger(self: Rational) bool {
        return @rem(self.num, self.den) == 0;
    }

    fn toInt(self: Rational) i64 {
        return @divTrunc(self.num, self.den);
    }

    fn gcd(a: i64, b: i64) i64 {
        var x = a;
        var y = b;
        while (y != 0) {
            const t = @rem(x, y);
            x = y;
            y = t;
        }
        return x;
    }
};

const Button = struct {
    affects: [MAX_COUNTERS]bool = [_]bool{false} ** MAX_COUNTERS,
};

const Machine = struct {
    num_counters: usize,
    targets: [MAX_COUNTERS]i64 = [_]i64{0} ** MAX_COUNTERS,
    buttons: [MAX_BUTTONS]Button = undefined,
    num_buttons: usize,
};

fn parseMachine(line: []const u8) !Machine {
    var machine = Machine{
        .num_counters = 0,
        .num_buttons = 0,
    };

    var i: usize = 0;

    // Skip the indicator lights [...]
    while (i < line.len and line[i] != ']') : (i += 1) {}
    i += 1;

    // Parse buttons and targets
    while (i < line.len) {
        while (i < line.len and line[i] == ' ') : (i += 1) {}
        if (i >= line.len) break;

        if (line[i] == '(') {
            i += 1;
            var button = Button{};
            while (i < line.len and line[i] != ')') {
                while (i < line.len and (line[i] == ' ' or line[i] == ',')) : (i += 1) {}
                if (i >= line.len or line[i] == ')') break;
                var num: usize = 0;
                while (i < line.len and line[i] >= '0' and line[i] <= '9') {
                    num = num * 10 + (line[i] - '0');
                    i += 1;
                }
                button.affects[num] = true;
            }
            i += 1;
            machine.buttons[machine.num_buttons] = button;
            machine.num_buttons += 1;
        } else if (line[i] == '{') {
            i += 1;
            var counter_idx: usize = 0;
            while (i < line.len and line[i] != '}') {
                while (i < line.len and (line[i] == ' ' or line[i] == ',')) : (i += 1) {}
                if (i >= line.len or line[i] == '}') break;
                var num: i64 = 0;
                while (i < line.len and line[i] >= '0' and line[i] <= '9') {
                    num = num * 10 + (line[i] - '0');
                    i += 1;
                }
                machine.targets[counter_idx] = num;
                counter_idx += 1;
            }
            machine.num_counters = counter_idx;
            break;
        } else {
            i += 1;
        }
    }
    return machine;
}

// 高斯消元求解
fn solve(machine: *const Machine) i64 {
    const n = machine.num_counters;
    const m = machine.num_buttons;

    if (m == 0) {
        for (0..n) |i| {
            if (machine.targets[i] != 0) return -1;
        }
        return 0;
    }

    // 构建增广矩阵 [A | b]，大小 n x (m+1)
    // A[row][col] 表示第 row 个计数器是否被第 col 个按钮影响
    var matrix: [MAX_COUNTERS][MAX_BUTTONS + 1]Rational = undefined;
    for (0..n) |row| {
        for (0..m) |col| {
            matrix[row][col] = if (machine.buttons[col].affects[row])
                Rational.fromInt(1)
            else
                Rational.fromInt(0);
        }
        matrix[row][m] = Rational.fromInt(machine.targets[row]);
    }

    // 高斯消元，化为行阶梯形
    var pivot_col: [MAX_COUNTERS]usize = undefined; // pivot_col[i] = 第 i 个主元所在的列
    var num_pivots: usize = 0;
    var col: usize = 0;

    for (0..n) |row| {
        // 找主元
        while (col < m) {
            // 找这一列中绝对值最大的行
            var max_row = row;
            for (row + 1..n) |r| {
                if (!matrix[r][col].isZero()) {
                    max_row = r;
                    break;
                }
            }

            if (!matrix[max_row][col].isZero()) {
                // 交换行
                if (max_row != row) {
                    for (0..m + 1) |c| {
                        const tmp = matrix[row][c];
                        matrix[row][c] = matrix[max_row][c];
                        matrix[max_row][c] = tmp;
                    }
                }

                // 消元
                const pivot = matrix[row][col];
                for (0..n) |r| {
                    if (r != row and !matrix[r][col].isZero()) {
                        const factor = matrix[r][col].div(pivot);
                        for (col..m + 1) |c| {
                            matrix[r][c] = matrix[r][c].sub(factor.mul(matrix[row][c]));
                        }
                    }
                }

                // 归一化主元行
                for (col..m + 1) |c| {
                    matrix[row][c] = matrix[row][c].div(pivot);
                }

                pivot_col[num_pivots] = col;
                num_pivots += 1;
                col += 1;
                break;
            }
            col += 1;
        }
        if (col >= m) break;
    }

    // 检查是否有解（如果有 0 = nonzero 的行，无解）
    for (num_pivots..n) |row| {
        if (!matrix[row][m].isZero()) {
            return -1; // 无解
        }
    }

    // 确定自由变量
    var is_pivot: [MAX_BUTTONS]bool = [_]bool{false} ** MAX_BUTTONS;
    for (0..num_pivots) |i| {
        is_pivot[pivot_col[i]] = true;
    }

    var free_vars: [MAX_BUTTONS]usize = undefined;
    var num_free: usize = 0;
    for (0..m) |c| {
        if (!is_pivot[c]) {
            free_vars[num_free] = c;
            num_free += 1;
        }
    }

    // 如果没有自由变量，直接检查解
    if (num_free == 0) {
        var total: i64 = 0;
        for (0..num_pivots) |i| {
            const val = matrix[i][m];
            if (!val.isInteger() or val.toInt() < 0) {
                return -1;
            }
            total += val.toInt();
        }
        return total;
    }

    // 有自由变量，需要枚举
    // 计算每个自由变量的合理范围
    var free_max: [MAX_BUTTONS]i64 = undefined;
    for (0..num_free) |fi| {
        const fc = free_vars[fi];
        // 这个自由变量最多能取多少？受限于它影响的计数器的目标值
        var max_val: i64 = std.math.maxInt(i64);
        for (0..n) |row| {
            if (machine.buttons[fc].affects[row]) {
                if (machine.targets[row] < max_val) {
                    max_val = machine.targets[row];
                }
            }
        }
        free_max[fi] = max_val;
    }

    // 枚举自由变量的值，找最小总和
    var best: i64 = std.math.maxInt(i64);
    var free_vals: [MAX_BUTTONS]i64 = [_]i64{0} ** MAX_BUTTONS;

    searchFreeVars(machine, &matrix, num_pivots, &pivot_col, &free_vars, num_free, &free_max, &free_vals, 0, &best);

    if (best == std.math.maxInt(i64)) return -1;
    return best;
}

fn searchFreeVars(
    machine: *const Machine,
    matrix: *[MAX_COUNTERS][MAX_BUTTONS + 1]Rational,
    num_pivots: usize,
    pivot_col: *[MAX_COUNTERS]usize,
    free_vars: *[MAX_BUTTONS]usize,
    num_free: usize,
    free_max: *[MAX_BUTTONS]i64,
    free_vals: *[MAX_BUTTONS]i64,
    fi: usize,
    best: *i64,
) void {
    const m = machine.num_buttons;

    if (fi == num_free) {
        // 计算所有变量的值
        var x: [MAX_BUTTONS]Rational = undefined;
        for (0..m) |c| {
            x[c] = Rational.fromInt(0);
        }

        // 设置自由变量
        for (0..num_free) |i| {
            x[free_vars[i]] = Rational.fromInt(free_vals[i]);
        }

        // 计算主元变量: x[pivot_col[i]] = matrix[i][m] - sum(matrix[i][j] * x[j]) for free j
        for (0..num_pivots) |i| {
            var val = matrix[i][m];
            for (0..num_free) |fj| {
                const fc = free_vars[fj];
                val = val.sub(matrix[i][fc].mul(x[fc]));
            }
            x[pivot_col[i]] = val;
        }

        // 检查所有变量是否为非负整数
        var total: i64 = 0;
        for (0..m) |c| {
            if (!x[c].isInteger()) return;
            const v = x[c].toInt();
            if (v < 0) return;
            total += v;
        }

        if (total < best.*) {
            best.* = total;
        }
        return;
    }

    // 枚举当前自由变量的值
    var val: i64 = 0;
    while (val <= free_max[fi]) : (val += 1) {
        free_vals[fi] = val;
        searchFreeVars(machine, matrix, num_pivots, pivot_col, free_vars, num_free, free_max, free_vals, fi + 1, best);
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: joltage <input_file>\n", .{});
        return;
    }

    const file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    var total: i64 = 0;
    var lines = std.mem.splitScalar(u8, content, '\n');

    var count: usize = 0;
    while (lines.next()) |line| : (count += 1) {
        const trimmed = std.mem.trim(u8, line, &[_]u8{ ' ', '\r', '\t' });
        if (trimmed.len == 0) continue;
        if (trimmed[0] != '[') continue;

        const machine = try parseMachine(trimmed);
        const min_presses = solve(&machine);

        std.debug.print("Machine{d:4}: min presses = {}\n", .{ count, min_presses });
        if (min_presses >= 0) {
            total += min_presses;
        }
    }

    std.debug.print("\nTotal minimum button presses: {}\n", .{total});
}
