module Maze (CLOCK_50, KEY, SW, HEX0, HEX1,

// The ports below are for the VGA output.  Do not change.
VGA_CLK,   	// VGA Clock
 
VGA_HS, 	// VGA H_SYNC

VGA_VS,		// VGA V_SYNC

VGA_BLANK_N,	// VGA BLANK

VGA_SYNC_N, 	// VGA SYNC

VGA_R,    	// VGA Red[9:0]

VGA_G,		// VGA Green[9:0]

VGA_B    	// VGA Blue[9:0]

);

input CLOCK_50; 	// 50 MHz
input [3:0]KEY;
input [1:0]SW;

output VGA_CLK;    	// VGA Clock
output VGA_HS;	 	// VGA H_SYNC
output VGA_VS;	  	// VGA V_SYNC
output VGA_BLANK_N;    // VGA BLANK
output VGA_SYNC_N;     // VGA SYNC
output [9:0] VGA_R;    // VGA Red[9:0]
output [9:0] VGA_G;    // VGA Green[9:0]
output [9:0] VGA_B;    // VGA Blue[9:0]
output [6:0] HEX0;
output [6:0] HEX1;
 
wire [5:0]colour; 
wire [7:0] x_out;
wire [7:0] y_out;

wire writeEn;
wire start;
wire clock_pulse;
wire left, right, up, down;

assign start = SW[1];

control u0(
     .clk(CLOCK_50),
     .resetn(~SW[1]),
     .left(~KEY[3]), .right(~KEY[2]), .up(~KEY[1]), .down(~KEY[0]),
     .start(start),
  
     .x(x_out[7:0]),.y(y_out[7:0]),
     .c(colour[5:0]),			//this is the colour
     .enable(writeEn),
	  .LEFT(left),
	  .RIGHT(right),
	  .UP(up),
	  .DOWN(down)
 );

 vga_adapter VGA(

.resetn(~SW[0]),

.clock(CLOCK_50),

.colour(colour),

.x(x_out),

.y(y_out),

.plot(writeEn),


// Signals for the DAC to drive the monitor. 

.VGA_R(VGA_R),

.VGA_G(VGA_G),

.VGA_B(VGA_B),

.VGA_HS(VGA_HS),

.VGA_VS(VGA_VS),

.VGA_BLANK(VGA_BLANK_N),

.VGA_SYNC(VGA_SYNC_N),

.VGA_CLK(VGA_CLK));

defparam VGA.RESOLUTION = "160x120";

defparam VGA.MONOCHROME = "FALSE";

defparam VGA.BITS_PER_COLOUR_CHANNEL = 2;

defparam VGA.BACKGROUND_IMAGE = "maze_2.mif";

endmodule 

