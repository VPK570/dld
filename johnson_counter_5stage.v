module johnson_counter_5stage(
    input clk,
    input reset,
    output [4:0] q
);
    
    wire [4:0] qn;
    wire feedback;
    
    assign feedback = ~q[4];
    
    dff_with_reset stage0 (.clk(clk), .reset(reset), .d(feedback), .q(q[0]), .qn(qn[0]));
    dff_with_reset stage1 (.clk(clk), .reset(reset), .d(q[0]), .q(q[1]), .qn(qn[1]));
    dff_with_reset stage2 (.clk(clk), .reset(reset), .d(q[1]), .q(q[2]), .qn(qn[2]));
    dff_with_reset stage3 (.clk(clk), .reset(reset), .d(q[2]), .q(q[3]), .qn(qn[3]));
    dff_with_reset stage4 (.clk(clk), .reset(reset), .d(q[3]), .q(q[4]), .qn(qn[4]));
    
endmodule
