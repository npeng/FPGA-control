`timescale 1ns / 1ps

module Final_Project(ClkPort, vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b, Sw0, Sw1, btnU, btnD,
	St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar,
	An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7);
	
	input ClkPort, Sw0, btnU, btnD, Sw0, Sw1;
	output St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar;
	output vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b;
	output An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp;
	output LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	reg vga_r, vga_g, vga_b;

	/*  LOCAL SIGNALS */
	wire	reset, start, ClkPort, board_clk, clk, button_clk;
	
	BUF BUF1 (board_clk, ClkPort); 	
	BUF BUF2 (reset, Sw0);
	BUF BUF3 (start, Sw1);
	
	reg [27:0]	DIV_CLK;
	always @ (posedge board_clk, posedge reset)  
	begin : CLOCK_DIVIDER
      if (reset)
			DIV_CLK <= 0;
      else
			DIV_CLK <= DIV_CLK + 1'b1;
	end

	assign	button_clk = DIV_CLK[18];
	assign	clk = DIV_CLK[1];
	assign 	{St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar} = {5'b11111};
	
	wire inDisplayArea;
	wire [9:0] CounterX;
	wire [9:0] CounterY;	
	
	
	hvsync_generator syncgen(.clk(clk), .reset(reset),.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));
	
	/////////////////////////////////////////////////////////////////
	///////////////		VGA control starts here		/////////////////
	/////////////////////////////////////////////////////////////////
	reg [9:0] X_me;
	reg [9:0] Y_me;
	wire border = (CounterX[9:3]==0) || (CounterX[9:3]==99) || (CounterY[9:3]==0) || (CounterY[9:3]==99);
	wire R = border;
	wire G = border;
	wire B = border;
	
	wire player = (CounterX>=X_me+10) && (CounterX<=X_me+110) && (CounterY>=Y_me+10) & (CounterY<=Y_me+110);
	wire enemy;
	wire bullet;
	wire collision;
	
	
	always @(posedge DIV_CLK[21])
		begin
			if(reset)
			begin
				X_me <= 25;
				Y_me <= 25;
			end
			else if(btnD && ~btnU)
				Y_me <= Y_me + 5;
			else if(btnU && ~btnD)
				Y_me <= Y_me - 5;
			else if (btnL && ~btnR)
				X_me <= X_me - 5;
			else if (btnR && ~btnL)
				X_me <= X_me + 5;
		end
		
	
	wire R = 0;
	wire G = CounterX>100 && CounterX<200 && CounterY[5:3]==7;
	wire B = CounterY>=(Player_position-10) && CounterY<=(Player_position+10) && CounterX[8:5]==7;
	
	always @(posedge clk)
	begin
		vga_r <= R & inDisplayArea;
		vga_g <= G & inDisplayArea;
		vga_b <= B & inDisplayArea;
	end
	
	///////////////////////////////////////////////////////////////////////////////////////
	
/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	reg 	[3:0]	SSD;
	wire 	[3:0]	SSD0, SSD1, SSD2, SSD3;
	wire 	[1:0] ssdscan_clk;
	
	assign SSD3 = 4'b1111;
	assign SSD2 = 4'b1111;
	assign SSD1 = 4'b1111;
	assign SSD0 = position[3:0];
	
	// need a scan clk for the seven segment display 
	// 191Hz (50MHz / 2^18) works well
	assign ssdscan_clk = DIV_CLK[19:18];	
	assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	= !( (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	= !( (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
			2'b00:
					SSD = SSD0;
			2'b01:
					SSD = SSD1;
			2'b10:
					SSD = SSD2;
			2'b11:
					SSD = SSD3;
		endcase 
	end	

	// and finally convert SSD_num to ssd
	reg [6:0]  SSD_CATHODES;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES, 1'b1};
	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD)		
			4'b1111: SSD_CATHODES = 7'b1111111 ; //Nothing 
			4'b0000: SSD_CATHODES = 7'b0000001 ; //0
			4'b0001: SSD_CATHODES = 7'b1001111 ; //1
			4'b0010: SSD_CATHODES = 7'b0010010 ; //2
			4'b0011: SSD_CATHODES = 7'b0000110 ; //3
			4'b0100: SSD_CATHODES = 7'b1001100 ; //4
			4'b0101: SSD_CATHODES = 7'b0100100 ; //5
			4'b0110: SSD_CATHODES = 7'b0100000 ; //6
			4'b0111: SSD_CATHODES = 7'b0001111 ; //7
			4'b1000: SSD_CATHODES = 7'b0000000 ; //8
			4'b1001: SSD_CATHODES = 7'b0000100 ; //9
			4'b1010: SSD_CATHODES = 7'b0001000 ; //10 or A
			default: SSD_CATHODES = 7'bXXXXXXX ; // default is not needed as we covered all cases
		endcase
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	
	reg [4:0] X_me;
	reg [4:0] Y_me;
	reg [4:0] X_enemy;
	reg [4:0] Y_enemy;
	
	reg [4:0] bullet_X;
	reg [4:0] bullet_y;
	reg [2:0] life;
	
	always @ (posedge Clk, posedge Reset)
	begin
		if (Reset)
		begin
			state <= I;
			position <= 500;
			X_me <= Xinital;
			Y_me <= Yinitial;
			X_enemy <= ($random % 10); //random position? or set starting position
			Y_enemy <= ($random % 10); 
			
			
		end
		
		else
			case (state)
				I:
				begin
				
				if (start)
				state <= MOVEMENT;
				
				
				X_me <= Xinitial;
				Y_me <= Yinitial;
				X_enemy <= Xrand;
				Y_enemy <= Yrand;
				
				
				end
				
				
				
				MOVEMENT:
				begin
				
				
				if (X_me == X_enemy || Y_me == Y_enemy)
				begin
					life <= life - 1;
					if (life <= 0)
						state <= GAME_OVER;
					else
						state <= I;
				end
				
				
				
				end
				
				TIME_DELAY:
				begin
				
				
				
				
				
				end
				
				BULLET:
				begin
				//depending on direction facing, bullet moves in that direction
				bullet_X <= 
				bullet_Y <= 
				
				if (bullet_X == X_enemy || bullet_Y == Y_enemy)
				//enemy disappears and respawns elsewhere
				//increment points/kills
				
				
				end
				
				DRAW:
				begin
				
				
				
				
				end
				
				DISPLAY:
				begin
				
				
				
				
				end
				
				GAME_OVER:
				begin
				
				//print "GAME OVER" and wait for center button to restart
				
				
				if (btnC)
				state <= I;
				
				
				end
			
			
				
				
				
			
			

		
	
endmodule