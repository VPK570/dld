module dff_with_reset(
    input clk,
    input reset,
    input d,
    output reg q,
    output qn
);
    
    always @(posedge clk or posedge reset) begin
        if (reset)
            q <= 1'b0;
        else
            q <= d;
    end
    
    assign qn = ~q;
    
endmodule
