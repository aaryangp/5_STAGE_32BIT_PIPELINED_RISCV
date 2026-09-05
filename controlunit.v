module controlunit(
    instruction,
    Branch,
    Jump,
    Jalr,
    MemRead,
    MemtoReg,
    ALUOp,
    MemWrite,
    ALUSrc,
    RegWrite
);

input [6:0] instruction;

output reg Branch;
output reg Jump;   // asserted for JAL and JALR: this instruction is UNCONDITIONALLY taken
output reg Jalr;   // asserted only for JALR: target = rs1+imm (not PC+imm like JAL/branches)
output reg MemRead;
output reg [1:0] MemtoReg;  // 00 = ALU result, 01 = memory read data, 10 = PC+4 (link, for JAL/JALR)
output reg MemWrite;
output reg ALUSrc;
output reg RegWrite;

output reg [1:0] ALUOp;

always @(*) begin

    // Default values
    Branch   = 1'b0;
    Jump     = 1'b0;
    Jalr     = 1'b0;
    MemRead  = 1'b0;
    MemtoReg = 2'b00;
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
            MemtoReg = 2'b00;
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
            MemtoReg = 2'b01;
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
            MemtoReg = 2'b00;
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
            MemtoReg = 2'b00;
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
            MemtoReg = 2'b00;  // result comes from ALU
            RegWrite = 1'b1;   // write result to rd

            MemRead  = 1'b0;
            MemWrite = 1'b0;
            Branch   = 1'b0;

            ALUOp    = 2'b10;  // ALU_Control decides exact operation

        end


        // -------------------------------
        // J-TYPE
        // JAL: rd = PC+4; PC = PC + imm
        // -------------------------------
        7'b1101111: begin

            ALUSrc   = 1'b0;   // ALU unused -- target comes from branch_adder (PC + imm)
            MemtoReg = 2'b10;  // write back PC+4 (the link address)
            RegWrite = 1'b1;

            MemRead  = 1'b0;
            MemWrite = 1'b0;
            Branch   = 1'b0;
            Jump     = 1'b1;
            Jalr     = 1'b0;

            ALUOp    = 2'b00;  // unused

        end


        // -------------------------------
        // I-TYPE
        // JALR: rd = PC+4; PC = (rs1+imm) & ~1
        // -------------------------------
        7'b1100111: begin

            ALUSrc   = 1'b1;   // ALU computes rs1 + imm (funct3 is always 000 here -> ADD)
            MemtoReg = 2'b10;  // write back PC+4 (the link address)
            RegWrite = 1'b1;

            MemRead  = 1'b0;
            MemWrite = 1'b0;
            Branch   = 1'b0;
            Jump     = 1'b1;
            Jalr     = 1'b1;

            ALUOp    = 2'b00;  // forces ADD via the existing ALUOp=00,funct3=000 path

        end

    endcase

end

endmodule