module control(
    input clk,
    input resetn,
    input left, right, up, down,
    input start,
	 
	 
	
    output reg [7:0]x,y,
    output reg [5:0]c,//this is the colour
    output reg enable,//enables the drawer
    output reg UP, DOWN, LEFT, RIGHT

    );
	 
	 
  wire Wdata, Wwren; 
  wire [5:0]BGcolour;
  wire [5:0]resetBG;
  assign Wdata = 1'b0;
  assign Wwren = 1'b0;
  wire[14:0]Waddress;
  reg [7:0]wirex;
  reg [6:0]wirey;
  assign Waddress = (wirey * 8'd160) + wirex; 
  
  
   reg endScreenEnable;
	reg bgEnable;
	reg StartEnable;
	wire [14:0]countOUT,countBG, countStart;
	wire [5:0] PGcolour, StartColour;
   wire [6:0]wy,wyBG, wyStart;
	wire [7:0]wx,wxBG, wxStart;
	
	   
	
	endScreenCounter c1(resetn, clk, endScreenEnable, wx, wy);
	 assign countOUT = (wy * 8'd160) + wx; 
	 endScreenCounter c2(resetn, clk, bgEnable, wxBG, wyBG);
	 assign countBG = (wyBG * 8'd160) + wxBG; 
	  endScreenCounter c3(resetn, clk, StartEnable, wxStart, wyStart);
	 assign countStart = (wyStart * 8'd160) + wxStart; 
	 
	 
	playagain pg(
	.data(0),
	.wren(0),
	.address(countOUT),
	.clock(clk),
	.q(PGcolour));
  
 image bg1(
	.data(0),
	.wren(0),
	.address(Waddress),
	.clock(clk),
	.q(BGcolour));

 image bg2(
	.data(0),
	.wren(0),
	.address(countBG),
	.clock(clk),
	.q(resetBG));	
	
	 start bg3(
	.data(0),
	.wren(0),
	.address(countStart),
	.clock(clk),
	.q(StartColour));	

    reg [6:0] current_state, next_state; 
    
    localparam  
		START_SCREEN   		= 6'd0,
	   	A_START     		= 6'd1,//The starting state
		DEL_WAIT		= 6'd2,//First Deleting State - Waiting for the negative edge of the keys
		RESET_SCREEN		= 6'd3,
		RESET_BG		= 6'd4,
		DEL_1			= 6'd5,//Second Deleting State - deletes the reference pixel
		DEL_2			= 6'd6,//Third Deleting State - deletes ref pixel + 1'b1 in the x direction
		DEL_3			= 6'd7,//Fourth Deleting State - deletes ref pixel + 1'b1 in the y direction
		DEL_4			= 6'd8,//Fifth Deleting State - deletes ref pixel - 1'b1 in the x direction
		DEL_ORIGINAL		= 6'd9,//Sixth Deleting State - return to reference pixel location

		LEFT_DRAW		= 6'd10,//Move Left State - move reference pixel -1'b1 in the x direction
		RIGHT_DRAW		= 6'd11,//Move Right State - move reference pixel 1'b1 in the x direction
		UP_DRAW			= 6'd12,//Move Up State - move reference pixel -1'b1 in the y direction
		DOWN_DRAW		= 6'd13,//Move Down State - move reference pixel 1'b1 in the y direction
		RESET_DRAW		= 6'd14,//Reset State - move back to starting location

		DRAW_TWO		= 6'd15,//Second Draw State - draw reference pixel + 1'b1 in the x direction
		DRAW_THREE		= 6'd16,//Third Draw State - draw reference pixel + 1'b1 in the y direction
		DRAW_FOUR		= 6'd17,//Fourth Draw State - draw reference pixel -1'b1 in the x direction
		DRAW_ORIGINAL		= 6'd18;//Fifth Draw State - return to the reference pixel location
      		
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
		case (current_state)
      
		START_SCREEN: begin
		if (left)
		next_state = RESET_BG;
		else 
		next_state = START_SCREEN;
		end
		
		A_START: begin
		if((y == 8'd114 || y == 8'd115) && (x == 8'd73 || x== 8'd74 || x== 8'd75|| x== 8'd76|| x== 8'd77|| x== 8'd78|| x== 8'd79 || x== 8'd80 )) begin
			next_state = RESET_SCREEN;
		end
		else if(left) begin
		wirex = x - 8'd1;
		wirey = y;
			next_state = DEL_WAIT;
		 //LEFT = 1'b1;
		end
		else if(right) begin
		 wirex = x + 8'd2;
		 wirey = y;
		 next_state = DEL_WAIT;
		 //RIGHT = 1'b1;
		end
		else if(up) begin
		wirex = x;
		wirey = y - 8'd1;
		 next_state = DEL_WAIT;
		 //UP = 1'b1;
		end
		else if(down) begin
		wirex = x;
		wirey = y + 8'd2  ;
		 next_state = DEL_WAIT;
		 //DOWN = 1'b1;
		end
		else 
		 next_state = A_START;
		end
	DEL_WAIT: begin
		if(left == 1'b0 && right == 1'b0 && up == 1'b0 && down == 1'b0) begin
			next_state = DEL_1;
		end
		
		end
	RESET_SCREEN: begin
	///////////////////////////////// PRESS KEY[3] TO EXIT END SCREEN /////////////////////////////
	if (left)
	next_state = RESET_BG;
	end
	RESET_BG: begin
	if(!left)
	next_state = DEL_1;
	end
	DEL_1: begin
		next_state = DEL_2;
		end
	DEL_2: begin
		next_state = DEL_3;
		end
	DEL_3: begin
		next_state = DEL_4;
		end
	DEL_4: begin
		next_state = DEL_ORIGINAL;
		end
	DEL_ORIGINAL: begin
		if(LEFT == 1'b1) begin
		 next_state = LEFT_DRAW;
		end
		else if(RIGHT == 1'b1) begin
		 next_state = RIGHT_DRAW;
		end
		else if(UP == 1'b1) begin
		 next_state = UP_DRAW;
		end
		
		else if(DOWN == 1'b1) begin
		 next_state = DOWN_DRAW;
		end
		else begin
		 next_state = RESET_DRAW;
		end
		end
	LEFT_DRAW: begin
		next_state = DRAW_TWO;
		end
	RIGHT_DRAW: begin
		next_state = DRAW_TWO;
		end
	UP_DRAW: begin
		next_state = DRAW_TWO;
		end
	DOWN_DRAW: begin
		next_state = DRAW_TWO;
		end
	RESET_DRAW: begin
		next_state = DRAW_TWO;
		end
	DRAW_TWO: begin
		next_state = DRAW_THREE;
		end
	DRAW_THREE: begin
		next_state = DRAW_FOUR;
		end
	DRAW_FOUR: begin
		next_state = DRAW_ORIGINAL;
		end
	DRAW_ORIGINAL: begin
		next_state = A_START;
		end			 
      default: next_state = A_START;
        endcase
    end // state_table

always @(posedge clk)
 begin: enable_signals
 case (current_state)
 
 
 START_SCREEN: begin
 
 StartEnable <= 1'b1;
 bgEnable <= 1'b0;
 endScreenEnable <= 1'b0;
 enable <= 1'b1;
 c[5:0] <= StartColour;
 x<=wxStart;
 y<=wyStart; 
 end


 A_START: begin
 if(start) begin
  x <= 8'd76;
  y <= 8'd29;
  c <= 6'b110000;
  enable <= 1'b0;
  LEFT <= 1'b0;
  RIGHT <= 1'b0;
  UP <= 1'b0;
  DOWN <= 1'b0;
 end
 
 else if(left) begin
   LEFT <= 1'b1;
   c[5:0] <= 6'b000000;//make the color black
   enable <= 1'b0;//dont want to draw anything
 end
 
 else if(right) begin
  RIGHT <= 1'b1;
  c[2:0] <= 3'b000;//make the color black
  enable <= 1'b0;//dont want to draw anything
 end
 
 else if(up) begin
  UP <= 1'b1;
  c[2:0] <= 3'b000;//make the color black
  enable <= 1'b0;//dont want to draw anything
 end
 
 else if(down) begin
  DOWN <= 1'b1;
  c[2:0] <= 3'b000;//make the color black
  enable <= 1'b0;//dont want to draw anything
 end 
 
 else begin
  c[2:0] <= 3'b000;//make the color black
  enable <= 1'b0;//dont want to draw anything
 end
 end
 
 DEL_WAIT: begin
	enable <= 1'b0;
 end
 
 RESET_SCREEN: begin
 /////////////////////////////////////////////////////////////////////////////////////
 endScreenEnable <= 1'b1;
 enable <= 1'b1;
 c[5:0] <=  PGcolour;
 x<=wx;
 y<=wy;
 end

 RESET_BG: begin

  endScreenEnable <= 0;
  bgEnable <= 1;
  enable <= 1'b1;
  c[5:0] <=  resetBG;
  x<=wxBG;
  y<=wyBG;
   
  end
  
 DEL_1: begin
 if (BGcolour != 6'b000000)
	  enable <= 1'b0;
  else  begin
  c[5:0] <= 6'b000000;
  enable <= 1'b1;

  end
 end

 DEL_2: begin
  x <= x + 1'b1;
 end

 DEL_3: begin
  y <= y + 1'b1;
 end

 DEL_4: begin
  x <= x - 1'b1;
 end

 DEL_ORIGINAL: begin
  y <= y - 1'b1;
  enable <= 1'b0;
 end

 UP_DRAW: begin
  if (BGcolour != 6'b000000) begin
	  enable <= 1'b0;
	  UP <= 1'b0;
	end
	
  else  begin
  y <= y - 1'b1;
  c[5:0] <= 6'b110000;
  enable <= 1'b1;
  UP <= 1'b0;
  end
 end

 DOWN_DRAW: begin
  if (BGcolour != 6'b000000) begin
	  enable <= 1'b0;
	   DOWN <= 1'b0;
	end
	
  else  begin
  y <= y + 1'b1;
  c[5:0] <= 6'b110000;
  enable <= 1'b1;
  DOWN <= 1'b0;
  end
 end
 
 RIGHT_DRAW: begin
  if (BGcolour != 6'b000000) begin
	  enable <= 1'b0;
	  RIGHT <= 1'b0;
	
end	
  else  begin
  x <= x + 1'b1;
  c[5:0] <= 6'b110000;
  enable <= 1'b1;
  RIGHT <= 1'b0;
  end
 end

 LEFT_DRAW: begin
  if (BGcolour != 6'b000000) begin
	  enable <= 1'b0;
	  LEFT <= 1'b0;
	end   
  else  begin
  x <= x - 1'b1;
  c[5:0] <= 6'b110000;
  enable <= 1'b1;
  LEFT <= 1'b0;
  end
 end
 
 RESET_DRAW: begin
  if (BGcolour != 6'b000000)
	  enable <= 1'b0;
  else  begin
	x <= 8'd76;
	y <= 8'd29;
	c[5:0] <= 6'b110000;
	enable <= 1'b1;
	end
 end

 DRAW_TWO: begin
  x <= x + 1'b1;
 end
 DRAW_THREE: begin
  y <= y + 1'b1;
 end
 DRAW_FOUR: begin
  x <= x - 1'b1;
 end

 DRAW_ORIGINAL: begin
  enable <= 1'b0;
  y <= y - 1'b1;
  c[5:0] = 6'b110000;
 end

default: begin
 enable <= 1'b0;
 x <= 8'd76;
  y <= 8'd29;
 c <= 3'b000;
 end
endcase
end // enable_signals
   
// current_state registers
always@(posedge clk)
begin: state_FFs
if(!resetn) begin
current_state <= START_SCREEN;
end

else
current_state <= next_state;

end // state_FFS
endmodule



module endScreenCounter (reset, clock, enable, x, y);
input reset, clock, enable;
output reg [7:0]x;
output reg [6:0]y;

always@(negedge reset, posedge clock) begin
if (!reset) begin
x<=0;
y<=0;
end

else if(x==8'd159) begin
	if(y==7'd119) begin
	y<=0;
	x<=0;
	end
	else begin
	y<=y+7'd1;
	x<=0;
	end
end

else
x<=x+8'd1;


end

endmodule







