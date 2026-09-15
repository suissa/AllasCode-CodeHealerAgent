const std = @import("std");
const ShoppingCart = @import("shopping_cart.zig").ShoppingCart;

test "shopping cart basic operations" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var cart = ShoppingCart.init(allocator);

    // Add items
    try cart.add_item("apple", 1.0, 2); // 2 apples at $1 each
    try cart.add_item("banana", 0.5, 3); // 3 bananas at $0.5 each
    try cart.add_item("orange", 0.75, 5); // 5 oranges at $0.75

    // Check initial total: 2*1.0 + 3*0.5 + 5*0.75 = 2.0 + 1.5 + 3.75 = 7.25
    try std.testing.expectEqual(@as(f64, 7.25), cart.get_total());

    // Apply discounts
    try cart.apply_discount("apple", 20.0); // 20% discount on apples
    try cart.apply_discount("orange", 10.0); // 10% discount on oranges

    // Add more items
    try cart.add_item("apple", 1.0, 3); // Add 3 more apples
    try cart.add_item("orange", 0.75, 2); // Add 2 more oranges

    // Expected total calculation:
    // Initial: 7.25
    // Apple discount: -2.0 * 0.20 = -0.40 -> 6.85
    // Orange discount: -3.75 * 0.10 = -0.375 -> 6.475
    // Add 3 apples: +3.0 -> 9.475
    // Add 2 oranges: +1.5 -> 10.975
    // Rounded: 10.98
    const expected_total = 10.98;
    const actual_total = cart.get_total();
    
    // Allow for small floating point differences
    const diff = if (actual_total > expected_total) actual_total - expected_total else expected_total - actual_total;
    try std.testing.expect(diff < 0.01);
}

test "shopping cart empty cart" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var cart = ShoppingCart.init(allocator);
    try std.testing.expectEqual(@as(f64, 0.0), cart.get_total());
}

test "shopping cart single item" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var cart = ShoppingCart.init(allocator);
    try cart.add_item("widget", 9.99, 1);
    try std.testing.expectEqual(@as(f64, 9.99), cart.get_total());
}

test "shopping cart multiple same items" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var cart = ShoppingCart.init(allocator);
    try cart.add_item("book", 15.0, 1);
    try cart.add_item("book", 15.0, 2);
    try cart.add_item("book", 15.0, 1);
    // Total: 4 books at $15 = $60
    try std.testing.expectEqual(@as(f64, 60.0), cart.get_total());
}

test "shopping cart discount on non-existent item" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var cart = ShoppingCart.init(allocator);
    try cart.add_item("item1", 10.0, 1);
    try cart.apply_discount("nonexistent", 50.0); // Should not affect total
    try std.testing.expectEqual(@as(f64, 10.0), cart.get_total());
}

test "shopping cart 100% discount" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var cart = ShoppingCart.init(allocator);
    try cart.add_item("free_item", 25.0, 2);
    try cart.apply_discount("free_item", 100.0);
    try std.testing.expectEqual(@as(f64, 0.0), cart.get_total());
}
