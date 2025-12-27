`include "tetris_defines.v"

module move #(
    parameter BOARD_W = `BOARD_W,
    parameter BOARD_H = `BOARD_H
)(
    input        i_clk,
    input        i_rst,

    input        i_new_piece,
    input  [2:0] i_shape,
    input  [1:0] i_rotate,
    input  [4:0] i_x,
    input  [4:0] i_y,

    input        i_play_en,
    input        i_move_left,
    input        i_move_right,
    input        i_move_rotate,
    input        i_move_drop,

    output reg       o_lock,
    output reg       o_line_full,
    output reg [2:0] o_line_cnt,
    output reg       o_gameover,

    output [BOARD_W*BOARD_H-1:0] o_board_bits,
    output reg [4:0] o_x,
    output reg [4:0] o_y,
    output reg [2:0] o_shape,
    output reg [1:0] o_rotate
);

    reg [BOARD_W-1:0] board [0:BOARD_H-1];
    reg [4:0] c_x, c_y;
    reg [2:0] c_shape;
    reg [1:0] c_rotate;


    reg signed [3:0] ldx0, ldy0, ldx1, ldy1, ldx2, ldy2, ldx3, ldy3;
    reg signed [5:0] lcx, lcy;


    task get_offsets;
        input [2:0] shape;
        input [1:0] rotate;

        output reg signed [3:0] dx0, dy0, dx1, dy1, dx2, dy2, dx3, dy3;
    begin
        case (shape)
            3'd0: begin // I
                case(rotate)
                    2'd0: begin dx0=0;dy0=0; dx1=0;dy1=1; dx2=0;dy2=2; dx3=0;dy3=3; end
                    2'd1: begin dx0=0;dy0=2; dx1=1;dy1=2; dx2=2;dy2=2; dx3=3;dy3=2; end
                    2'd2: begin dx0=0;dy0=0; dx1=0;dy1=1; dx2=0;dy2=2; dx3=0;dy3=3; end
                    2'd3: begin dx0=0;dy0=2; dx1=1;dy1=2; dx2=2;dy2=2; dx3=3;dy3=2; end
                endcase
            end
            3'd1: begin // O
                dx0=0;dy0=0; dx1=1;dy1=0; dx2=0;dy2=1; dx3=1;dy3=1;
            end
            3'd2: begin // T
                case(rotate)
                    2'd0: begin dx0=0;dy0=1; dx1=1;dy1=1; dx2=2;dy2=1; dx3=1;dy3=2; end
                    2'd1: begin dx0=1;dy0=0; dx1=1;dy1=1; dx2=1;dy2=2; dx3=0;dy3=1; end
                    2'd2: begin dx0=2;dy0=1; dx1=1;dy1=1; dx2=0;dy2=1; dx3=1;dy3=0; end
                    2'd3: begin dx0=0;dy0=2; dx1=0;dy1=1; dx2=0;dy2=0; dx3=1;dy3=1; end
                endcase
            end
            3'd3: begin // L
                case(rotate)
                    2'd0: begin dx0=0;dy0=0; dx1=0;dy1=1; dx2=0;dy2=2; dx3=1;dy3=2; end
                    2'd1: begin dx0=2;dy0=1; dx1=1;dy1=1; dx2=0;dy2=1; dx3=0;dy3=2; end
                    2'd2: begin dx0=1;dy0=2; dx1=1;dy1=1; dx2=1;dy2=0; dx3=0;dy3=0; end
                    2'd3: begin dx0=0;dy0=1; dx1=1;dy1=1; dx2=2;dy2=1; dx3=2;dy3=0; end
                endcase
            end
            3'd4: begin // J
                case(rotate)
                    2'd0: begin dx0=0;dy0=2; dx1=1;dy1=2; dx2=1;dy2=1; dx3=1;dy3=0; end
                    2'd1: begin dx0=0;dy0=0; dx1=0;dy1=1; dx2=1;dy2=1; dx3=2;dy3=1; end
                    2'd2: begin dx0=1;dy0=0; dx1=0;dy1=0; dx2=0;dy2=1; dx3=0;dy3=2; end
                    2'd3: begin dx0=2;dy0=2; dx1=2;dy1=1; dx2=1;dy2=1; dx3=0;dy3=1; end
                endcase
            end
            3'd5: begin // S
                case(rotate)
                    2'd0: begin dx0=0;dy0=2; dx1=1;dy1=2; dx2=1;dy2=1; dx3=2;dy3=1; end
                    2'd1: begin dx0=0;dy0=0; dx1=0;dy1=1; dx2=1;dy2=1; dx3=1;dy3=2; end
                    2'd2: begin dx0=0;dy0=2; dx1=1;dy1=2; dx2=1;dy2=1; dx3=2;dy3=1; end
                    2'd3: begin dx0=0;dy0=0; dx1=0;dy1=1; dx2=1;dy2=1; dx3=1;dy3=2; end
                endcase
            end
            3'd6: begin // Z
                case(rotate)
                    2'd0: begin dx0=0;dy0=1; dx1=1;dy1=1; dx2=1;dy2=2; dx3=2;dy3=2; end
                    2'd1: begin dx0=0;dy0=2; dx1=0;dy1=1; dx2=1;dy2=1; dx3=1;dy3=0; end
                    2'd2: begin dx0=0;dy0=1; dx1=1;dy1=1; dx2=1;dy2=2; dx3=2;dy3=2; end
                    2'd3: begin dx0=0;dy0=2; dx1=0;dy1=1; dx2=1;dy2=1; dx3=1;dy3=0; end
                endcase
            end
            default: begin
                dx0=0;dy0=0; dx1=0;dy1=0; dx2=0;dy2=0; dx3=0;dy3=0;
            end
        endcase
    end
    endtask

    function can_place;
        input signed [5:0] x, y;
        input [2:0] shape;
        input [1:0] rotate;
        reg signed [3:0] dx0,dy0,dx1,dy1,dx2,dy2,dx3,dy3;
        reg signed [5:0] cx,cy;
    begin
        case (shape)
            3'd0: begin // I
                case(rotate)
                    2'd0: begin dx0=0;dy0=0; dx1=0;dy1=1; dx2=0;dy2=2; dx3=0;dy3=3; end
                    2'd1: begin dx0=0;dy0=2; dx1=1;dy1=2; dx2=2;dy2=2; dx3=3;dy3=2; end
                    2'd2: begin dx0=0;dy0=0; dx1=0;dy1=1; dx2=0;dy2=2; dx3=0;dy3=3; end
                    2'd3: begin dx0=0;dy0=2; dx1=1;dy1=2; dx2=2;dy2=2; dx3=3;dy3=2; end
                endcase
            end
            3'd1: begin // O
                dx0=0;dy0=0; dx1=1;dy1=0; dx2=0;dy2=1; dx3=1;dy3=1;
            end
            3'd2: begin // T
                case(rotate)
                    2'd0: begin dx0=0;dy0=1; dx1=1;dy1=1; dx2=2;dy2=1; dx3=1;dy3=2; end
                    2'd1: begin dx0=1;dy0=0; dx1=1;dy1=1; dx2=1;dy2=2; dx3=0;dy3=1; end
                    2'd2: begin dx0=2;dy0=1; dx1=1;dy1=1; dx2=0;dy2=1; dx3=1;dy3=0; end
                    2'd3: begin dx0=0;dy0=2; dx1=0;dy1=1; dx2=0;dy2=0; dx3=1;dy3=1; end
                endcase
            end
            3'd3: begin // L
                case(rotate)
                    2'd0: begin dx0=0;dy0=0; dx1=0;dy1=1; dx2=0;dy2=2; dx3=1;dy3=2; end
                    2'd1: begin dx0=2;dy0=1; dx1=1;dy1=1; dx2=0;dy2=1; dx3=0;dy3=2; end
                    2'd2: begin dx0=1;dy0=2; dx1=1;dy1=1; dx2=1;dy2=0; dx3=0;dy3=0; end
                    2'd3: begin dx0=0;dy0=1; dx1=1;dy1=1; dx2=2;dy2=1; dx3=2;dy3=0; end
                endcase
            end
            3'd4: begin // J
                case(rotate)
                    2'd0: begin dx0=0;dy0=2; dx1=1;dy1=2; dx2=1;dy2=1; dx3=1;dy3=0; end
                    2'd1: begin dx0=0;dy0=0; dx1=0;dy1=1; dx2=1;dy2=1; dx3=2;dy3=1; end
                    2'd2: begin dx0=1;dy0=0; dx1=0;dy1=0; dx2=0;dy2=1; dx3=0;dy3=2; end
                    2'd3: begin dx0=2;dy0=2; dx1=2;dy1=1; dx2=1;dy2=1; dx3=0;dy3=1; end
                endcase
            end
            3'd5: begin // S
                case(rotate)
                    2'd0: begin dx0=0;dy0=2; dx1=1;dy1=2; dx2=1;dy2=1; dx3=2;dy3=1; end
                    2'd1: begin dx0=0;dy0=0; dx1=0;dy1=1; dx2=1;dy2=1; dx3=1;dy3=2; end
                    2'd2: begin dx0=0;dy0=2; dx1=1;dy1=2; dx2=1;dy2=1; dx3=2;dy3=1; end
                    2'd3: begin dx0=0;dy0=0; dx1=0;dy1=1; dx2=1;dy2=1; dx3=1;dy3=2; end
                endcase
            end
            3'd6: begin // Z
                case(rotate)
                    2'd0: begin dx0=0;dy0=1; dx1=1;dy1=1; dx2=1;dy2=2; dx3=2;dy3=2; end
                    2'd1: begin dx0=0;dy0=2; dx1=0;dy1=1; dx2=1;dy2=1; dx3=1;dy3=0; end
                    2'd2: begin dx0=0;dy0=1; dx1=1;dy1=1; dx2=1;dy2=2; dx3=2;dy3=2; end
                    2'd3: begin dx0=0;dy0=2; dx1=0;dy1=1; dx2=1;dy2=1; dx3=1;dy3=0; end
                endcase
            end
            default: begin
                dx0=0;dy0=0; dx1=0;dy1=0; dx2=0;dy2=0; dx3=0;dy3=0;
            end
        endcase

        can_place = 1;
        cx = x + dx0; cy = y + dy0;
        if (cx<0 || cx>=BOARD_W || cy>=BOARD_H) can_place = 0;
        else if (cy>=0 && board[cy][cx])        can_place = 0;

        cx = x + dx1; cy = y + dy1;
        if (cx<0 || cx>=BOARD_W || cy>=BOARD_H) can_place = 0;
        else if (cy>=0 && board[cy][cx])        can_place = 0;

        cx = x + dx2; cy = y + dy2;
        if (cx<0 || cx>=BOARD_W || cy>=BOARD_H) can_place = 0;
        else if (cy>=0 && board[cy][cx])        can_place = 0;

        cx = x + dx3; cy = y + dy3;
        if (cx<0 || cx>=BOARD_W || cy>=BOARD_H) can_place = 0;
        else if (cy>=0 && board[cy][cx])        can_place = 0;
    end
    endfunction

    function is_full_line;
        input integer yy;
        integer xx;
    begin
        is_full_line = 1;
        for (xx = 0; xx < BOARD_W; xx = xx + 1) begin
            if (!board[yy][xx])
                is_full_line = 0;
        end
    end
    endfunction

    task check_and_clear_lines;
        integer read_y, write_y;
        integer yy;
    begin
        o_line_cnt = 0;
        write_y = BOARD_H - 1;

        for (read_y = BOARD_H - 1; read_y >= 0; read_y = read_y - 1) begin
            if (is_full_line(read_y)) begin
                o_line_cnt = o_line_cnt + 1;
            end else begin
                if (write_y != read_y) begin
                    board[write_y] = board[read_y];
                end
                write_y = write_y - 1;
            end
        end

        for (yy = 0; yy >= 0; yy = yy - 1) begin
            if(yy <= write_y) board[yy] = board[yy];
            else board[yy] = {BOARD_W{1'b0}};
        end

        if (o_line_cnt != 0)
            o_line_full = 1;
    end
    endtask

    genvar gy;
    generate
        for (gy = 0; gy < BOARD_H; gy = gy + 1) begin : flat_loop
            assign o_board_bits[gy*BOARD_W +: BOARD_W] = board[gy];
        end
    endgenerate

    integer iy;
    reg [1:0] n_rotate;
    integer   n_x, n_y;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            for (iy=0; iy<BOARD_H; iy=iy+1)
                board[iy] = {BOARD_W{1'b0}};

            c_x = 0;
            c_y = 0;
            c_shape = 0; 
            c_rotate = 0;

            o_gameover = 0;
            o_lock = 0; 
            o_line_full = 0;
            o_line_cnt = 0;

        end else begin
            o_lock = 0;
            o_line_full = 0;
            o_line_cnt = 0;

            n_x = c_x;
            n_y = c_y;
            n_rotate = c_rotate;

            if (i_new_piece) begin
                c_shape = i_shape;
                c_rotate   = i_rotate;
                c_x     = i_x;
                c_y     = i_y;

                if (!can_place(i_x, i_y, i_shape, i_rotate))
                    o_gameover = 1;
            end
            else if (i_play_en && !o_gameover) begin

                if (i_move_left) begin
                    if (can_place(n_x - 1, n_y, c_shape, n_rotate))
                        n_x = n_x - 1;
                end
                else if (i_move_right) begin
                    if (can_place(n_x + 1, n_y, c_shape, n_rotate))
                        n_x = n_x + 1;
                end

                if (i_move_rotate) begin
                    if (can_place(n_x, n_y, c_shape, n_rotate + 1))
                        n_rotate = n_rotate + 1;
                end

                if (i_move_drop) begin
                    if (can_place(n_x, n_y + 1, c_shape, n_rotate)) begin
                        n_y = n_y + 1;
                    end 
                    else begin
                        o_lock = 1;
                        
                        begin : lock_logic
                            get_offsets(c_shape, n_rotate,
                                        ldx0, ldy0, ldx1, ldy1,
                                        ldx2, ldy2, ldx3, ldy3);

                            lcx=n_x+ldx0; lcy=n_y+ldy0; 
                            if(lcy>=0 && lcy<BOARD_H && lcx>=0 && lcx<BOARD_W)
                                board[lcy][lcx] = 1;

                            lcx=n_x+ldx1; lcy=n_y+ldy1; 
                            if(lcy>=0 && lcy<BOARD_H && lcx>=0 && lcx<BOARD_W)
                                board[lcy][lcx] = 1;

                            lcx=n_x+ldx2; lcy=n_y+ldy2; 
                            if(lcy>=0 && lcy<BOARD_H && lcx>=0 && lcx<BOARD_W)
                                board[lcy][lcx] = 1;

                            lcx=n_x+ldx3; lcy=n_y+ldy3; 
                            if(lcy>=0 && lcy<BOARD_H && lcx>=0 && lcx<BOARD_W)
                                board[lcy][lcx] = 1;
                                
                            check_and_clear_lines();
                        end
                    end
                end

                if (!o_lock) begin
                    c_x = n_x;
                    c_y = n_y;
                    c_rotate = n_rotate;
                end
            end
        end
    end

    always @* begin
        o_x     = c_x;
        o_y     = c_y;
        o_shape = c_shape;
        o_rotate   = c_rotate;
    end

endmodule 