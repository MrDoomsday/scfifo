onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sc_fifo_tb/clk
add wave -noupdate /sc_fifo_tb/reset_n
add wave -noupdate /sc_fifo_tb/wr
add wave -noupdate /sc_fifo_tb/data_in
add wave -noupdate /sc_fifo_tb/rd
add wave -noupdate /sc_fifo_tb/data_out
add wave -noupdate /sc_fifo_tb/full
add wave -noupdate /sc_fifo_tb/empty
add wave -noupdate /sc_fifo_tb/use_words
add wave -noupdate /sc_fifo_tb/clear
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {458 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {4652 ns}
