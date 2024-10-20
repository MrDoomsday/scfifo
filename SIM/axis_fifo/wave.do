onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /axis_fifo_tb/DUT/clk
add wave -noupdate /axis_fifo_tb/DUT/reset_n
add wave -noupdate -expand -group sink /axis_fifo_tb/DUT/s_data_i
add wave -noupdate -expand -group sink /axis_fifo_tb/DUT/s_valid_i
add wave -noupdate -expand -group sink /axis_fifo_tb/DUT/s_ready_o
add wave -noupdate -expand -group source /axis_fifo_tb/DUT/m_data_o
add wave -noupdate -expand -group source /axis_fifo_tb/DUT/m_valid_o
add wave -noupdate -expand -group source /axis_fifo_tb/DUT/m_ready_i
add wave -noupdate /axis_fifo_tb/DUT/wr_ptr
add wave -noupdate /axis_fifo_tb/DUT/wr_ptr_next
add wave -noupdate /axis_fifo_tb/DUT/rd_ptr
add wave -noupdate /axis_fifo_tb/DUT/rd_ptr_next
add wave -noupdate /axis_fifo_tb/DUT/s_ready_next
add wave -noupdate /axis_fifo_tb/DUT/m_valid_next
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
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
WaveRestoreZoom {0 ns} {4646 ns}
