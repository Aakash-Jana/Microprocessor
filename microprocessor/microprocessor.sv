
module microprocessor (
    input wire clk,
    input wire reset,
    input wire [3:0] i_pins,
    output wire [3:0] o_reg,
    output wire [7:0] pm_address , pm_data, pc,
    output wire NOPC8, NOPCF, NOPD8, NOPDF, zero_flag,
    output wire [3:0] x0, x1, y0, y1, r, m, i,
    output wire [8:0] reg_enables,
    output wire [7:0] from_ID, from_PS, from_CU, ir
);


    program_memory prog_mem(
        .clock(~clk),
        .address(pm_address),
        .q(pm_data)
    );

    reg sync_reset;
    always @(posedge clk) begin
        if (clk)
            sync_reset <= reset;
        else
            sync_reset <= sync_reset;
    end

    wire jump, conditional_jump; 
    wire [3:0] LS_nibble_ir;

    program_sequencer prog_sequencer(
        .clk(clk),
        .sync_reset(sync_reset),
        .pm_addr(pm_address),
        .jmp(jump),
        .jmp_nz(conditional_jump),  
        .jmp_addr(LS_nibble_ir),    // in the assignment 6 the testbench use jump_addr
        .dont_jump(zero_flag),
        .pc(pc),
        .from_PS(from_PS)
    );

    wire i_mux_select , y_mux_select, x_mux_select;
    wire [3:0] source_select;

    instruction_decoder inst_decoder1(
        .clk(clk),
        .sync_reset(sync_reset),
        .next_instr(pm_data),
        .jmp(jump),
        .jmp_nz(conditional_jump),
        .ir_nibble(LS_nibble_ir), // ir[3:0]
        .i_sel(i_mux_select),
        .y_sel(y_mux_select),
        .x_sel(x_mux_select),
        .source_sel(source_select),
        .reg_en(reg_enables),
        .ir(ir),
        .from_ID(from_ID),
        .NOPC8(NOPC8),
        .NOPCF(NOPCF),
        .NOPD8(NOPD8),
        .NOPDF(NOPDF)
    );

    wire [3:0] data_mem_addr , data_bus, dm;

    // to make the i reg value an output
    always @ (*)
        i <= data_mem_addr; // connects to the i reg in CU

    Computational_unit comp_unit(
        .clk(clk),
        .sync_reset(sync_reset),
        .r_eq_0(zero_flag),
        .i_pins(i_pins),
        .nibble_ir(LS_nibble_ir),
        .i_sel(i_mux_select),
        .y_sel(y_mux_select),
        .x_sel(x_mux_select),
        .source_sel(source_select),
        .reg_en(reg_enables),
        .i(data_mem_addr),
        .data_bus(data_bus),
        .dm(dm),
        .o_reg(o_reg),
        .x0(x0),
        .x1(x1),
        .y0(y0),
        .y1(y1),
        .r(r),
        .m(m),
        .from_CU(from_CU)
    );


    data_memory data_mem(
        .clock(~clk),
        .address(data_mem_addr),
        .data(data_bus),
        .q(dm),
        .wren(reg_enables[7])
    );

endmodule