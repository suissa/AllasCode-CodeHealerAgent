const std = @import("std");
const Thread = std.Thread;
const Mutex = std.Thread.Mutex;

pub const ThreadSafeCounter = struct {
    _count: i64,
    _lock: Mutex,
    _active_threads: i32,
    _increment_history: std.ArrayList(IncrementRecord),

    pub const IncrementRecord = struct {
        thread_id: u64,
        old_value: i64,
        new_value: i64,
    };

    pub fn init() ThreadSafeCounter {
        return ThreadSafeCounter{
            ._count = 0,
            ._lock = Mutex{},
            ._active_threads = 0,
            ._increment_history = std.ArrayList(IncrementRecord).init(std.heap.page_allocator),
        };
    }

    pub fn deinit(self: *ThreadSafeCounter) void {
        self._increment_history.deinit();
    }

    pub fn increment(self: *ThreadSafeCounter) void {
        // Simulate varying work loads (commented out for tests - can be enabled if needed)
        // std.time.sleep(std.time.ns_per_ms * 1);

        self._lock.lock();
        self._active_threads += 1;
        const last_value = self._count;
        self._lock.unlock();

        // Simulate varying work loads
        // std.time.sleep(std.time.ns_per_ms * 1);

        const local_value = last_value;
        const new_value = local_value + 1;

        self._lock.lock();
        // Only update if no other thread has modified the value
        if (self._count == local_value) {
            self._count = new_value;
            // Use a simple counter for thread identification in tests
            const thread_id: u64 = @intCast(self._active_threads);
            self._increment_history.append(IncrementRecord{
                .thread_id = thread_id,
                .old_value = local_value,
                .new_value = new_value,
            }) catch {};
        }
        self._active_threads -= 1;
        self._lock.unlock();
    }

    pub fn get_count(self: *ThreadSafeCounter) i64 {
        self._lock.lock();
        defer self._lock.unlock();
        return self._count;
    }

    pub fn get_active_threads(self: *ThreadSafeCounter) i32 {
        self._lock.lock();
        defer self._lock.unlock();
        return self._active_threads;
    }

    pub fn get_increment_history(self: *ThreadSafeCounter) []const IncrementRecord {
        self._lock.lock();
        defer self._lock.unlock();
        return self._increment_history.items;
    }
};

pub fn increment_counter(counter: *ThreadSafeCounter, num_increments: usize) void {
    var i: usize = 0;
    while (i < num_increments) : (i += 1) {
        counter.increment();
    }
}
