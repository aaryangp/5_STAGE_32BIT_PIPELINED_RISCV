module MEM_WB_reg(
    input clk,
    input rst,

    // ---------------- WB control ----------------
    input RegWrite_in,
    input [1:0] MemtoReg_in,

    // ---------------- datapath -------------------
    input [31:0] ReadData_in,      // data memory output
    input [31:0] ALU_Result_in,
    input [31:0] LinkPC_in,        // PC+4, for JAL/JALR's writeback value
    input [31:0] Instruction_in,   // carried for debug/waveform viewing
    input [4:0]  rd_in,

    // ---------------- outputs --------------------
    output reg RegWrite_out,
    output reg [1:0] MemtoReg_out,

    output reg [31:0] ReadData_out,
    output reg [31:0] ALU_Result_out,
    output reg [31:0] LinkPC_out,
    output reg [31:0] Instruction_out,
    output reg [4:0]  rd_out
);

always @(posedge clk) begin
    if (rst) begin
        RegWrite_out    <= 1'b0;
        MemtoReg_out    <= 2'b00;
        ReadData_out    <= 32'b0;
        ALU_Result_out  <= 32'b0;
        LinkPC_out      <= 32'b0;
        Instruction_out <= 32'b0;
        rd_out          <= 5'b0;
    end
    else begin
        RegWrite_out    <= RegWrite_in;
        MemtoReg_out    <= MemtoReg_in;
        ReadData_out    <= ReadData_in;
        ALU_Result_out  <= ALU_Result_in;
        LinkPC_out      <= LinkPC_in;
        Instruction_out <= Instruction_in;
        rd_out          <= rd_in;
    end
end

endmodule