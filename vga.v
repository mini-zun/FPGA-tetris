`include "tetris_defines.v"

module vga #(
    parameter BOARD_W = `BOARD_W,
    parameter BOARD_H = `BOARD_H
)(
    input        i_clk,
    input        i_rst,
    input [BOARD_W*BOARD_H-1:0] i_board_bits,
    input [4:0]  i_x,
    input [4:0]  i_y,
    input [2:0]  i_shape,
    input [1:0]  i_rot,
    input [2:0]  i_state,
    input [7:0]  i_score,
    input        i_gameover,

    output [7:0] o_VGA_R,
    output [7:0] o_VGA_G,
    output [7:0] o_VGA_B,
    output       o_VGA_HS,
    output       o_VGA_VS,
    output       o_VGA_CLK,
    output       o_VGA_BLANK_N,
    output       o_VGA_SYNC_N
);

    localparam H_ACTIVE=640, H_FRONT=16, H_SYNC=96, H_BACK=48, H_TOTAL=800;
    localparam V_ACTIVE=480, V_FRONT=10, V_SYNC=2,  V_BACK=33, V_TOTAL=525;

    reg [9:0] h_cnt, v_cnt;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            h_cnt<=0; v_cnt<=0;
        end else begin
            if (h_cnt < H_TOTAL-1)
                h_cnt <= h_cnt + 1;
            else begin
                h_cnt <= 0;
                if (v_cnt < V_TOTAL-1)
                    v_cnt <= v_cnt + 1;
                else
                    v_cnt <= 0;
            end
        end
    end

    assign o_VGA_HS =
        ~((h_cnt >= (H_ACTIVE+H_FRONT)) &&
          (h_cnt <  (H_ACTIVE+H_FRONT+H_SYNC)));

    assign o_VGA_VS =
        ~((v_cnt >= (V_ACTIVE+V_FRONT)) &&
          (v_cnt <  (V_ACTIVE+V_FRONT+V_SYNC)));

    assign o_VGA_CLK     = i_clk;
    assign o_VGA_SYNC_N  = 1'b0;

    wire video_on = (h_cnt < H_ACTIVE && v_cnt < V_ACTIVE);
    assign o_VGA_BLANK_N = video_on;

    wire [9:0] pix_x = h_cnt;
    wire [9:0] pix_y = v_cnt;


    localparam CELL_SZ = 16;

    localparam FIELD_W_PIX = BOARD_W * CELL_SZ;
    localparam FIELD_H_PIX = BOARD_H * CELL_SZ;

    localparam FIELD_X0 = 160;
    localparam FIELD_Y0 = 40;

    wire in_field =
        (pix_x >= FIELD_X0) && (pix_x < FIELD_X0+FIELD_W_PIX) &&
        (pix_y >= FIELD_Y0) && (pix_y < FIELD_Y0+FIELD_H_PIX);

    wire [4:0] cell_x = (pix_x - FIELD_X0)/CELL_SZ;
    wire [4:0] cell_y = (pix_y - FIELD_Y0)/CELL_SZ;

    wire board_filled =
        in_field ? i_board_bits[cell_y*BOARD_W + cell_x] : 1'b0;

    wire cur_block_here =
        in_field && (i_state==3'b010) &&
        is_cur_block_cell(cell_x, cell_y,
            i_x, i_y, i_shape, i_rot);


    localparam CHAR_SZ = 18;
    localparam LOGO_W  = 6 * CHAR_SZ;   // 108
    localparam LOGO_H  = CHAR_SZ;       // 18

    localparam BOARD_CENTER_X = FIELD_X0 + (FIELD_W_PIX/2);
    localparam BOARD_CENTER_Y = FIELD_Y0 + (FIELD_H_PIX/2);

    localparam LOGO_X0 = BOARD_CENTER_X - (LOGO_W/2);
    localparam LOGO_Y0 = BOARD_CENTER_Y - (LOGO_H/2);

    wire in_logo =
        (pix_x >= LOGO_X0) && (pix_x < LOGO_X0 + LOGO_W) &&
        (pix_y >= LOGO_Y0) && (pix_y < LOGO_Y0 + LOGO_H);

    wire [7:0] lx = in_logo ? (pix_x - LOGO_X0) : 8'd0;
    wire [4:0] ly = in_logo ? (pix_y - LOGO_Y0) : 5'd0;

    wire [2:0] letter_index =
        in_logo ? ((lx / CHAR_SZ) > 5 ? 3'd5 : (lx / CHAR_SZ)) : 3'd0;

    wire [4:0] px = lx % CHAR_SZ;
    wire [4:0] py = ly;

    wire logo_pixel =
        (i_state==3'b000) && in_logo &&
        font_pixel_on(letter_index, px, py);

    reg [7:0] r,g,b;

    always @* begin
        r=40; g=40; b=40;

        if (i_gameover) begin
            r=255; g=0; b=0;
        end
        else begin
            if (logo_pixel)
                {r,g,b} = {8'd255,8'd255,8'd0};

            if (in_field) begin
                {r,g,b} = {8'd0,8'd0,8'd0};

                if (board_filled)
                    {r,g,b} = {8'd0,8'd180,8'd90};
                if (cur_block_here)
                    {r,g,b} = {8'd255,8'd255,8'd0};
                if (logo_pixel)
                    {r,g,b} = {8'd255,8'd255,8'd0};
            end
        end
    end

    assign o_VGA_R = video_on ? r : 0;
    assign o_VGA_G = video_on ? g : 0;
    assign o_VGA_B = video_on ? b : 0;

    function is_cur_block_cell;
        input [4:0] cx,cy;
        input [4:0] bx,by;
        input [2:0] shape;
        input [1:0] rotate;

        reg signed [3:0] dx0,dy0,dx1,dy1,dx2,dy2,dx3,dy3;
    begin
        dx0=0;dy0=0; dx1=0;dy1=0; dx2=0;dy2=0; dx3=0;dy3=0;

        case (shape)
            3'd0: begin // I
                case(rotate)
                    2'd0: begin dx0=0;dy0=0; dx1=0;dy1=1; dx2=0;dy2=2; dx3=0;dy3=3; end
                    2'd1: begin dx0=0;dy0=2; dx1=1;dy1=2; dx2=2;dy2=2; dx3=3;dy3=2; end
                    2'd2: begin dx0=3;dy0=3; dx1=3;dy1=2; dx2=3;dy2=1; dx3=3;dy3=0; end
                    2'd3: begin dx0=3;dy0=1; dx1=2;dy1=1; dx2=1;dy2=1; dx3=0;dy3=1; end
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
        // -----------------------------------------

        is_cur_block_cell =
            ((cx==bx+dx0)&&(cy==by+dy0)) ||
            ((cx==bx+dx1)&&(cy==by+dy1)) ||
            ((cx==bx+dx2)&&(cy==by+dy2)) ||
            ((cx==bx+dx3)&&(cy==by+dy3));
    end
    endfunction

    function font_pixel_on;
        input [2:0] ch;
        input [4:0] x,y;
    begin
        case (ch)
            3'd0: font_pixel_on = font_T(x,y);
            3'd1: font_pixel_on = font_E(x,y);
            3'd2: font_pixel_on = font_T(x,y);
            3'd3: font_pixel_on = font_R(x,y);
            3'd4: font_pixel_on = font_I(x,y);
            3'd5: font_pixel_on = font_S(x,y);
            default: font_pixel_on = 0;
        endcase
    end
    endfunction

    function font_T;
        input [4:0] x,y;
    begin
        if (y<3) font_T=1;
        else if (x>=7 && x<=10) font_T=1;
        else font_T=0;
    end
    endfunction

    function font_E;
        input [4:0] x,y;
    begin
        if (x<=2) font_E=1;
        else if (y<3) font_E=1;
        else if (y>=7 && y<=9) font_E=1;
        else if (y>=14) font_E=1;
        else font_E=0;
    end
    endfunction

    function font_R;
        input [4:0] x,y;
    begin
        if (x<=2) font_R=1;
        else if (y<3) font_R=1;
        else if (y>=7 && y<=9) font_R=1;
        else if ((x>=14)&&(y>=3 && y<=6)) font_R=1;
        else if ((y>=10)&&(x==(y-7))) font_R=1;
        else font_R=0;
    end
    endfunction

    function font_I;
        input [4:0] x,y;
    begin
        if (y<3) font_I=1;
        else if (y>=14) font_I=1;
        else if (x>=7 && x<=10) font_I=1;
        else font_I=0;
    end
    endfunction

    function font_S;
        input [4:0] x,y;
    begin
        if (y<3) font_S=1;
        else if (y>=7 && y<=9) font_S=1;
        else if (y>=14) font_S=1;
        else if ((x<=2)&&(y>=3 && y<=6)) font_S=1;
        else if ((x>=15)&&(y>=10 && y<=13)) font_S=1;
        else font_S=0;
    end
    endfunction

endmodule