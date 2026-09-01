module controlunit(
    instruction,
    Branch,
    MemRead,
    MemtoReg,
    ALUOp,
    MemWrite,
    ALUSrc,
    RegWrite
);

input [6:0] instruction;

output reg Branch;
output reg MemRead;
output reg MemtoReg;
output reg MemWrite;
output reg ALUSrc;
output reg RegWrite;

output reg [1:0] ALUOp;

always @(*) begin

    // Default values
    Branch   = 1'b0;
    MemRead  = 1'b0;
    MemtoReg = 1'b0;
    MemWrite = 1'b0;
    ALUSrc   = 1'b0;
    RegWrite = 1'b0;
    ALUOp    = 2'b00;

    case (instruction)

        // -------------------------------
        // R-TYPE
        // ADD, SUB, AND, OR, XOR,
        // SLT, SLL, SRL, SRA
        // -------------------------------
        7'b0110011: begin

            ALUSrc   = 1'b0;
            MemtoReg = 1'b0;
            RegWrite = 1'b1;

            MemRead  = 1'b0;
            MemWrite = 1'b0;
            Branch   = 1'b0;

            ALUOp    = 2'b10;

        end


        // -------------------------------
        // I-TYPE LOAD
        // LW
        // -------------------------------
        7'b0000011: begin

            ALUSrc   = 1'b1;
            MemtoReg = 1'b1;
            RegWrite = 1'b1;

            MemRead  = 1'b1;
            MemWrite = 1'b0;
            Branch   = 1'b0;

            ALUOp    = 2'b00;

        end


        // -------------------------------
        // S-TYPE STORE
        // SW
        // -------------------------------
        7'b0100011: begin

            ALUSrc   = 1'b1;
            MemtoReg = 1'b0;
            RegWrite = 1'b0;

            MemRead  = 1'b0;
            MemWrite = 1'b1;
            Branch   = 1'b0;

            ALUOp    = 2'b00;

        end


        // -------------------------------
        // SB-TYPE BRANCH
        // BEQ, BNE, BLT, BGE
        // -------------------------------
        7'b1100011: begin

            ALUSrc   = 1'b0;
            MemtoReg = 1'b0;
            RegWrite = 1'b0;

            MemRead  = 1'b0;
            MemWrite = 1'b0;
            Branch   = 1'b1;

            ALUOp    = 2'b01;

        end


        // -------------------------------
        // I-TYPE ALU
        // ADDI, SLTI, ANDI, ORI,
        // XORI, SLLI, SRLI, SRAI
        // -------------------------------
        7'b0010011: begin

            ALUSrc   = 1'b1;   // IMPORTANT: use immediate
            MemtoReg = 1'b0;   // result comes from ALU
            RegWrite = 1'b1;   // write result to rd

            MemRead  = 1'b0;
            MemWrite = 1'b0;
            Branch   = 1'b0;

            ALUOp    = 2'b10;  // ALU_Control decides exact operation

        end

    endcase

end

endmodule
