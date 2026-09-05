`include "pipelined_top.v"
module tb_top() ;

reg clk , rst ;

top uut(.clk(clk),.rst(rst));

initial begin

    clk = 1'b0 ;
    rst = 1'b1 ;

    #12
    rst = 1'b0 ;

    #150;
    $display("\n---- final register check ----");
    $display("x1=%0d (expect 4)", uut.RB.RB[1]);
    $display("x2=%0d (expect 2, UNCHANGED -- both dead writes must be skipped)", uut.RB.RB[2]);
    $display("x3=%0d (expect 5)", uut.RB.RB[3]);
    $display("x4=%0d (expect 20)", uut.RB.RB[4]);
    $display("x6=%0d (expect 99)", uut.RB.RB[6]);
    $finish ;
end

always begin
    #5 clk = ~clk ;
end


  always @(posedge clk) begin
        #1 ;

        $display("t=%0t | stall=%b mispred=%b || IF: PC=%h I=%h || ID: I=%h pred=%b || EX: I=%h Jump=%b Jalr=%b tgt=%h link=%h ALUres=%0d actual_taken=%b || MEM: I=%h ALUres=%0d pc_src=%b || WB: I=%h rd=%0d wdata=%0d",
            $time, uut.stall_load_use, uut.misprediction,
            uut.PC_TOP, uut.INSTRUCTION,
            uut.IFID_Instruction, uut.predicted_taken_ID,
            uut.IDEX_Instruction, uut.IDEX_Jump, uut.IDEX_Jalr, uut.jump_target_top, uut.link_pc4_top, uut.ALU_Result_TOP, uut.actual_taken,
            uut.EXMEM_Instruction, uut.EXMEM_ALU_Result, uut.pc_src,
            uut.MEMWB_Instruction, uut.MEMWB_rd, uut.write_data_TOP
        );
    end

initial begin

$dumpfile("tb.vcd");
$dumpvars(0,tb_top);

end

endmodule