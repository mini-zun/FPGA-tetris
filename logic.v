module logic #(
    parameter DROP_MAX = 24'd12500000
)(
    input        i_clk,
    input        i_rst,
    input        i_start,
    input        i_left,
    input        i_right,
    input        i_rotate,
    input        i_down,

    input        i_lock,
    input        i_line_full,
    input  [3:0] i_line_cnt, 
    input        i_gameover,

    output reg   o_new_piece,
    output reg   o_play_en,
    output reg   o_move_left,
    output reg   o_move_right,
    output reg   o_move_rotate,
    output reg   o_move_drop,

    output reg [2:0]  o_state,
    output reg [7:0] o_score
);

    // 상태 정의
    localparam IDLE        = 3'd0;
    localparam SPAWN       = 3'd1;
    localparam PLAY        = 3'd2;
    localparam LOCK        = 3'd3;
    localparam POINT       = 3'd4;
    localparam STOP         = 3'd5;
    localparam SPAWN_WAIT  = 3'd6;

    reg [2:0] c_state, n_state;

    reg c_left, c_right, c_rotate, c_down;
    reg n_left, n_right, n_rotate, n_down;
    wire fleft  = !i_left  & c_left;
    wire fright = !i_right & c_right;
    wire frotate   = !i_rotate& c_rotate;
    wire fdown  = !i_down & c_down;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            c_state = IDLE;
            c_left     = 0;
            c_right    = 0;
            c_rotate   = 0;
            c_down     = 0;
        end else begin
            c_left     = n_left;
            c_right    = n_right;
            c_rotate   = n_rotate;
            c_down     = n_down;
            c_state    = n_state;
        end
    end

    reg [23:0] drop_cnt;
    wire       drop_tick = (drop_cnt == DROP_MAX);

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            drop_cnt = 0;
        end else if (c_state == PLAY) begin
            if (drop_cnt == DROP_MAX)
                drop_cnt = 0;
            else
                drop_cnt = drop_cnt + 1;
        end else begin
            drop_cnt = 0;
        end
    end

    reg [3:0] ones, tens;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_score <= 8'h00;
        end else if (c_state == IDLE && i_start) begin
            o_score <= 8'h00;
        end else if (c_state == PLAY && i_lock && i_line_full) begin   //c_state == LOCK
            if (i_line_cnt) begin

                ones = o_score[3:0] + i_line_cnt;
                tens = o_score[7:4];

                if (ones >= 10) begin
                    ones = ones - 10;
                    tens = tens + 1;
                end

                o_score <= {tens, ones};
            end
        end
    end

    always @* begin
        n_state      = c_state;
        o_new_piece  = 0;
        o_play_en    = 0;
        o_move_left  = 0;
        o_move_right = 0;
        o_move_rotate   = 0;
        o_move_drop  = 0;
        n_left      = i_left;
        n_right     = i_right;
        n_rotate    = i_rotate;   
        n_down      = i_down;

        case (c_state)

            IDLE: begin
                if (i_start)
                    n_state = SPAWN;
            end

            SPAWN: begin
                o_new_piece = 1'b1; 
                n_state     = SPAWN_WAIT; 
            end

 
            SPAWN_WAIT: begin
                if (i_gameover)
                    n_state = STOP; 
                else
                    n_state = PLAY; 
            end

            PLAY: begin
                o_play_en    = 1;
                o_move_left  = fleft;
                o_move_right = fright;
                o_move_rotate   = frotate;
                o_move_drop  = fdown | drop_tick;

     
                if (i_gameover)
                    n_state = STOP;
                else if (i_lock)
                    n_state = SPAWN;     //n_state = LOCK;
            end


            LOCK: begin
                if (i_line_full)
                    n_state = POINT;
                else
                    n_state = SPAWN;
            end

            POINT: begin
                n_state = SPAWN;
            end

            STOP: begin
                if (!i_start)
                    n_state = IDLE;
            end

            default: n_state = IDLE;
        endcase
    end

    always @* begin
        o_state = c_state;
    end
endmodule