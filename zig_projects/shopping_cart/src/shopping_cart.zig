const std = @import("std");
const Allocator = std.mem.Allocator;
const StringHashMap = std.StringHashMap;

pub const ShoppingCart = struct {
    allocator: Allocator,
    items: StringHashMap(u32),
    item_prices: StringHashMap(f64),
    discounts: StringHashMap(f64),
    total: f64,

    pub fn init(allocator: Allocator) ShoppingCart {
        return ShoppingCart{
            .allocator = allocator,
            .items = StringHashMap(u32).init(allocator),
            .item_prices = StringHashMap(f64).init(allocator),
            .discounts = StringHashMap(f64).init(allocator),
            .total = 0.0,
        };
    }

    pub fn deinit(self: *ShoppingCart) void {
        // Free all keys (strings) before deinitializing the hashmaps
        var it = self.items.keyIterator();
        while (it.next()) |key| {
            self.allocator.free(key.*);
        }
        self.items.deinit();
        
        it = self.item_prices.keyIterator();
        while (it.next()) |key| {
            self.allocator.free(key.*);
        }
        self.item_prices.deinit();
        
        it = self.discounts.keyIterator();
        while (it.next()) |key| {
            self.allocator.free(key.*);
        }
        self.discounts.deinit();
    }

    pub fn add_item(self: *ShoppingCart, item: []const u8, price: f64, quantity: u32) !void {
        const item_key = try self.allocator.dupe(u8, item);
        errdefer self.allocator.free(item_key);

        if (self.items.get(item)) |existing_qty| {
            // Item already exists, update quantity
            try self.items.put(item, existing_qty + quantity);
        } else {
            // New item, add to items and item_prices
            try self.items.put(item_key, quantity);
            try self.item_prices.put(item_key, price);
        }

        self.total += price * @as(f64, @floatFromInt(quantity));
    }

    pub fn apply_discount(self: *ShoppingCart, item: []const u8, discount_percentage: f64) !void {
        const item_key = try self.allocator.dupe(u8, item);
        errdefer self.allocator.free(item_key);

        // Store the discount
        if (self.discounts.get(item)) |_| {
            // Discount already exists, update it
            try self.discounts.put(item, discount_percentage);
        } else {
            try self.discounts.put(item_key, discount_percentage);
        }

        // Apply discount to total if item exists
        if (self.items.get(item)) |qty| {
            const price = self.item_prices.get(item).?;
            self.total -= price * @as(f64, @floatFromInt(qty)) * discount_percentage / 100.0;
        }
    }

    pub fn get_total(self: *ShoppingCart) f64 {
        // Round to 2 decimal places
        return @floor(self.total * 100.0 + 0.5) / 100.0;
    }
};
