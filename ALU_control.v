module ALU_Control(ALUOp, fun7, fun3, Control_out);

    input fun7;
    input [2:0] fun3;
    input [1:0] ALUOp; 
    output reg [3:0] Control_out;

always @(*) begin
    Control_out = 4'b0010; // default ADD

    case (ALUOp)

        2'b00: begin // Load / Store / ADDI
            case (fun3)
                3'b000: Control_out = 4'b0010; // ADD
                3'b010: Control_out = 4'b0111; // SLT
                3'b111: Control_out = 4'b0000; // AND
                3'b110: Control_out = 4'b0001; // OR
                3'b100: Control_out = 4'b1100; // XOR
            endcase
        end

       2'b01: begin  // Branch instructions
           case (fun3)
        3'b000: Control_out = 4'b0110; // BEQ
        3'b001: Control_out = 4'b0110; // BNE
        3'b100: Control_out = 4'b0111; // BLT
        3'b101: Control_out = 4'b0111; // BGE
        default: Control_out = 4'b0110;
          endcase
              end

        2'b10: begin // R-Type
            case (fun3)
                3'b000: Control_out = (fun7) ? 4'b0110 : 4'b0010; // SUB/ADD
                3'b010: Control_out = 4'b0111; // SLT
                3'b111: Control_out = 4'b0000; // AND
                3'b110: Control_out = 4'b0001; // OR
                3'b100: Control_out = 4'b1100; // XOR
                 // 🔥 SHIFT INSTRUCTIONS
                3'b001: Control_out = 4'b1001;              // SLL
                3'b101: Control_out = (fun7) ? 4'b1011 : 4'b1010;     // SRL
            endcase
        end
    endcase
end

endmodule
