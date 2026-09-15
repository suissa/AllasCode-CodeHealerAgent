const std = @import("std");

pub const EnvironmentTool = struct {
    name: []const u8,
    action: []const u8,
    instructions: Instructions,
    environment: ?*anyopaque = null,

    pub const Instructions = struct {
        template: []const u8,
        description: []const u8,
        examples: []const []const u8,
    };

    pub fn use(self: *EnvironmentTool, input_text: []const u8) ![]const u8 {
        _ = self;
        _ = input_text;
        return error.NotImplemented;
    }
};

pub const PlusTool = struct {
    base: EnvironmentTool,

    pub fn init() PlusTool {
        return PlusTool{
            .base = EnvironmentTool{
                .name = "plus",
                .action = "```plus",
                .instructions = EnvironmentTool.Instructions{
                    .template = "```plus <number1> <number2>```",
                    .description = "Adds two numbers together.",
                    .examples = &[_][]const u8{
                        "```plus 1 2``` will return 3.",
                        "```plus 3 4``` will return 7.",
                        "```plus -3 3``` will return 0.",
                    },
                },
            },
        };
    }

    pub const Result = union(enum) {
        value: i64,
        err: []const u8,
    };

    pub fn use(self: *PlusTool, input_text: []const u8) Result {
        _ = self;
        // Parse the input text
        const action_str = "```plus";
        
        // Find the action in the input
        const start_idx = std.mem.indexOf(u8, input_text, action_str) orelse return Result{ .err = "SyntaxError: invalid syntax." };
        
        // Extract the part after the action
        const after_action = input_text[start_idx + action_str.len..];
        
        // Find the closing ```
        const end_idx = std.mem.indexOf(u8, after_action, "```") orelse return Result{ .err = "SyntaxError: invalid syntax." };
        
        // Get the numbers part and trim whitespace
        const numbers_part = std.mem.trim(u8, after_action[0..end_idx], " \t\n\r");
        
        // Split by whitespace
        var iter = std.mem.tokenizeScalar(u8, numbers_part, ' ');
        
        const num1_str = iter.next() orelse return Result{ .err = "SyntaxError: invalid syntax." };
        const num2_str = iter.next() orelse return Result{ .err = "SyntaxError: invalid syntax." };
        
        // Check if there are extra numbers (more than 2)
        if (iter.next()) |_| {
            return Result{ .err = "SyntaxError: invalid syntax." };
        }
        
        // Parse the numbers
        const num1 = std.fmt.parseInt(i64, num1_str, 10) catch return Result{ .err = "ValueError: invalid value." };
        const num2 = std.fmt.parseInt(i64, num2_str, 10) catch return Result{ .err = "ValueError: invalid value." };
        
        // Calculate result
        const result = num1 + num2;
        
        return Result{ .value = result };
    }
};

// Helper function to format result as string
pub fn formatResult(allocator: std.mem.Allocator, result: i64) ![]const u8 {
    return std.fmt.allocPrint(allocator, "{d}", .{result});
}
