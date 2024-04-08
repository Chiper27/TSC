/***********************************************************************
 * A SystemVerilog testbench for an instruction register.
 * The course labs will convert this to an object-oriented testbench
 * with constrained random test generation, functional coverage, and
 * a scoreboard for self-verification.
 **********************************************************************/

module instr_register_test
  import instr_register_pkg::*;  // user-defined types are defined in instr_register_pkg.sv
  (input  logic          clk,
   output logic          load_en,
   output logic          reset_n,
   output operand_t      operand_a,
   output operand_t      operand_b,
   output opcode_t       opcode,
   output address_t      write_pointer,
   output address_t      read_pointer,
   input  instruction_t  instruction_word
  );//dut ul are output care merge in test

  timeunit 1ns/1ns;
  parameter readNumber  = 49;
  parameter writeNumber = 50;
  parameter write_order = 2;
  parameter read_order = 0;
//se ia doar primi 5 biti de la int deoarece e pe 5 biti , si de asta read si writePointer ajunge pana la maxim 31 si dupa face overflow s
// se reseteaza in 0
  parameter TEST_REG;
  int seed = 555;
  instruction_t  iw_test_reg [0:31]; 
  int failedTest = 0;
  int passedTest = 0;

  initial begin
    $display("\n\n***********************************************************");
    $display(    "***  THIS IS A SELF-CHECKING TESTBENCH .  YOU DON'T  ***");
    $display(    "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display(    "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(    "***********************************************************");

    $display("\nReseting the instruction register...");
    write_pointer  = 5'h00;         // 5 biti in hexazecimal si toate in zero
    read_pointer   = 5'h1F;         // initialize read pointer
    load_en        = 1'b0;          // initialize load control line
    reset_n       <= 1'b0;          // assert reset_n (active low)
    foreach ( iw_test_reg[i]) begin
       iw_test_reg[i] = '{opc: ZERO, default: 0};
    end
    repeat (2) @(posedge clk) ;     // hold in reset for 2 clock cycles
    reset_n        = 1'b1;          // deassert reset_n (active low)

    $display("\nWriting values to register stack...");
    @(posedge clk) load_en = 1'b1;  // enable writing to register
    // repeat (3) begin Chiper Stefan 03/11/2024 
    repeat (writeNumber) begin 
      @(posedge clk) randomize_transaction;
      @(negedge clk) print_transaction;
      saveTestData;
    end
    @(posedge clk) load_en = 1'b0;  // turn-off writing to register

    // read back and display same three register locations
    $display("\nReading back the same register locations written...");
    // for (int i=0; i<=2; i++) begin Chiper Stefan 03/11/2024
    for (int i=0; i<=readNumber; i++) begin
      // later labs will replace this loop with iterating through a
      // scoreboard to determine which addresses were written and
      // the expected values to be read back
      // @(posedge clk) read_pointer = i;
      case(read_order)
      0: @(posedge clk) read_pointer = i;
      1: @(posedge clk) read_pointer = 31-(i%32);
      2: @(posedge clk) read_pointer = $unsigned($random)%32;
      endcase
      @(negedge clk) print_results;
      checkResult;
    end
    
     final_report;

    @(posedge clk) ;
    $display("\n***********************************************************");
    $display(  "***  THIS IS A SELF-CHECKING TESTBENCH .  YOU DON'T  ***");
    $display(  "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display(  "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(  "***********************************************************\n");
    $finish;
  end
 
  function void randomize_transaction;
    // A later lab will replace this function with SystemVerilog
    // constrained random values
    //
    // The stactic temp variable is required in order to write to fixed
    // addresses of 0, 1 and 2.  This will be replaceed with randomizeed
    // write_pointer values in a later lab
    //
    static int temp = 0; // static se refera ca este alocata o singura data
    static int temp_decrement = 31;
    operand_a     <= $random(seed)%16;                 // between -15 and 15 | random este implementat in functie de vendor= producatorul toolui
    operand_b     <= $unsigned($random)%16;            // between 0 and 15 |unsinged converteste numerele negative in numere pozitive
    opcode        <= opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type| opcode_t' -inseamna cast =converstete la tipul opcode_t
    
    case (write_order) 
      0: write_pointer = temp++;
      1: write_pointer = temp_decrement--;
      2: write_pointer = $unsigned($random)%32;
    endcase

  endfunction: randomize_transaction

  function void print_transaction;
    $display("Writing to register location %0d: ", write_pointer);
    $display("  opcode = %0d (%s)", opcode, opcode.name);
    $display("  operand_a = %0d",   operand_a);
    $display("  operand_b = %0d\n", operand_b);
  endfunction: print_transaction

  function void print_results;
    $display("Read from register location %0d: ", read_pointer);
    $display("  opcode = %0d (%s)", instruction_word.opc, instruction_word.opc.name);
    $display("  operand_a = %0d",   instruction_word.op_a);
    $display("  operand_b = %0d", instruction_word.op_b);
    $display(" result_t = %0d\n", instruction_word.rezultat);
  endfunction: print_results

  function void checkResult;
  int exp_result;
  if( iw_test_reg[read_pointer].opc == instruction_word.opc  )
    $display("Opcode is correct from register location %0d: ", read_pointer);
  else
    $display("Opcode is incorrect from register location %0d: ", read_pointer);

  if( iw_test_reg[read_pointer].op_a == instruction_word.op_a)
    $display("Operant_a is correct from register location %0d: ", read_pointer);
  else
    $display("Operant_a is incorrect from register location %0d: ", read_pointer);

  if( iw_test_reg[read_pointer].op_b == instruction_word.op_b)
      $display("Operant_b is correct from register location %0d: ", read_pointer);
    else
      $display("Operant_b is incorrect from register location %0d: ", read_pointer);

  case (iw_test_reg[read_pointer].opc)
    ZERO : exp_result = 0;
    ADD: exp_result = iw_test_reg[read_pointer].op_a + iw_test_reg[read_pointer].op_b;
    SUB: exp_result = iw_test_reg[read_pointer].op_a - iw_test_reg[read_pointer].op_b;
    PASSA: exp_result = iw_test_reg[read_pointer].op_a;
    PASSB: exp_result = iw_test_reg[read_pointer].op_b;
    MULT: exp_result = iw_test_reg[read_pointer].op_a * iw_test_reg[read_pointer].op_b;
    DIV:
         if(!iw_test_reg[read_pointer].op_b)
              exp_result = 0;
         else
              exp_result = iw_test_reg[read_pointer].op_a / iw_test_reg[read_pointer].op_b;
    MOD: exp_result = iw_test_reg[read_pointer].op_a % iw_test_reg[read_pointer].op_b;
    default: $display("Non existent operator");

  endcase

  // Compararea rezultatului așteptat cu rezultatul primit de la DUT
  if (exp_result == instruction_word.rezultat) begin
    $display("Result check: Approved");
    passedTest++;
  end else begin
    $display("Result check: Unapproved");
    failedTest++;
  end
  endfunction:checkResult


  function void saveTestData;

  iw_test_reg[write_pointer] = '{opcode, operand_a,operand_b,0};
    $display("Read from register location %0d: ", write_pointer);
    $display("  opcode = %0d (%s)", iw_test_reg[write_pointer].opc, iw_test_reg[write_pointer].opc.name);
    $display("  operand_a = %0d",   iw_test_reg[write_pointer].op_a);
    $display("  operand_b = %0d", iw_test_reg[write_pointer].op_b);
  endfunction:saveTestData

 function final_report;

  $display("Failed tests %0d: ", failedTest);
  $display("Passed tests %0d: ", passedTest);
// facem aici cu fopen si deschidem fiser ,sa arate pass sau fail
// putem sa mai facem si un nou parameter
//cum adaugi un paramter nou
// cum salvam formele de unda
//mai lucreaza acaasa
// adauga un bit de semn, tre sa mergi in packege
 endfunction:final_report

endmodule: instr_register_test
