module decoder_10output(
    input [4:0] q,
    output reg [9:0] out
);
    
    always @(*) begin
        case (q)
            5'b00000: out = 10'b0000000001;
            5'b00001: out = 10'b0000000010;
            5'b00011: out = 10'b0000000100;
            5'b00111: out = 10'b0000001000;
            5'b01111: out = 10'b0000010000;
            5'b11111: out = 10'b0000100000;
            5'b11110: out = 10'b0001000000;
            5'b11100: out = 10'b0010000000;
            5'b11000: out = 10'b0100000000;
            5'b10000: out = 10'b1000000000;
            default:  out = 10'b0000000001;
        endcase
    end
    
endmodule
