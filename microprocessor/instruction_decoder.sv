 
module instruction_decoder (
        input wire clk,
        input wire sync_reset,
        input wire [7:0] next_instr,
        output reg jmp,
        output reg jmp_nz,
        output reg [3:0] ir_nibble, // LS_nibble_ir ir[3:0]
        output reg i_sel,
        output reg y_sel,
        output reg x_sel,
        output wire [3:0] source_sel,
        output reg [8:0] reg_en, // not connected to scrambler does not affect acc. output 
        output wire [7:0] ir, from_ID,
        output wire  NOPC8, NOPCF, NOPD8, NOPDF
    );

    always @ (*)
        from_ID <= reg_en[7:0];
        // from_ID <= 8'h00;

    /* decoding NOP instructions (affects acc. output) */
    always @ (*)
        if (ir==8'hC8)
            NOPC8 <= 1'b1;
        else
            NOPC8 <= 1'b0;

    always @ (*)
        if (ir==8'hCF)
            NOPCF <= 1'b1;
        else
            NOPCF <= 1'b0;

    always @ (*)
        if (ir==8'hD8)
            NOPD8 <= 1'b1;
        else
            NOPD8 <= 1'b0;

    always @ (*)
        if (ir==8'hDF)
            NOPDF <= 1'b1;
        else
            NOPDF <= 1'b0;
    /* decoding NOP instructions ends */
    

    always @ ( posedge clk )  
    begin
        ir <= next_instr;
    end

    always @ (*)
        ir_nibble <= ir[3:0];
    

    /* logic for decoding register enables */
    // x0 - enable
    always @ (*)
    if (sync_reset == 1'b1)
        reg_en[0] <= 1'b1;
    else if ((ir[7]==1'b0) && (ir[6:4]==3'd0))  // load
        reg_en[0] <= 1'b1;
    else if ((ir[7:6]==2'b10) && (ir[5:3]==3'd0)) // move
        reg_en[0] <= 1'b1;
    else
        reg_en[0] <= 1'b0;

    // x1 - enable
    always @ (*)
    if (sync_reset == 1'b1)
        reg_en[1] <= 1'b1;
    else if ((ir[7]==1'b0) && (ir[6:4]==3'd1))  // load
        reg_en[1] <= 1'b1;
    else if ((ir[7:6]==2'b10) && (ir[5:3]==3'd1)) // move
        reg_en[1] <= 1'b1;
    else
        reg_en[1] <= 1'b0;

    // x2 - enable
    always @ (*)
    if (sync_reset == 1'b1)
        reg_en[2] <= 1'b1;
    else if ((ir[7]==1'b0) && (ir[6:4]==3'd2))  // load
        reg_en[2] <= 1'b1;
    else if ((ir[7:6]==2'b10) && (ir[5:3]==3'd2)) // move
        reg_en[2] <= 1'b1;
    else
        reg_en[2] <= 1'b0;

    // x3 - enable
    always @ (*)
    if (sync_reset == 1'b1)
        reg_en[3] <= 1'b1;
    else if ((ir[7]==1'b0) && (ir[6:4]==3'd3))  // load
        reg_en[3] <= 1'b1;
    else if ((ir[7:6]==2'b10) && (ir[5:3]==3'd3)) // move
        reg_en[3] <= 1'b1;
    else
        reg_en[3] <= 1'b0;

    // x5 - enable
    always @ (*)
    if (sync_reset == 1'b1)
        reg_en[5] <= 1'b1;
    else if ((ir[7]==1'b0) && (ir[6:4]==3'd5))  // load
        reg_en[5] <= 1'b1;
    else if ((ir[7:6]==2'b10) && (ir[5:3]==3'd5)) // move
        reg_en[5] <= 1'b1;
    else
        reg_en[5] <= 1'b0;

    // x6 - enable
    always @ (*)
    if (sync_reset == 1'b1)
        reg_en[6] <= 1'b1;
    else if ((ir[7]==1'b0) && ((ir[6:4]==3'd6) || (ir[6:4]==3'd7)))  // load into i or dm
        reg_en[6] <= 1'b1;
    else if ((ir[7:6]==2'b10) && ((ir[5:3]==3'd6) || (ir[5:3]==3'd7)) ) // move
        reg_en[6] <= 1'b1;
    else if ((ir[7:6]==2'b10) && (ir[2:0]==3'd7)) // when dm is source
        reg_en[6] <= 1'b1;
    else
        reg_en[6] <= 1'b0;

    // x7 - enable
    always @ (*)
    if (sync_reset == 1'b1)
        reg_en[7] <= 1'b1;
    else if ((ir[7]==1'b0) && (ir[6:4]==3'd7))  // load
        reg_en[7] <= 1'b1;
    else if ((ir[7:6]==2'b10) && (ir[5:3]==3'd7)) // move
        reg_en[7] <= 1'b1;
    else
        reg_en[7] <= 1'b0;

    // r - enable
    always @ (*)
    if (sync_reset == 1'b1)
        reg_en[4] = 1'b1;
    else if (ir[7:5]==3'b110) // note src must not be r as well - works only when an ALU opp is executed
        reg_en[4] = 1'b1;
    else
        reg_en[4] = 1'b0;

    // o_reg - enable
    always @ (*)
    if (sync_reset == 1'b1)
        reg_en[8] = 1'b1;
    else if ((ir[7]==1'b0) && (ir[6:4]==3'd4))
        reg_en[8] = 1'b1;
    else if ((ir[7:6]==2'b10) && (ir[5:3]==3'd4))
        reg_en[8] = 1'b1;
    else
        reg_en[8] = 1'b0;
    /* logic for decoding register enables done */


    /* logic for decoding source register */
    always @ (*)
        if (sync_reset == 1'b1)
            source_sel <= 4'd10; 
        else if (ir[7]==1'b0)                // load instruction
            source_sel <= 4'd8;    // connect pm_data or ir_nibble to the data bus in comp unit & enable the corresponding reg_en
        else if (ir[7:6]==2'b10)        // move instruction
            begin
                if ((ir[5:3]==ir[2:0]) && (ir[5:3]!=3'd4) ) // move from i_pins to reg bank
                    source_sel <= 4'd9; // connect i_pins to data_bus
                else if ((ir[5:3]==ir[2:0]) && (ir[5:3]==3'd4) )  // move r to o_reg
                    source_sel <= 4'd4; // r to data_bus
                else
                    source_sel <= ir[2:0];  // normal move , connects the register bank, dm,i  to data_bus
            end
        else
            source_sel <= 4'd10;
    /* logic for decoding source register done */


    /* logic for decoding i, x, y selects */
    always @ (*)
    begin
        if (sync_reset == 1'b1)
        begin
            x_sel <= 1'b0;
            y_sel <= 1'b0;
        end
        else
        begin
            x_sel <= ir[4];
            y_sel <= ir[3];
        end
    end
    
    always @ (*)        // i_sel is 0 only when the dst is the i reg otherwise always 1
    begin
        if (sync_reset == 1'b1)
            i_sel <= 1'b0;
        else if ((ir[7]==1'b0) && (ir[6:4]==3'd6))     // when dst is i_reg in load
            i_sel <= 1'b0;
        else if ((ir[7:6]==2'b10) && (ir[5:3]==3'd6)) // when dst is i_reg in move
            i_sel <= 1'b0;
        else
            i_sel <= 1'b1;
    end
    /* logic for decoding i, x, y selects done */


    /* logic for decoding instruction type */
    always @ (*)
    if (sync_reset == 1'b1)
        begin
            jmp <= 1'b0;
            jmp_nz <= 1'b0;
        end
    else if (ir[7:4] == 4'b1110) // unconditional jump instruction
        begin
            jmp <= 1'b1;
            jmp_nz <= 1'b0;
        end
    else if (ir[7:4] == 4'b1111) // conditional jump instruction
        begin
            jmp <= 1'b0;
            jmp_nz <= 1'b1;
        end
    else
        begin  // it is important to set these signals back to 0 for normal increment of the program sequencer
            jmp <= 1'b0;
            jmp_nz <= 1'b0;
        end
    /* logic for decoding instruction type done */

endmodule