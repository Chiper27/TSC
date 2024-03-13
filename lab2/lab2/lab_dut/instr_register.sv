	/***********************************************************************
	 * A SystemVerilog RTL model of an instruction regisgter
	 *
	 * An error can be injected into the design by invoking compilation with
	 * the option:  +define+FORCE_LOAD_ERROR
	 *
	 **********************************************************************/

	module instr_register
	import instr_register_pkg::*;  // user-defined types are defined in instr_register_pkg.sv
	(input  logic          clk,
	 input  logic          load_en,
	 input  logic          reset_n,
	 input  operand_t      operand_a,
	 input  operand_t      operand_b,
	 input  opcode_t       opcode,
	 input  address_t      write_pointer,
	 input  address_t      read_pointer,
	 output instruction_t  instruction_word
  ); 
	  timeunit 1ns/1ns;

	  instruction_t  iw_reg [0:31];  // an array of instruction_word structures

	  // write to the register
	  always@(posedge clk, negedge reset_n)   // write into register 
		if (!reset_n) begin
		  foreach (iw_reg[i])
			iw_reg[i] = '{opc:ZERO,default:0};  // reset to all zeros 
		end
		else if (load_en) begin 
		  case (opcode)
				ZERO: iw_reg[write_pointer] = '{opcode,operand_a,operand_b, 0}; //rezultatul este setat la 0
				PASSA: iw_reg[write_pointer] = '{opcode,operand_a,operand_b, operand_a}; //rezultatul este operandul A
				PASSB: iw_reg[write_pointer] = '{opcode,operand_a,operand_b, operand_b};//rezultatul este operandul B
				ADD: iw_reg[write_pointer] = '{opcode,operand_a,operand_b, operand_a + operand_b};
				SUB: iw_reg[write_pointer] = '{opcode,operand_a,operand_b, operand_a - operand_b};
				MULT: iw_reg[write_pointer] = '{opcode,operand_a,operand_b, operand_a * operand_b};
				DIV:
					if(!operand_b )
						iw_reg[write_pointer] ='{opcode,operand_a,operand_b, 0};
					else
						iw_reg[write_pointer] = '{opcode,operand_a,operand_b, operand_a / operand_b};
				MOD: iw_reg[write_pointer] = '{opcode,operand_a,operand_b, operand_a % operand_b};  
		  endcase 
		end

	  // read from the register
	  assign instruction_word = iw_reg[read_pointer];  // continuously read from register

	// compile with +define+FORCE_LOAD_ERROR to inject a functional bug for verification to catch
	`ifdef FORCE_LOAD_ERROR
	initial begin
	  force operand_b = operand_a; // cause wrong value to be loaded into operand_b
	end
	`endif

	endmodule: instr_register