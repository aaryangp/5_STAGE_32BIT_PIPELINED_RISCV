module hazard_detection_unit(
    input        IDEX_MemRead,   // instruction currently in EX is a load
    input [4:0]  IDEX_rd,        // that load's destination register

    input [4:0]  IFID_rs1,       // source registers of the instruction
    input [4:0]  IFID_rs2,       // currently in ID (right behind the load)

    output stall                 // 1 = load-use hazard: freeze PC & IF/ID, bubble ID/EX
);

// Classic load-use hazard: the instruction right behind a load needs, as one of
// its own source registers, the exact register that load is about to write.
// At this point the loaded value doesn't exist anywhere forwarding can reach
// (EX/MEM only has the load's *address*, not its data) -- see EX_MEM_reg -- so
// the only fix is to hold this instruction in ID for one extra cycle, giving the
// load time to reach MEM/WB, where the forwarding unit can pick it up normally.
assign stall = IDEX_MemRead &&
               (IDEX_rd != 5'b0) &&
               ((IDEX_rd == IFID_rs1) || (IDEX_rd == IFID_rs2));

endmodule