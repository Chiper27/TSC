
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
  );

  timeunit 1ns/1ns;

  parameter WRITE_NR = 50;
  parameter READ_NR = 49;
  parameter WRITE_ORDER = 0; // 0 - incremental, 1 - random, 2 - decremental
  parameter READ_ORDER = 0; // 0 - incremental, 1 - random, 2 - decremental
  parameter CASE_NAME;
  parameter SEED_VAL= 555;

  int seed = SEED_VAL;

  int passed_tests = 0;
  int failed_tests = 0;
  instruction_t save_data [0:31];

  initial begin
    $display("\n************************************************************");
    $display(  "***  THIS IS A SELF-CHECKING TESTBENCH. YOU DON'T        ***");
    $display(  "***    NEED TO VISUALLY VERIFY THE OUTPUT VALUES         ***");
    $display(  "*** TO MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION ***");
    $display(  "************************************************************\n");

    $display("\nReseting the instruction register...");
    write_pointer  = 5'h00;         // initialize write pointer
    read_pointer   = 5'h1F;         // initialize read pointer
    load_en        = 1'b0;          // initialize load control line
    reset_n       <= 1'b0;          // assert reset_n (active low)
    foreach (save_data[i])
      save_data[i] = '{opc:ZERO,default:0};  // reset to all zeros
    repeat (2) @(posedge clk) ;     // hold in reset for 2 clock cycles
    reset_n        = 1'b1;          // deassert reset_n (active low)

    $display("\nWriting values to register stack...");
    @(posedge clk) load_en = 1'b1;  // enable writing to register
    // repeat (3) begin - 11/03/2024 -Chiper Stefan
    repeat (WRITE_NR) begin
      @(posedge clk) begin
        randomize_transaction;
        save_test_data;
      end
      // @(negedge clk) print_transaction; - 14/04/2024 - Chiper Stefan
    end
    @(posedge clk) load_en = 1'b0;  // turn-off writing to register

    // read back and display same three register locations
    $display("\nReading back the same register locations written...");
    // for (int i=0; i<=2; i++) begin - 11/03/2024 - Chiper Stefan
    for (int i=0; i<=READ_NR; i++) begin
      // later labs will replace this loop with iterating through a
      // scoreboard to determine which addresses were written and
      // the expected values to be read back
      @(posedge clk) begin
        if(READ_ORDER == 0)
          read_pointer = i;
        if(READ_ORDER == 1)
          read_pointer = $unsigned($random)%32;
        if(READ_ORDER == 2)
          read_pointer = 31 - (i % 32);
      end
      @(negedge clk) test_data;
      // @(negedge clk) print_results; 18.03.2024 -Chiper Stefan
      check_results;
    end

    @(posedge clk);
    final_report;
    overall_report;

    $display("\n*************************************************************");
    $display(  "***  THIS IS NOW A SELF-CHECKING TESTBENCH. YOU NO        ***");
    $display(  "***  LONGER NEED TO VISUALLY VERIFY THE OUTPUT VALUES     ***");
    $display(  "*** TO MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(  "*************************************************************\n");
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
    static int temp = 0;
    static int temp2 = 31;
    operand_a     <= $random(seed)%16;                 // between -15 and 15
    operand_b     <= $unsigned($random)%16;            // between 0 and 15
    opcode        <= opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type
    if(WRITE_ORDER == 0)
      write_pointer <= temp++;
    if(WRITE_ORDER == 1)
      write_pointer <= $unsigned($random)%32;
    if(WRITE_ORDER == 2)
      write_pointer <= temp2--;
  endfunction: randomize_transaction

  function void print_transaction;
    $display("Writing to register location %0d: ", write_pointer);
    $display("  opcode = %0d (%s)", opcode, opcode.name);
    $display("  operand_a = %0d",   operand_a);
    $display("  operand_b = %0d\n", operand_b);
  endfunction: print_transaction

  function void save_test_data;
    save_data[write_pointer] = {opcode, operand_a, operand_b, 0};
  endfunction: save_test_data

  function void test_data;
    if(save_data[read_pointer].opc != instruction_word.opc)begin
      $display("Register Location %0d: DUT opcode %0d (%s), saved opcode %0d (%s)", read_pointer, instruction_word.opc, instruction_word.opc.name, save_data[read_pointer].opc, save_data[read_pointer].opc.name);
      failed_tests++;
    end
    else if(save_data[read_pointer].op_a != instruction_word.op_a) begin
      $display("Register Location %0d: DUT operand_a %0d, saved operand_a %0d", read_pointer, instruction_word.op_a, save_data[read_pointer].op_a);
      failed_tests++;
    end
    else if(save_data[read_pointer].op_b != instruction_word.op_b) begin
      $display("Register Location %0d: DUT operand_b %0d, saved operand_b %0d", read_pointer, instruction_word.op_b, save_data[read_pointer].op_b);
      failed_tests++;
    end
    else begin
      // $display("OK: Saved data matches the DUT data for location %0d", read_pointer);
      passed_tests++;
    end
  endfunction: test_data;

  function void print_results;
    $display("Read from register location %0d: ", read_pointer);
    $display("  opcode = %0d (%s)", instruction_word.opc, instruction_word.opc.name);
    $display("  operand_a = %0d",   instruction_word.op_a);
    $display("  operand_b = %0d", instruction_word.op_b);
    $display("  result = %0d\n", instruction_word.rezultat);
  endfunction: print_results

  function void check_results; // din instruction word luam operand A, operand B, op code si calculam iar valorile si le verificam fata de cele din DUT (case)
    automatic longint expected_result = 0; // rezultat intern folosit la calcul, longint e pe 64 de biti, deci pot face comparatie
    if(instruction_word.opc.name === "ZERO")
      expected_result = 0;
    else if(instruction_word.opc.name === "PASSA")
      expected_result = instruction_word.op_a;
    else if(instruction_word.opc.name === "PASSB")
      expected_result = instruction_word.op_b;
    else if(instruction_word.opc.name === "ADD")
      expected_result = instruction_word.op_a + instruction_word.op_b;
    else if(instruction_word.opc.name === "SUB")
      expected_result = instruction_word.op_a - instruction_word.op_b;
    else if(instruction_word.opc.name === "MULT")
      expected_result = instruction_word.op_a * instruction_word.op_b;
    else if(instruction_word.opc.name === "DIV") begin
      if(instruction_word.op_b == 0)
        expected_result = 0;
      else
        expected_result = instruction_word.op_a / instruction_word.op_b;
    end
    else if(instruction_word.opc.name === "MOD") begin
      if(instruction_word.op_b == 0)
        expected_result = 0;
      else
        expected_result = instruction_word.op_a % instruction_word.op_b;
    end
    
    $display("Read pointer = %0d: ", read_pointer);
    $display("  opcode = %0d (%s)", instruction_word.opc, instruction_word.opc.name);
    $display("  operand_a = %0d",   instruction_word.op_a);
    $display("  operand_b = %0d", instruction_word.op_b);
    $display("  result = %0d", instruction_word.rezultat);
    $display("  expected result = %0d", expected_result);
    
    if(expected_result == instruction_word.rezultat)
      $display("OK: Expected result and the actual result are identical!\n");
    else
      $display("ERROR: Expected result and the actual result differ!\n");
  endfunction: check_results

  function void final_report;
    if(passed_tests + failed_tests != WRITE_NR && passed_tests + failed_tests < WRITE_NR)
      $display("\nYou have tested only %0d out of %0d!", passed_tests + failed_tests, WRITE_NR);
    else if(passed_tests + failed_tests > WRITE_NR)
      $display("\nYou have %0d tests and only %0d values!", passed_tests + failed_tests, WRITE_NR);
    else begin
      $display("\nNumber of passed tests: %0d (%0d%%)", passed_tests, (passed_tests * 100) / WRITE_NR);
      $display("Number of failed tests: %0d (%0d%%)", failed_tests, (failed_tests * 100) / WRITE_NR);
    end
  endfunction: final_report

  function void overall_report;
  int file;
  file = $fopen("../reports/regression_status.txt", "a");
  if(failed_tests != 0) 
    $fwrite(file, "Case %s: failed\n", CASE_NAME);
  else 
    $fwrite(file, "Case %s: passed\n", CASE_NAME);

  $fclose(file);
  endfunction: overall_report

endmodule: instr_register_test
//sesiune de debug
//inca o suta de teste random
// aduagam un POV
// de pus parametru nou
// git 
// salvez formele de unda 
//ai un test care pica , faci debug
// 