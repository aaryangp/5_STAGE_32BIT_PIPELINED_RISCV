module ID_EX_reg(
    input clk,
    input rst,
    input flush,    // insert a bubble (load-use stall): force this stage to a NOP

    // ---------------- WB control ----------------
    input RegWrite_in,
    input [1:0] MemtoReg_in,

    // ---------------- M control ------------------
    input Branch_in,
    input Jump_in,   // JAL/JALR: unconditionally taken
    input Jalr_in,   // JALR specifically: target = rs1+imm, not PC+imm
    input MemRead_in,
    input MemWrite_in,

    // ---------------- EX control -----------------
    input [1:0] ALUOp_in,
    input ALUSrc_in,

    // ---------------- datapath -------------------
    input [31:0] PC_in,
    input [31:0] ReadData1_in,
    input [31:0] ReadData2_in,
    input [31:0] ImmExt_in,
    input [31:0] Instruction_in,   // full instruction, carried for debug/waveform viewing

    input [4:0]  rs1_in,           // carried now so a future forwarding/hazard unit can use it
    input [4:0]  rs2_in,           // (unused by the datapath itself for now)
    input [4:0]  rd_in,
    input        funct7_in,
    input [2:0]  funct3_in,
    input        predicted_taken_in,  // carried through so MEM can check it against the real outcome

    // ---------------- outputs --------------------
    output reg RegWrite_out,
    output reg [1:0] MemtoReg_out,

    output reg Branch_out,
    output reg Jump_out,
    output reg Jalr_out,
    output reg MemRead_out,
    output reg MemWrite_out,

    output reg [1:0] ALUOp_out,
    output reg ALUSrc_out,

    output reg [31:0] PC_out,
    output reg [31:0] ReadData1_out,
    output reg [31:0] ReadData2_out,
    output reg [31:0] ImmExt_out,
    output reg [31:0] Instruction_out,

    output reg [4:0] rs1_out,
    output reg [4:0] rs2_out,
    output reg [4:0] rd_out,
    output reg       funct7_out,
    output reg [2:0] funct3_out,
    output reg       predicted_taken_out
);

always @(posedge clk) begin
    if (rst || flush) begin
        // flush behaves exactly like reset for this register: it forces a
        // complete bubble (NOP) into EX. Data fields don't strictly need
        // clearing since every downstream control bit is 0 anyway, but
        // zeroing them too keeps waveforms/debug prints unambiguous.
        RegWrite_out     <= 1'b0;
        MemtoReg_out     <= 2'b00;
        Branch_out       <= 1'b0;
        Jump_out         <= 1'b0;
        Jalr_out         <= 1'b0;
        MemRead_out      <= 1'b0;
        MemWrite_out     <= 1'b0;
        ALUOp_out        <= 2'b0;
        ALUSrc_out       <= 1'b0;
        PC_out           <= 32'b0;
        ReadData1_out    <= 32'b0;
        ReadData2_out    <= 32'b0;
        ImmExt_out       <= 32'b0;
        Instruction_out  <= 32'b0;
        rs1_out          <= 5'b0;
        rs2_out          <= 5'b0;
        rd_out           <= 5'b0;
        funct7_out       <= 1'b0;
        funct3_out       <= 3'b0;
        predicted_taken_out <= 1'b0;
    end
    else begin
        RegWrite_out     <= RegWrite_in;
        MemtoReg_out     <= MemtoReg_in;
        Branch_out       <= Branch_in;
        Jump_out         <= Jump_in;
        Jalr_out         <= Jalr_in;
        MemRead_out      <= MemRead_in;
        MemWrite_out     <= MemWrite_in;
        ALUOp_out        <= ALUOp_in;
        ALUSrc_out       <= ALUSrc_in;
        PC_out           <= PC_in;
        ReadData1_out    <= ReadData1_in;
        ReadData2_out    <= ReadData2_in;
        ImmExt_out       <= ImmExt_in;
        Instruction_out  <= Instruction_in;
        rs1_out          <= rs1_in;
        rs2_out          <= rs2_in;
        rd_out           <= rd_in;
        funct7_out       <= funct7_in;
        funct3_out       <= funct3_in;
        predicted_taken_out <= predicted_taken_in;
    end
end

endmodule