`default_nettype none

module tt_um_vga_example (
    input wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input wire ena,
    input wire clk,
    input wire rst_n
);

    // VGA position
    reg [9:0] hpos;
    reg [9:0] vpos;

    wire hsync;
    wire vsync;
    wire video_active;

    assign hsync = !(hpos >= 656 && hpos < 752);
    assign vsync = !(vpos >= 490 && vpos < 492);
    assign video_active = (hpos < 640 && vpos < 480);

    // VGA Counter
    always @(posedge clk) begin
        if (!rst_n) begin
            hpos <= 0;
            vpos <= 0;
        end
        else begin
            if (hpos == 799) begin
                hpos <= 0;

                if (vpos == 524)
                    vpos <= 0;
                else
                    vpos <= vpos + 1;
            end
            else
                hpos <= hpos + 1;
        end
    end

    // Update game once per frame
    wire frame;
    assign frame = (hpos == 799 && vpos == 524);

    // Frog position
    reg [9:0] frog_x;
    reg [9:0] frog_y;

    // Car positions
    reg [9:0] car1_x;
    reg [9:0] car2_x;
    reg [9:0] car3_x;
    reg [9:0] car4_x;

    // Game State
    reg game_over;
    reg win;

    // Collision Detection
    wire hit1, hit2, hit3, hit4;

    assign hit1 = frog_x < car1_x + 80 &&
                  frog_x + 20 > car1_x &&
                  frog_y < 140 &&
                  frog_y + 20 > 100;

    assign hit2 = frog_x < car2_x + 80 &&
                  frog_x + 20 > car2_x &&
                  frog_y < 220 &&
                  frog_y + 20 > 180;

    assign hit3 = frog_x < car3_x + 80 &&
                  frog_x + 20 > car3_x &&
                  frog_y < 300 &&
                  frog_y + 20 > 260;

    assign hit4 = frog_x < car4_x + 80 &&
                  frog_x + 20 > car4_x &&
                  frog_y < 380 &&
                  frog_y + 20 > 340;

    // Game Logic
    always @(posedge clk) begin
        if (!rst_n || ui_in[4]) begin
            frog_x <= 310;
            frog_y <= 440;

            car1_x <= 0;
            car2_x <= 500;
            car3_x <= 200;
            car4_x <= 400;

            game_over <= 0;
            win <= 0;
        end

        else if (frame && !game_over && !win) begin

            if (hit1 || hit2 || hit3 || hit4)
                game_over <= 1;

            else if (frog_y <= 40)
                win <= 1;

            else begin

                
                if (ui_in[0] && frog_y >= 4)
                    frog_y <= frog_y - 4;

                else if (ui_in[1] && frog_y <= 456)
                    frog_y <= frog_y + 4;

                if (ui_in[2] && frog_x >= 4)
                    frog_x <= frog_x - 4;

                else if (ui_in[3] && frog_x <= 616)
                    frog_x <= frog_x + 4;

                if (car1_x >= 640)
                    car1_x <= 0;
                else
                    car1_x <= car1_x + 3;

                if (car2_x <= 4)
                    car2_x <= 640;
                else
                    car2_x <= car2_x - 4;

               
                if (car3_x >= 640)
                    car3_x <= 0;
                else
                    car3_x <= car3_x + 5;

                if (car4_x <= 3)
                    car4_x <= 640;
                else
                    car4_x <= car4_x - 3;

            end
        end
    end

    reg [1:0] R;
    reg [1:0] G;
    reg [1:0] B;

    // Draw Game
    always @(*) begin

        R = 0;
        G = 0;
        B = 0;

        if (video_active) begin

           
            if (game_over) begin
                R = 3;
            end

            
            else if (win) begin
                G = 3;
            end

            
            else if (hpos >= frog_x &&
                     hpos < frog_x + 20 &&
                     vpos >= frog_y &&
                     vpos < frog_y + 20) begin
                G = 3;
            end

            
            else if (hpos >= car1_x &&
                     hpos < car1_x + 80 &&
                     vpos >= 100 && vpos < 140) begin
                R = 3;
            end

            else if (hpos >= car2_x &&
                     hpos < car2_x + 80 &&
                     vpos >= 180 && vpos < 220) begin
                B = 3;
            end

            
            else if (hpos >= car3_x &&
                     hpos < car3_x + 80 &&
                     vpos >= 260 && vpos < 300) begin
                R = 3;
                G = 3;
            end

           
            else if (hpos >= car4_x &&
                     hpos < car4_x + 80 &&
                     vpos >= 340 && vpos < 380) begin
                R = 3;
                B = 3;
            end

            
            else if (vpos < 80 || vpos >= 400) begin
                G = 1;
            end

           
            else if ((vpos == 80 ||
                      vpos == 160 ||
                      vpos == 240 ||
                      vpos == 320 ||
                      vpos == 399) &&
                      hpos[5] == 1) begin
                R = 3;
                G = 3;
                B = 3;
            end

           
            else begin
                R = 1;
                G = 1;
                B = 1;
            end

        end
    end

   
    assign uo_out = {
        hsync, B[0], G[0], R[0],
        vsync, B[1], G[1], R[1]
    };

    assign uio_out = 8'b00000000;
    assign uio_oe = 8'b00000000;

endmodule