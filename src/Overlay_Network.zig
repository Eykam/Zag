const std = @import("std");
const L2 = @import("L2");
const L3 = @import("L3");

const Allocator = std.mem.Allocator;
const Router = L3.Router_Handler.Router;
const Interface = L2.Interface_Handler.Interface;
const Frame = L2.Frame_Handler.Eth_Frame;

const Network = struct {
    interfaces: std.ArrayList(Interface),
    router: Router,
    allocator: Allocator,

    pub fn init(allocator: Allocator) Network {
        return Network{
            .interfaces = std.ArrayList(Interface).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Network) void {
        for (self.interfaces.items) |*iface| {
            iface.deinit();
        }
        self.interfaces.deinit();
    }

    // TODO: Implement LLCD or some broadcasting protocol to let others on network know
    // Also spawn reading of interface in new thread
    pub fn add_interface(self: *Network) !void {
        const iface = try Interface.init(self.allocator);
        try self.interfaces.append(iface);
    }

    pub fn add_router(self: *Network) !void {
        _ = self;
    }
};

// pub fn main() !void {
//     std.debug.print("Creating Virtual network...\n", .{});
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     defer _ = gpa.deinit();
//     const allocator = gpa.allocator();

//     var network = Network.init(allocator);
//     defer network.deinit();

//     try network.addInterface("eth0", .{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55 }, .{ 192, 168, 1, 1 });
//     try network.addInterface("eth1", .{ 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB }, .{ 192, 168, 2, 1 });
//     std.debug.print("Creating Virtual Interfaces:\n\n", .{});

//     std.debug.print("eth0: ", .{});
//     inline for (network.interfaces.items[0].mac, 0..) |byte, ind| {
//         const last = if (ind < network.interfaces.items[0].mac.len - 1) ":" else "";
//         std.debug.print("{x:0>2}{s}", .{ byte, last });
//     }

//     std.debug.print("\neth1: ", .{});
//     inline for (network.interfaces.items[1].mac, 0..) |byte, ind| {
//         const last = if (ind < network.interfaces.items[1].mac.len - 1) ":" else "";
//         std.debug.print("{x:0>2}{s}", .{ byte, last });
//     }
//     std.debug.print("\n\n", .{});

//     // Simulate sending a packet
//     _ = [_]u8{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0x08, 0x00 };
//     _ = [_]u8{ 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99 };
// }
