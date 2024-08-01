const std = @import("std");
const assert = std.debug.assert;

/// An intrusive first in/first out linked list.
/// The element type T must have a field called "next" of type ?*T
pub fn FIFO(comptime T: type) type {
    return struct {
        const Self = @This();

        in: ?*T = null,
        out: ?*T = null,

        pub fn push(self: *Self, elem: *T) void {
            assert(elem.next == null);

            if (self.in) |in| {
                in.next = elem;
                self.in = elem;
            } else {
                assert(self.out == null);

                self.in = elem;
                self.out = elem;
            }
        }

        pub fn pop(self: *Self) ?*T {
            const popped = self.out orelse return null;
            self.out = popped.next;
            popped.next = null;

            if (self.in == self.out) {
                self.in = null;
            }

            return popped;
        }

        pub fn peek(self: Self) ?*T {
            return self.out;
        }

        pub fn empty(self: Self) bool {
            return self.peek() == null;
        }

        /// Remove an element from the FIFO. Asserts that the element is
        /// in the FIFO. This operation is O(N), if this is done often you
        /// probably want a different data structure.
        pub fn remove(self: *Self, to_remove: *T) void {
            if (to_remove == self.out) {
                _ = self.pop();
                return;
            }
            var item = self.out;

            while (item) |elem| : (item = elem.next) {
                if (to_remove == elem.next) {
                    if (self.in == to_remove) {
                        self.in = elem;
                    }

                    elem.next = to_remove.next;
                    to_remove.next = null;
                    break;
                }
            } else {
                unreachable;
            }
        }
    };
}

test "push/pop/peek/remove/empty" {
    const testing = @import("std").testing;

    const Foo = struct { next: ?*@This() = null };

    var one: Foo = .{};
    var two: Foo = .{};
    var three: Foo = .{};

    var fifo: FIFO(Foo) = .{};
    try testing.expect(fifo.empty());

    fifo.push(&one);
    try testing.expect(!fifo.empty());
    try testing.expectEqual(@as(?*Foo, &one), fifo.peek());

    fifo.push(&two);
    fifo.push(&three);
    try testing.expect(!fifo.empty());
    try testing.expectEqual(@as(?*Foo, &one), fifo.peek());

    fifo.remove(&one);
    try testing.expect(!fifo.empty());
    try testing.expectEqual(@as(?*Foo, &two), fifo.pop());
    try testing.expectEqual(@as(?*Foo, &three), fifo.pop());
    try testing.expectEqual(@as(?*Foo, null), fifo.pop());
    try testing.expect(fifo.empty());

    fifo.push(&one);
    fifo.push(&two);
    fifo.push(&three);
    fifo.remove(&two);
    try testing.expect(!fifo.empty());
    try testing.expectEqual(@as(?*Foo, &one), fifo.pop());
    try testing.expectEqual(@as(?*Foo, &three), fifo.pop());
    try testing.expectEqual(@as(?*Foo, null), fifo.pop());
    try testing.expect(fifo.empty());

    fifo.push(&one);
    fifo.push(&two);
    fifo.push(&three);
    fifo.remove(&three);
    try testing.expect(!fifo.empty());
    try testing.expectEqual(@as(?*Foo, &one), fifo.pop());
    try testing.expect(!fifo.empty());
    try testing.expectEqual(@as(?*Foo, &two), fifo.pop());
    try testing.expect(fifo.empty());
    try testing.expectEqual(@as(?*Foo, null), fifo.pop());
    try testing.expect(fifo.empty());

    fifo.push(&one);
    fifo.push(&two);
    fifo.remove(&two);
    fifo.push(&three);
    try testing.expectEqual(@as(?*Foo, &one), fifo.pop());
    try testing.expectEqual(@as(?*Foo, &three), fifo.pop());
    try testing.expectEqual(@as(?*Foo, null), fifo.pop());
    try testing.expect(fifo.empty());
}
