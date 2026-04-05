module cd4017_tb;
    
    reg clk;
    reg reset;
    reg clk_inhibit;
    wire [9:0] Q;
    wire carry_out;
    
    cd4017_top uut (
        .clk(clk),
        .reset(reset),
        .clk_inhibit(clk_inhibit),
        .Q(Q),
        .carry_out(carry_out)
    );
    
    initial clk = 0;
    always #25 clk = ~clk;
    
    initial begin
        reset = 1;
        clk_inhibit = 0;
        #100;
        reset = 0;
        
        #750;
        
        clk_inhibit = 1;
        #200;
        clk_inhibit = 0;
        
        #500;
        
        reset = 1;
        #50;
        reset = 0;
        
        #1000;
        
        $finish;
    end
    
    initial begin
        $monitor("Time=%0t | Q=%b | Carry=%b | Reset=%b | Inhibit=%b", 
                 $time, Q, carry_out, reset, clk_inhibit);
    end
    
    initial begin
        $dumpfile("cd4017.vcd");
        $dumpvars(0, cd4017_tb);
    end
    
endmodule
