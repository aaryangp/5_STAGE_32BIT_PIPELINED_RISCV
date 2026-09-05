module EX_MEM_reg(
    input clk,
    input rst,
    input flush,    // branch/jump misprediction: force this stage to a NOP

    // ---------------- WB control ----------------
    input RegWrite_in,
    input [1:0] MemtoReg_in,

    // ---------------- M control ------------------
    input MemRead_in,
    input MemWrite_in,
    input Branch_in,
    input Jump_in,            // JAL/JALR, carried so MEM can OR it with Branch to gate PC redirect
    input branch_taken_in,   // actual outcome computed in EX: real branch condition, OR forced 1 for jumps
                              // this is what plays the role of "Zero" in the textbook diagram
    input predicted_taken_in, // what the predictor guessed for this same instruction, back in ID

    // ---------------- datapath -------------------
    input [31:0] ALU_Result_in,
    input [31:0] BranchTarget_in,  // the resolved redirect target: PC+imm for branch/JAL, rs1+imm for JALR
    input [31:0] WriteData_in,     // unmodified rs2 value, needed for SW
    input [31:0] LinkPC_in,        // PC+4 of this instruction, needed for JAL/JALR's writeback value
    input [31:0] Instruction_in,   // carried for debug/waveform viewing
    input [4:0]  rd_in,

    // ---------------- outputs --------------------
    output reg RegWrite_out,
    output reg [1:0] MemtoReg_out,

    output reg MemRead_out,
    output reg MemWrite_out,
    output reg Branch_out,
    output reg Jump_out,
    output reg branch_taken_out,
    output reg predicted_taken_out,

    output reg [31:0] ALU_Result_out,
    output reg [31:0] BranchTarget_out,
    output reg [31:0] WriteData_out,
    output reg [31:0] LinkPC_out,
    output reg [31:0] Instruction_out,
    output reg [4:0]  rd_out
);

always @(posedge clk) begin
    if (rst || flush) begin
        // flush behaves exactly like reset: a mispredicted branch/jump means the
        // instruction sitting in EX right now was fetched down the wrong
        // path, so it must not be allowed to reach MEM as itself -- turn it
        // into a bubble instead.
        RegWrite_out      <= 1'b0;
        MemtoReg_out      <= 2'b00;
        MemRead_out       <= 1'b0;
        MemWrite_out      <= 1'b0;
        Branch_out        <= 1'b0;
        Jump_out          <= 1'b0;
        branch_taken_out  <= 1'b0;
        predicted_taken_out <= 1'b0;
        ALU_Result_out    <= 32'b0;
        BranchTarget_out  <= 32'b0;
        WriteData_out     <= 32'b0;
        LinkPC_out        <= 32'b0;
        Instruction_out   <= 32'b0;
        rd_out            <= 5'b0;
    end
    else begin
        RegWrite_out      <= RegWrite_in;
        MemtoReg_out      <= MemtoReg_in;
        MemRead_out       <= MemRead_in;
        MemWrite_out      <= MemWrite_in;
        Branch_out        <= Branch_in;
        Jump_out          <= Jump_in;
        branch_taken_out  <= branch_taken_in;
        predicted_taken_out <= predicted_taken_in;
        ALU_Result_out    <= ALU_Result_in;
        BranchTarget_out  <= BranchTarget_in;
        WriteData_out     <= WriteData_in;
        LinkPC_out        <= LinkPC_in;
        Instruction_out   <= Instruction_in;
        rd_out            <= rd_in;
    end
end

endmodule