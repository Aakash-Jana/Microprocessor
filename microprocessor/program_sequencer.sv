
module program_sequencer (
        input wire clk, sync_reset,
        output [7:0] pm_addr,
        input wire jmp,
        input wire jmp_nz,  
        input wire [3:0] jmp_addr,    // in the assignment 6 the testbench use jump_addr
        input wire dont_jump,
        output wire [7:0] pc,
        output wire [7:0] from_PS
    );

    always @ (*)
        from_PS <= pc;
        // from_PS <= 8'h00;    // default

    always @ (posedge clk)
    begin
       pc = pm_addr; 
    end

    always @ (*)
    begin
        if (sync_reset == 1'b1 )
            pm_addr = 8'H0;
        else if (jmp == 1'b1 ) 
            pm_addr = { jmp_addr, 4'H0 };
        else if ((jmp_nz == 1'b1) && (dont_jump == 1'b0) )
            pm_addr = {jmp_addr, 4'H0};
        else if ((jmp_nz == 1'b1) && (dont_jump == 1'b1) )
            pm_addr = pc + 8'H01;
        else if ((jmp==1'b0) && (jmp_nz==1'b0))
            pm_addr = pc + 8'H01;
        // else
        //     pm_addr <= pm_addr;
    end

endmodule