proc isim_script {} {

   add_divider "Signals of the Vigenere Interface"
   add_wave_label "" "CLK" /testbench/clk
   add_wave_label "" "RST" /testbench/rst
   add_wave_label "-radix ascii" "DATA" /testbench/tb_data
   add_wave_label "-radix ascii" "KEY" /testbench/tb_key
   add_wave_label "-radix ascii" "CODE" /testbench/tb_code

   add_divider "Vigenere Inner Signals"
   add_wave_label "-radix unsigned" "OFFSET" /testbench/uut/offset
   add_wave_label "-radix ascii" "PLUS_RESULT" /testbench/uut/plusMod
   add_wave_label "-radix ascii" "MINUS_RESULT" /testbench/uut/minusMod

   add_wave_label "" "presentSTATE" /testbench/uut/presState
   add_wave_label "" "nextSTATE" /testbench/uut/nextState

   add_wave_label "" "FSM_OUTPUT" /testbench/uut/fsmOutput_logic
   run 8 ns
}
