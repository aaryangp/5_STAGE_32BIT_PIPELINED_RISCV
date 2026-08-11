module controlunit(instruction , Branch , MemRead , MemtoReg,ALUOp , MemWrite,ALUSrc ,RegWrite) ;

input [6:0] instruction ;
output reg Branch , MemRead , MemtoReg, MemWrite , ALUSrc , RegWrite ;
output reg [1:0] ALUOp ;

always@(*) begin
    // 🛑 CRITICAL FIX: Initialize all outputs to a safe default (e.g., NO-OP/Stall)
    Branch   = 1'b0;
    MemRead  = 1'b0;
    MemtoReg = 1'b0;
    MemWrite = 1'b0;
    ALUSrc   = 1'b0;
    RegWrite = 1'b0;
    ALUOp    = 2'b00; // Default ALU operation (e.g., for ADD)

    case(instruction)
        
        7'b0110011 : begin   // R-TYPE INSTRUCTIONS
            ALUSrc = 1'b0 ; 
            MemtoReg = 1'b0 ;
            RegWrite = 1'b1 ;
            MemRead = 1'b0 ;
            MemWrite = 1'b0 ;
            Branch = 1'b0 ;
            ALUOp = 2'b10 ;
        end

        7'b0000011 : begin   // LOAD (I-TYPE) INSTRUCTIONS
            ALUSrc = 1'b1 ; 
            MemtoReg = 1'b1 ;
            RegWrite = 1'b1 ;
            MemRead = 1'b1 ;
            MemWrite = 1'b0 ;
            Branch = 1'b0 ;
            ALUOp = 2'b00 ; // ALU performs ADD for address calculation
        end

         7'b0010011 : begin   // I-TYPE ALU INSTRUCTIONS
          ALUSrc   = 1'b1;
          MemtoReg = 1'b0;
          RegWrite = 1'b1;
          MemRead  = 1'b0;
          MemWrite = 1'b0;
          Branch   = 1'b0;
          ALUOp    = 2'b10;
            end
        
        7'b0100011 : begin   // STORE (S-TYPE) INSTRUCTIONS
            ALUSrc = 1'b1 ; 
            MemtoReg = 1'b0 ;
            RegWrite = 1'b0 ;
            MemRead = 1'b0 ;
            MemWrite = 1'b1;
            Branch = 1'b0 ;
            ALUOp = 2'b00 ; // ALU performs ADD for address calculation
        end
        
        7'b1100011 : begin   // BRANCH (SB-TYPE) INSTRUCTIONS 
            ALUSrc = 1'b0 ; 
            MemtoReg = 1'b0 ;
            RegWrite = 1'b0 ;
            MemRead = 1'b0 ;
            MemWrite = 1'b0 ;
            Branch = 1'b1 ;
            ALUOp = 2'b01 ; // ALU performs SUB for comparison
        end
        
        // ⚠️ Missing Instruction Types (JAL/JALR/I-type ALU) will fall here:
        // By using the initial assignment (above), this 'default' case is covered.
    endcase
end

endmodule
