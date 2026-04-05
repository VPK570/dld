module clock_control(
    input clk_in,
    input clk_inhibit,
    input reset,
    output clk_out
);
    
    assign clk_out = clk_in & ~clk_inhibit & ~reset;
    
endmodule
