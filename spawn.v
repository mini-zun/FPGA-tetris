module spawn(
    input       i_clk,
    input       i_rst,
    output reg [2:0] o_shape,
    output reg [1:0] o_rot,
    output reg [4:0] o_x,
    output reg [4:0] o_y
);

    reg [7:0] lfsr;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) lfsr = 8'hA5;                           //rst신호로 인한 스위치 작동안할시 spawn이 안되나?
        else       lfsr = {lfsr[6:0], lfsr[7] ^ lfsr[5]};
    end

    always @* begin
        o_shape   = lfsr[2:0] % 7;
        o_rot     = lfsr[4:3];    
        o_x  = 5'd8;
        o_y  = 5'd0;
    end

endmodule