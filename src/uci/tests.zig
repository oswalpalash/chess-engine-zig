const std = @import("std");
const b = @import("../board.zig");
const c = @import("../consts.zig");
const m = @import("../moves.zig");
const UciCommand = @import("command.zig").UciCommand;
const UciProtocol = @import("protocol.zig").UciProtocol;
const moveToUci = @import("helpers.zig").moveToUci;
const bitboardToSquare = @import("helpers.zig").bitboardToSquare;

// All tests from uci.zig go here, with imports updated as above.
// ... (copy all test blocks from uci.zig here, except main) ... 