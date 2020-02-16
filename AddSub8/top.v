module Top(input CLK,
            input PIN_14, // Button CLk
            input PIN_16, // Button select add or subtract
            input PIN_17, // Switch MSB PIN_17, PIN_18, PIN_19, PIN_20, PIN_21, PIN_22, PIN_23, PIN_24
            input PIN_18,
            input PIN_19,
            input PIN_20,
            input PIN_21,
            input PIN_22,
            input PIN_23,
            input PIN_24,
            output reg PIN_9, // Sum LEDs MSB PIN_1, PIN_2, PIN_3, PIN_4, PIN_5, PIN_6, PIN_7, PIN_8, PIN_9
            output reg PIN_8,
            output reg PIN_7,
            output reg PIN_6,
            output reg PIN_5,
            output reg PIN_4,
            output reg PIN_3,
            output reg PIN_2,
            output reg PIN_1,
            output reg PIN_15, // Displays if ADDING or SUBTRACTING (HIGH when ADDING)
);

            localparam  WIDTH = 8;

            wire [WIDTH-1:0] a = {~PIN_17, ~PIN_18, ~PIN_19, ~PIN_20, ~PIN_21, ~PIN_22, ~PIN_23, ~PIN_24};
            wire [WIDTH-1:0] aNot;
            wire [WIDTH-1:0] twosComp;
            wire [WIDTH-1:0] b;
            wire [WIDTH:0] sum;
            wire muxSel;
            wire [WIDTH:0]muxOut;
            wire pushDB;

            reg [WIDTH-1:0] plusOne = 8'b00000001;
            reg selAddSub = 1'b0;
            reg pushClk = PIN_14;
            reg pushAddSub = PIN_16;

  DeBounce DeBounce_2(CLK, pushAddSub, pushDB);
  Reg1 Reg1_1(CLK, selAddSub, muxSel, pushAddSub); // save value of +- select
  Ripple Ripple_1(~a, plusOne, twosComp); // convert to twos compliments
  RegWidth RegWidth_1(CLK, a, b, pushClk); // store twos compliment
  Ripple Ripple_2(b, muxOut, sum); // adds the stored twos compliment and the value from the switches

  always @(posedge pushDB)
  begin
    selAddSub <= ~selAddSub;
  end

  assign muxOut = muxSel ? twosComp : a;
  assign {PIN_9, PIN_8, PIN_7, PIN_6, PIN_5, PIN_4, PIN_3, PIN_2, PIN_1} = sum;
  assign PIN_15 = ~muxSel;

endmodule // Top


module Reg1 (
  input CLK,
  input  i,
  output reg o,
  input pshClk, // FROM SWITCH
);

  wire pushB; // push button for clock emulation

  DeBounce DeBounce_1(CLK, pshClk, pushB);

	always @(posedge pushB)
	begin
  	o <= i;
	end

endmodule // Reg1


module RegWidth #(parameter WIDTH=8) (
  input CLK,
  input [WIDTH-1:0] i,
  output reg [WIDTH-1:0] o,
  input pshClk, // FROM SWITCH
);

  wire pushB; // push button for clock emulation

  DeBounce DeBounce_1(CLK, pshClk, pushB);

	always @(posedge pushB)
	begin
  	o <= i;
	end

endmodule // RegWidth


module DeBounce(
  input CLK,
  input i,
  output o,
);
    parameter cDebounceLimit = 19000; // 10ns at 19MHz

    reg pushB = 1'b0;
    reg [15:0] count = 0; // 2^15 = 32768

  always @(posedge CLK)
  begin
     if (i !== pushB && count < cDebounceLimit)
       //start counting
       count <= count + 1;
     else if (count == cDebounceLimit)
       begin
         pushB <= i;
         count <= 0;
       end
     else
       count <= 0;
   end

   assign o = pushB;

endmodule // DeBounce


module Ripple #(parameter WIDTH=8) (
   input [WIDTH-1:0]  i_add_term1,
   input [WIDTH-1:0]  i_add_term2,
   output [WIDTH:0] o_result,
);

  wire [WIDTH:0]    w_CARRY;
  wire [WIDTH-1:0]    w_SUM;

  // No carry input on first full adder
  assign w_CARRY[0] = 1'b0;

  genvar i;
  for (i = 0; i < WIDTH; i = i + 1)
  begin
    FullAdder FullAdder_1
    (
      .i_bit1(i_add_term1[i]),
      .i_bit2(i_add_term2[i]),
      .i_carry(w_CARRY[i]),
      .o_sum(w_SUM[i]),
      .o_carry(w_CARRY[i+1])
    );
  end

  assign o_result = {w_CARRY[WIDTH], w_SUM};   // Verilog Concatenation

endmodule // Ripple

module FullAdder (
   input i_bit1,
   input i_bit2,
   input i_carry,
   output o_sum,
   output o_carry,
);

  wire   w_WIRE_1 = i_bit1 ^ i_bit2;
  wire   w_WIRE_2 = w_WIRE_1 & i_carry;
  wire   w_WIRE_3 = i_bit1 & i_bit2;

  assign o_sum   = w_WIRE_1 ^ i_carry;
  assign o_carry = w_WIRE_2 | w_WIRE_3;

endmodule // FullAdder
