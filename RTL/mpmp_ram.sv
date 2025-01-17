module mpmp_ram #(
    parameter   DATA_WIDTH      = 10,   // ширина шины данных
                RAM_SIZE        = 12,   // число слов, которые можно записать в память (на глубину памяти не смотрим)
                ADDR_WIDTH      = 10    // минимальная ширина шины адреса, способная адресовать весь массив слов RAM_SIZE
)(
    input                               clk,
    input                               reset_n,

    // write
    input   logic                       write,
    input   logic   [DATA_WIDTH-1:0]    wdata,

    // read
    input   logic                       read,
    output  logic   [DATA_WIDTH-1:0]    rdata

);


    reg     [DATA_WIDTH-1:0]    ram             [RAM_SIZE-1:0];
    logic   [ADDR_WIDTH-1:0]    wr_ptr, 
                                wr_ptr_next;
    logic   [ADDR_WIDTH-1:0]    rd_ptr,
                                rd_ptr_next;
    

    // wr ptr
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            wr_ptr <= '0;
        end else if(write) begin
            wr_ptr <= wr_ptr_next;
        end
    end

    always_comb begin
        if(wr_ptr == RAM_SIZE - 1) begin
            wr_ptr_next = '0;
        end else begin
            wr_ptr_next = wr_ptr + 'd1;
        end
    end

    always_ff @(posedge clk) begin
        if(write) begin
            ram[wr_ptr] <= wdata;
        end
    end

    // rd ptr
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            rd_ptr <= '0;
        end else if(read) begin
            rd_ptr <= rd_ptr_next;
        end
    end

    always_comb begin
        if(rd_ptr == RAM_SIZE - 1) begin
            rd_ptr_next = '0;
        end else begin
            rd_ptr_next = rd_ptr + 'd1;
        end
    end

    always_ff @(posedge clk) begin
        rdata <= ram[rd_ptr];
    end





endmodule