module multi_push_multi_pop_fifo_tb;

    // Parameters
    localparam  WIDTH_DATA = 32;
    localparam  SIZE_FIFO = 1025;
    localparam  AMOUNT_PUSH_POP = 17;

    localparam  WIDTH_CAN = $clog2(AMOUNT_PUSH_POP + 1); // ширина шин can_push и can_pop
    localparam  WIDTH_SIZE_FIFO = $clog2(SIZE_FIFO + 1);

    // Ports
    reg                                             clk;
    reg                                             reset_n;
    
    reg   [WIDTH_CAN-1:0]                           push;
    reg   [AMOUNT_PUSH_POP-1:0][WIDTH_DATA-1:0]     push_data;
    wire  [WIDTH_CAN-1:0]                           can_push;

    reg   [WIDTH_CAN-1:0]                           pop;
    wire  [AMOUNT_PUSH_POP-1:0][WIDTH_DATA-1:0]     pop_data;
    logic [WIDTH_CAN-1:0]                           pop_resp;
    wire  [WIDTH_CAN-1:0]                           can_pop;

    mailbox mbx_gen_push;
    int amount_gen_data_word = 1_000_000;
    int complete_check_words = 0;
    int error_check_words = 0;


    multi_push_multi_pop_fifo # (
        .WIDTH_DATA         ( WIDTH_DATA        ),
        .SIZE_FIFO          ( SIZE_FIFO         ),
        .AMOUNT_PUSH_POP    ( AMOUNT_PUSH_POP   )
    ) DUT (
        .clk        ( clk       ),
        .reset_n    ( reset_n   ),

        .push       ( push      ),
        .push_data  ( push_data ),
        .can_push   ( can_push  ),
        
        .pop        ( pop       ),
        .pop_data   ( pop_data  ),
        .pop_resp   ( pop_resp  ),
        .can_pop    ( can_pop   )
    );


    always begin
        clk <= 1'b0;
        #10;
        clk <= 1'b1;
        #10;
    end

    
    initial begin
        mbx_gen_push = new();

        reset_n     <= 1'b0;
        push        <= '0;
        push_data   <= '0;
        pop         <= '0;
        repeat(10) @(posedge clk);
        reset_n     <= 1'b1;
        repeat(10) @(posedge clk);
        

        fork
            generator_push();
            generator_pop();
            data_checker();
            timeout(1_000_000_000);
        join
    end


    task generator_push();
        automatic int current_gen_words = 0; // текущее число сгенерированных слов
        wait(reset_n);

        while(current_gen_words < amount_gen_data_word) begin
            automatic logic [WIDTH_CAN-1:0] push_next;
            automatic logic [AMOUNT_PUSH_POP-1:0][WIDTH_DATA - 1:0] data_next;
                        
            // randomize
            void'(std::randomize(push_next) with {  push_next <= AMOUNT_PUSH_POP; 
                                                    push_next <= can_push; 
                                                    push_next + current_gen_words <= amount_gen_data_word;});
            void'(std::randomize(data_next));

            current_gen_words += push_next;

            if(push_next > 0) begin
                for(int i = 0; i < push_next; i++) begin
                    mbx_gen_push.put(data_next[i]);
                end
            end

            push        <= push_next;
            push_data   <= data_next;
            @(posedge clk);
            #1;
        end
        push        <= '0;
        push_data   <= '0; 
        $display("PUSH generation is complete");
    endtask

    task generator_pop();
        automatic int current_gen_words = 0; // текущее число сгенерированных слов
        logic [WIDTH_CAN-1:0] pop_next;
        wait(reset_n);

        while(current_gen_words < amount_gen_data_word) begin
            // randomize
            void'(std::randomize(pop_next) with {   pop_next <= AMOUNT_PUSH_POP; 
                                                    pop_next <= can_pop; 
                                                    pop_next + current_gen_words <= amount_gen_data_word;});
            
            current_gen_words += pop_next;

            pop <= pop_next;
            @(posedge clk);
            #1;
        end
        pop <= '0;
        $display("POP generation is complete");
    endtask


    task data_checker();
        automatic int current_check_words = 0; // текущее число сгенерированных слов
        automatic logic [WIDTH_DATA-1:0] mbx_rdata;
        wait(reset_n);

        @(posedge clk);

        while(current_check_words < amount_gen_data_word) begin
            @(posedge clk);
            if(pop_resp > 0) begin
                for(int i = 0; i < pop_resp; i++) begin
                    current_check_words++;
                    mbx_gen_push.get(mbx_rdata);
                    if(mbx_rdata != pop_data[i]) begin
                        $error("Data not equal, data push = %0h, data pop = %0h", mbx_rdata, pop_data[i]);
                        error_check_words++;
                    end else begin
                        complete_check_words++;
                    end
                end
            end
        end

        repeat(1000) @(posedge clk);

        if(error_check_words > 0) begin
            $error("****TEST FAILED****");
            $display("Error check words = %0d", error_check_words);
            $display("Complete check words = %0d", complete_check_words);
            $stop();
        end else begin
            $display("****TEST PASSED****");
            $display("Complete check words = %0d", complete_check_words);
        end
        $stop();
    endtask


    task timeout(int tout);
        repeat(tout) @(posedge clk);
        $error("***TIMEOUT****");
        $stop();
    endtask

endmodule