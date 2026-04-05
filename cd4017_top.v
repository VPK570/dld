module cd4017_top(
    input clk,
    input reset,
    input clk_inhibit,
    output [9:0] Q,
    output carry_out
);
    
    wire gated_clk;
    wire [4:0] counter_state;
    
    clock_control clk_ctrl (
        .clk_in(clk),
        .clk_inhibit(clk_inhibit),
        .reset(reset),
        .clk_out(gated_clk)
    );
    
    johnson_counter_5stage counter (
        .clk(gated_clk),
        .reset(reset),
        .q(counter_state)
    );
    
    decoder_10output decoder (
        .q(counter_state),
        .out(Q)
    );
    
    assign carry_out = Q[9];
    
endmodule
