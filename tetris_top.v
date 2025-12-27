`include "tetris_defines.v"

module tetris_top(
    input        i_clk,
    input        i_rst,
    input        i_start,
    input        i_left,
    input        i_right,
    input        i_rotate,
    input        i_down,

    output [7:0]     o_VGA_R,
    output [7:0]     o_VGA_G,
    output [7:0]     o_VGA_B,
    output           o_VGA_HS,
    output           o_VGA_VS,
    output           o_VGA_CLK,
    output           o_VGA_BLANK_N,
    output           o_VGA_SYNC_N,

    output [6:0] o_FND0,
    output [6:0] o_FND1,


    output [7:0] o_LED
);

    localparam BOARD_W = `BOARD_W;
    localparam BOARD_H = `BOARD_H;

    reg pixel_clk;

    always @(posedge i_clk) begin
        if (i_rst)
            pixel_clk <= 1'b0;
        else
            pixel_clk <= ~pixel_clk;
    end

    wire [2:0] spawn_shape;
    wire [1:0] spawn_rot;
    wire [4:0] spawn_x;
    wire [4:0] spawn_y;

    wire       new_piece;
    wire       play_enable;
    wire       move_left;
    wire       move_right;
    wire       move_rotate;
    wire       move_drop;

    wire       lock;
    wire       line_full;
    wire [2:0] line_cnt;
    wire       gameover;

    wire [BOARD_W*BOARD_H-1:0] board_bits;
    wire [4:0] c_x;
    wire [4:0] c_y;
    wire [2:0] c_shape;
    wire [1:0] c_rot;

    wire [2:0]  state;
    wire [7:0] score;

    assign o_LED[2:0] = state;
    assign o_LED[3]   = gameover;
    assign o_LED[7:4] = 4'b0;

    spawn spawn0(pixel_clk, i_rst, spawn_shape, spawn_rot, spawn_x, spawn_y);

    logic logic0(
        pixel_clk, i_rst, i_start, i_left, i_right, i_rotate, i_down, 
        lock, line_full, line_cnt, gameover, new_piece, play_enable, 
        move_left, move_right, move_rotate, move_drop, state, score
    );

    move #(BOARD_W, BOARD_H) 
    move0 (
        pixel_clk, i_rst,

        new_piece, spawn_shape, spawn_rot, spawn_x, spawn_y,

        play_enable, move_left, move_right, move_rotate, move_drop,

        lock, line_full, line_cnt, gameover,

        board_bits, c_x, c_y, c_shape, c_rot
    );

    wire [3:0] score_ones  = score[3:0];      
    wire [3:0] score_tens  = score[7:4];          


    FND FND0(score_ones, o_FND0);
    FND FND1(score_tens, o_FND1);
    
    vga #( BOARD_W, BOARD_H) 
    vga0 (
        pixel_clk, i_rst, board_bits, c_x, c_y, c_shape, c_rot, state, score, gameover,

        o_VGA_R, o_VGA_G, o_VGA_B, o_VGA_HS, o_VGA_VS, o_VGA_CLK, o_VGA_BLANK_N, o_VGA_SYNC_N
    );

endmodule