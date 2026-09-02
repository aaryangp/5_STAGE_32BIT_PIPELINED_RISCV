module forwarding_unit(
    input  [4:0] IDEX_rs1,
    input  [4:0] IDEX_rs2,

    input  [4:0] EXMEM_rd,
    input        EXMEM_RegWrite,

    input  [4:0] MEMWB_rd,
    input        MEMWB_RegWrite,

    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB
);

// Encoding (matches the 3:1 mux in the EX stage):
//   00 -> no forwarding, use ID/EX register-file value
//   10 -> forward from EX/MEM (the instruction one ahead, in MEM this cycle)
//   01 -> forward from MEM/WB (the instruction two ahead, in WB this cycle)
//
// EX/MEM is checked first: it holds the *newer* result, so it must win
// if both EX/MEM and MEM/WB target the same register (double hazard).

always @(*) begin
    // ---- ForwardA : source for rs1 ----
    if (EXMEM_RegWrite && (EXMEM_rd != 5'b0) && (EXMEM_rd == IDEX_rs1))
        ForwardA = 2'b10;
    else if (MEMWB_RegWrite && (MEMWB_rd != 5'b0) && (MEMWB_rd == IDEX_rs1))
        ForwardA = 2'b01;
    else
        ForwardA = 2'b00;

    // ---- ForwardB : source for rs2 ----
    if (EXMEM_RegWrite && (EXMEM_rd != 5'b0) && (EXMEM_rd == IDEX_rs2))
        ForwardB = 2'b10;
    else if (MEMWB_RegWrite && (MEMWB_rd != 5'b0) && (MEMWB_rd == IDEX_rs2))
        ForwardB = 2'b01;
    else
        ForwardB = 2'b00;
end

endmodule