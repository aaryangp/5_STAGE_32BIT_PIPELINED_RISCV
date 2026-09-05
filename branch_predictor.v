module branch_predictor(
    input [6:0] opcode,   // opcode of the instruction currently being decoded (ID stage).
                          // Not used by this policy -- kept as an input so a smarter
                          // predictor (BTFNT using the immediate's sign bit, or a real
                          // dynamic 1-/2-bit saturating counter table indexed by PC) can
                          // be dropped in later without changing anything in top.v.

    output predicted_taken
);

// Static "predict not-taken": always guess a branch will NOT be taken.
// This is why IF doesn't need any new hardware to act on it -- PC_MUX already
// defaults to pc_plus4_top (sequential fetch) unless something overrides it,
// which IS this prediction, structurally, for free.
//
// To upgrade later:
//   BTFNT (backward-taken/forward-not-taken): predicted_taken = is_branch && imm_sign_bit
//     (needs the branch's immediate sign, e.g. from IFID_Instruction[31], wired in as
//      another input -- backward branches, usually loop back-edges, guess taken).
//   Dynamic (1-bit/2-bit saturating counter): predicted_taken = a per-PC table lookup,
//     updated in MEM once the real outcome is known -- needs a small table + update port.
assign predicted_taken = 1'b0;

endmodule