onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /multi_push_multi_pop_fifo_tb/DUT/clk
add wave -noupdate /multi_push_multi_pop_fifo_tb/DUT/reset_n
add wave -noupdate -radix unsigned /multi_push_multi_pop_fifo_tb/DUT/push
add wave -noupdate -expand /multi_push_multi_pop_fifo_tb/DUT/push_data
add wave -noupdate /multi_push_multi_pop_fifo_tb/DUT/can_push
add wave -noupdate -radix unsigned /multi_push_multi_pop_fifo_tb/DUT/pop
add wave -noupdate -expand /multi_push_multi_pop_fifo_tb/DUT/pop_data
add wave -noupdate /multi_push_multi_pop_fifo_tb/DUT/pop_resp
add wave -noupdate -radix unsigned /multi_push_multi_pop_fifo_tb/DUT/can_pop
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/wrside_available_words
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/wrside_available_words_next
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/write
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/full
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/write_r
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/write_rr
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/write_rrr
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/wrmask_rr
add wave -noupdate -expand -group debug -expand /multi_push_multi_pop_fifo_tb/DUT/wrmask_rrr
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/wrmask_rr_next
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/wrmask_rrr_next
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/push_r
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/push_rr
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/push_rrr
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/wr_ptr_ram_block
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/wr_ptr_ram_block_next
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/rdside_used_words
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/rdside_used_words_next
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/read
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/empty
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/rdside_used_words
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/rdside_used_words_next
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/read
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/empty
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/read_r
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/pop_r
add wave -noupdate -expand -group debug -expand -group rd_rr /multi_push_multi_pop_fifo_tb/DUT/read_rr
add wave -noupdate -expand -group debug -expand -group rd_rr /multi_push_multi_pop_fifo_tb/DUT/pop_rr
add wave -noupdate -expand -group debug -expand -group rd_rr /multi_push_multi_pop_fifo_tb/DUT/rdmask_rr_next
add wave -noupdate -expand -group debug -expand -group rd_rr -expand /multi_push_multi_pop_fifo_tb/DUT/rdmask_rr
add wave -noupdate -expand -group debug -expand -group rd_rrr /multi_push_multi_pop_fifo_tb/DUT/read_rrr
add wave -noupdate -expand -group debug -expand -group rd_rrr /multi_push_multi_pop_fifo_tb/DUT/pop_rrr
add wave -noupdate -expand -group debug -expand -group rd_rrr -expand /multi_push_multi_pop_fifo_tb/DUT/rdmask_rrr_next
add wave -noupdate -expand -group debug -expand -group rd_rrr -expand /multi_push_multi_pop_fifo_tb/DUT/rdmask_rrr
add wave -noupdate -expand -group debug -expand -group rd_rrr /multi_push_multi_pop_fifo_tb/DUT/rd_ptr_ram_block
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/pop_rrrr
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/pop_rrrrr
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/rdata
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/rdata_rrrr
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/rdata_rrrrr
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/pop_data_next
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/rd_ptr_ram_block_next
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/rd_ptr_ram_block_rrrr
add wave -noupdate -expand -group debug /multi_push_multi_pop_fifo_tb/DUT/rd_ptr_ram_block_rrrrr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {34 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 283
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
WaveRestoreZoom {0 ns} {251 ns}
