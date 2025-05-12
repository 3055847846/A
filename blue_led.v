module blue_led(
input wire sys_clk,
input wire rst_n,
input wire ble_rxd,
output wire [7:0] led_data,
output wire [5:0] led_sel,
output wire o_bleth_at
);

  //----Code starts here: integrated by Robei-----
  
    wire [7:0] blueteeth1_rdata;
    wire blueteeth1_rx_sig;
  assign o_bleth_at = 1'b1 ;
  
  
//---Module instantiation---
  blueteeth blueteeth1(
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .ble_rxd(ble_rxd),
    .rdata(blueteeth1_rdata),
    .rx_sig(blueteeth1_rx_sig)
);

  seg_led seg_led2(
    .rdata(blueteeth1_rdata),
    .led_data(led_data),
    .led_sel(led_sel),
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .rx_sig(blueteeth1_rx_sig)
);

endmodule    //blue_led
