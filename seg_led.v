module seg_led(
input wire [7:0] rdata,
output reg [7:0] led_data,
output wire [5:0] led_sel,
input wire sys_clk,
input wire rst_n,
input wire rx_sig
);

  //----Code starts here: integrated by Robei-----
  always@(posedge sys_clk or negedge rst_n)begin
  	if(!rst_n)
  		led_data <= 8'b1100_0000;
  	else if(rx_sig)
  		case(rdata)
  			8'h00:led_data <= 8'b1100_0000;
  			8'h01:led_data <= 8'b1111_1001;
  			8'h02:led_data <= 8'b1010_0100;
  			8'h03:led_data <= 8'b1011_0000;
  			8'h04:led_data <= 8'b1001_1001;
  			8'h05:led_data <= 8'b1001_0010;
  			8'h06:led_data <= 8'b1000_0010;
  			8'h07:led_data <= 8'b1111_1000;
  			8'h08:led_data <= 8'b1000_0000;
  			8'h09:led_data <= 8'b1001_0000;
  			8'h10:led_data <= 8'b1000_1000;
  			8'h11:led_data <= 8'b1000_0011;
  			8'h12:led_data <= 8'b1100_0110;
  			8'h13:led_data <= 8'b1000_0011;
  			8'h14:led_data <= 8'b1010_0001;
  			8'h15:led_data <= 8'b1100_1010;
  			default:led_data <= 8'b1011_1110;
  		endcase
        else
      	led_data <= led_data;
  end
  
  assign led_sel = 6'b011111;
  
endmodule    //seg_led
