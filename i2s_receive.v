`timescale 1ns/1ns
module i2s_receive #
  (
   parameter DATA_WIDTH = 32
   )
  (
   input M_AXIS_ACLK,
   input M_AXIS_ARESETN,
   output reg  M_AXIS_TVALID,
   output reg [DATA_WIDTH-1 : 0] M_AXIS_TDATA,
   output reg  M_AXIS_TLAST,
   input wire  M_AXIS_TREADY,
   
   input sck,
   input ws,
   input sd
   );

  reg [1:0] sck_sync;
  always @(posedge M_AXIS_ACLK)
    sck_sync <= {sck_sync,sck};
  wire sck_rise = sck_sync == 2'b01;
  wire sck_fall = sck_sync == 2'b10;

  reg wsd = 0;
  always @(posedge M_AXIS_ACLK)
    if (sck_rise)
      wsd <= ws;

  reg wsdd;
  always @(posedge M_AXIS_ACLK)
    if (sck_rise)
      wsdd <= wsd;

  wire wsp = wsd ^ wsdd;

  reg [$clog2(DATA_WIDTH+1)-1:0] counter;
  always @(posedge M_AXIS_ACLK)
    if (sck_fall)
      if (wsp)
	counter <= 0;
      else if (counter < DATA_WIDTH)
	counter <= counter+1;

  reg [0:DATA_WIDTH-1] shift;
  always @(posedge M_AXIS_ACLK)
    if (sck_rise)
      begin
	if (wsp)
	  shift <= 0;
	if (counter < DATA_WIDTH)
	  shift[counter] <= sd;
      end

  always @(posedge M_AXIS_ACLK)
    if (sck_rise && wsp)
      M_AXIS_TDATA <= shift;

  always @(posedge M_AXIS_ACLK)
    if (!M_AXIS_ARESETN)
      M_AXIS_TVALID <= 0;
    else if (sck_rise && wsp)
      M_AXIS_TVALID <= 1;
    else if (M_AXIS_TREADY)
      M_AXIS_TVALID <= 0;

  always @(posedge M_AXIS_ACLK)
    if (sck_rise && wsp)
      M_AXIS_TLAST <= !wsd;

endmodule