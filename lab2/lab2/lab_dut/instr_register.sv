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
    end// ' se refere ca e indiferent de numarul de biti
    else if (load_en) begin//daca am loand_en in incarc valorile a si b in array
    //trebuie pus un switch care daca opcode e add facem adunare si le stocam intr-o variabila noua , trebuie sa vedem pe cati biti e
      iw_reg[write_pointer] = '{opcode,operand_a,operand_b};//poate sa fie orice valorea, deoarece se suprascrie
    end

//letch comuta pe palier si bisatbilu pe front 
  // read from the register
 
 assign instruction_word = iw_reg[read_pointer];  // continuously read from register
//read_pointer ii spune ca citesc ce  in structura, daca nu am intializat nicio structra citesc 0 , iar inainte de reste citesc x-uri
// compile with +define+FORCE_LOAD_ERROR to inject a functional bug for verification to catch
`ifdef FORCE_LOAD_ERROR
initial begin
  force operand_b = operand_a; // cause wrong value to be loaded into operand_b
end
`endif

endmodule: instr_register
