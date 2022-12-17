module Computational_unit (
        input wire clk,
        input wire sync_reset,
        output reg r_eq_0,         //(zero_flag),
        input wire [3:0] i_pins,         //(i_pins),
        input wire [3:0] nibble_ir,     //(LS_nibble_ir),
        input wire i_sel,         //(i_mux_select),
        input wire y_sel,         //(y_mux_select),
        input wire x_sel,         //(x_mux_select),
        input wire [3:0] source_sel,    //(source_select),
        input wire [8:0] reg_en,        //(reg_enables),
        output reg [3:0] i,             //(data_mem_addr),
        output reg [3:0] data_bus,      //(data_bus),
        input wire [3:0] dm,            //(dm),
        output reg [3:0] o_reg,          //(o_reg)
        output reg [3:0] x0, x1, y0, y1, r, m, alu_out,
        output reg [7:0] from_CU
    );

    always @ (*)
        from_CU <= {x1,x0}; // affects acc. output 
        // from_CU <= 8'h00; // affects acc. output 
    
    always @ (*)
    begin
        case (source_sel)
            4'd0: data_bus <= x0;
            4'd1: data_bus <= x1;
            4'd2: data_bus <= y0;
            4'd3: data_bus <= y1;
            4'd4: data_bus <= r;
            4'd5: data_bus <= m;
            4'd6: data_bus <= i;
            4'd7: data_bus <= dm;
            4'd8: data_bus <= pm_data;
            4'd9: data_bus <= i_pins;
            4'd10: data_bus <= 4'H0;
            default: data_bus <= 4'H0;
        endcase
    end

    always @ (posedge clk)
    begin
        if (reg_en[0]==1'b1)
            x0 <= data_bus;
        else
            x0 <= x0;
    end

    always @ (posedge clk)
    begin
        if (reg_en[1]==1'b1)
            x1 <= data_bus;
        else
            x1 <= x1;
    end

    always @ (posedge clk)
    begin
        if (reg_en[2]==1'b1)
            y0 <= data_bus;
        else
            y0 <= y0;
    end

    always @ (posedge clk)
    begin
        if (reg_en[3]==1'b1)
            y1 <= data_bus;
        else
            y1 <= y1;
    end

    always @ (posedge clk)
    begin
        if (reg_en[5]==1'b1)
            m <= data_bus;
        else
            m <= m;
    end

    /* i register and also dm write path */
    reg [3:0] increment;
    reg [3:0] i_input;

    always @ (*)
        increment <= m + i;

    always @ (*)
    begin
        if (i_sel==1'b1)
            i_input <= increment;
        else
            i_input <= data_bus;
    end

    always @ (posedge clk)
    begin
        if (reg_en[6]==1'b1)
            i <= i_input;
        else
            i <= i;
    end
    /* i register and also dm write path ends*/

    always @ (posedge clk)
    begin
        if (reg_en[8]==1'b1)
            o_reg <= data_bus;
        else
            o_reg <= o_reg;
    end

    /* ALU */
    reg [3:0] x;
    reg [3:0] y;

    always @ (*)
    begin
        if (x_sel ==1'b0)
            x <= x0;
        else
            x <= x1;
    end
    
    always @ (*)
    begin
        if (y_sel ==1'b0)
            y <= y0;
        else
            y <= y1;
    end

    // Main ALU logic
    reg alu_out_eq_0 , ir_3;
    reg [3:0] pm_data;
    reg [2:0] alu_func;

    always @ (*)
        alu_func <= nibble_ir[2:0];
    
    always @ (*)
        ir_3 = nibble_ir[3];
    
    always @ (*)
        pm_data <= nibble_ir;

    always @ (*)
    begin
        if (sync_reset==1'b1)
            alu_out_eq_0 <= 1'b1;
        else if (alu_out==4'd0)
            alu_out_eq_0 <= 1'b1;
        else
            alu_out_eq_0 <= 1'b0;
    end

    reg [7:0] mul;  // created since multiplication could not be directly sliced
    always @ (*)
        mul <= x * y;

    always @ (*)
    begin
        if (ir_3==1'b0)
        begin
            case (alu_func)
                3'b000 : alu_out <= (~x + 1); //-x;
                3'b001 : alu_out <= x - y;
                3'b010 : alu_out <= x + y;
                3'b011 : alu_out <= mul[7:4];
                3'b100 : alu_out <= mul[3:0];
                3'b101 : alu_out <= x ^ y;
                3'b110 : alu_out <= x & y;
                3'b111 : alu_out <= ~x;
            endcase
        end
        else
            if (alu_func==3'b000)       // NOP instr
                alu_out <= r;
            else if (alu_func==3'b111)  // NOP instr
                alu_out <= r;
            else
                case (alu_func)
                    3'b001 : alu_out <= x - y;
                    3'b010 : alu_out <= x + y;
                    3'b011 : alu_out <= mul[7:4];
                    3'b100 : alu_out <= mul[3:0];
                    3'b101 : alu_out <= x ^ y;
                    3'b110 : alu_out <= x & y;
                endcase
    end

// Simple ALU
// always @ *
//     if (sync_reset == 1'b1)
//         alu_out = 4'H0;
//     else if ((alu_func == 3'b000) && nibble_ir[3] == 1'b0)
//         alu_out = -x;
//     else if ((alu_func == 3'b000) && nibble_ir[3] == 1'b1)
//         alu_out = r;
//     else if (alu_func == 3'b001)
//         alu_out = x-y;
//     else if (alu_func == 3'b010)
//         alu_out = x+y;
//     else if (alu_func == 3'b011)
//         alu_out = mul[7:4];
//     else if (alu_func == 3'b100)
//         alu_out = mul[3:0];
//     else if (alu_func == 3'b101)
//         alu_out = x^y;
//     else if (alu_func == 3'b110)
//         alu_out = x&y;
//     else if ((alu_func == 3'b111) && (nibble_ir[3] == 1'b0))
//         alu_out = ~x;
//     else if ((alu_func == 3'b111) && (nibble_ir[3] == 1'b1))
//         alu_out = r;
//     else 
//         alu_out = r;


    always @ (posedge clk)
        if (reg_en[4]==1'b1)
            r_eq_0 <= alu_out_eq_0;
        else
            r_eq_0 <= r_eq_0;


    always @ (posedge clk) // we are not resetting with sync_reset
        if (reg_en[4]==1'b1)
            r <= alu_out;
        else
            r <= r;
    /* ALU ends */


endmodule
