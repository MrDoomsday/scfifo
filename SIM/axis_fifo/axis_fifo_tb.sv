module axis_fifo_tb();

    localparam T_DATA_WIDTH = 320;
    localparam SIZE = 1024;

    bit clk;
    bit reset_n;

    //input stream
    bit   [T_DATA_WIDTH-1:0]        s_data_i;
    bit                             s_valid_i;
    bit                             s_ready_o;

    //output stream
    bit   [T_DATA_WIDTH-1:0]        m_data_o;
    bit                             m_valid_o;
    bit                             m_ready_i;

    mailbox mbx_etalon_seq;
    mailbox mbx_master_mon;

    int timeout = 10000000;
    int count_transaction = 100000;


    axis_fifo_fr #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .SIZE          (SIZE)
    ) DUT (
        .clk        (clk),
        .reset_n    (reset_n),

        //input stream
        .s_data_i   (s_data_i),
        .s_valid_i  (s_valid_i),
        .s_ready_o  (s_ready_o),

        //output stream
        .m_data_o   (m_data_o),
        .m_valid_o  (m_valid_o),
        .m_ready_i  (m_ready_i)
    );


    always begin
        clk = 1'b0;
        #10;
        clk = 1'b1;
        #10;
    end


    initial begin
        mbx_etalon_seq = new();
        mbx_master_mon = new();

        gen_reset();

        fork
            wait_timeout(timeout);
            drive_slave(count_transaction);
            drive_master();
            monitor_master();
            check(count_transaction);
        join
    end

    task gen_reset();
        reset_n     <= 1'b0;
        s_valid_i   <= 1'b0;
        s_data_i    <= 'h0;
        m_ready_i   <= 1'b0;
        repeat(10) @(posedge clk);
        reset_n <= 1'b1;
    endtask

    task wait_timeout(int tout);
        repeat(tout) @(posedge clk);
        $stop("TIMEOUT");
    endtask


    task drive_slave(int cnt_word);
        bit [T_DATA_WIDTH-1:0] test_data;
        repeat(cnt_word) begin
            void'(std::randomize(test_data));
            do begin
                s_valid_i   <= 1'b1;
                s_data_i    <= test_data;
                @(posedge clk);
            end
            while(~s_ready_o);
            mbx_etalon_seq.put(test_data);
            s_valid_i   <= 1'b0;
            s_data_i    <= 'h0;
        end
        $display("Send etalon sequence is complete");
    endtask

    task drive_master();
        forever begin
            m_ready_i <= 1'b1;
            repeat($urandom_range(10, 0)) @(posedge clk);
            m_ready_i <= 1'b0;
            repeat($urandom_range(10, 0)) @(posedge clk);
            
        end
    endtask

    task monitor_master();
        forever begin
            @(posedge clk);
            if(m_valid_o && m_ready_i) begin
                mbx_master_mon.put(m_data_o);
            end
        end
    endtask

    task check(int cnt_word);
        int current_check_word;
        int cnt_error;
        bit [T_DATA_WIDTH-1:0] sdata, mdata;

        cnt_error = 0;
        current_check_word = 0;

        forever begin
            mbx_etalon_seq.get(sdata);
            mbx_master_mon.get(mdata);

            if(sdata != mdata) begin
                cnt_error++;
                $display("mdata != sdata, sdata = %0h, mdata = %0h", sdata, mdata);
                $error();
            end
            
            current_check_word++;
            
            if(current_check_word >= cnt_word) begin
                if(cnt_error > 0) $display("TEST FAILED, cout errors = %0d", cnt_error);
                else $display("TEST PASSED, count transaction = %0d", current_check_word);

                if(mbx_etalon_seq.num() > 0 || mbx_master_mon.num() > 0) begin
                    $display("mbx_etalon.size = %0d, mbx_mon.size = %0d", mbx_etalon_seq.num(), mbx_master_mon.num());
                end
                repeat(10) @(posedge clk);
                $stop();
            end
        end

    endtask

endmodule