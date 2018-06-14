module tb_Motherboard;

reg clk;
reg rst;
reg     [15:0] switches;
wire    [15:0] led;

integer I;
integer K;

Motherboard #(.CLOCK_DIVIDER(1)) DUT (
    .clk100Mhz      (clk),
    .rst            (rst),
    .switches       (switches),
    .led            (led)
);

task tick;
begin
    clk = 1'b0; #5; clk =  1'b1; #5;
end
endtask

initial begin
    switches = 0;
    rst = 1'b0; #1; rst = 1'b1; #1; rst = 1'b0;  
    for(I = 32'h9E20; I < 2 ** 16 - 1; I = I + 1) begin
        for(K = 0; K < 16; K = K + 1) begin
            tick;
        end
        switches = I;
        if(led == 0) begin
            switches = 0;
            $stop;
        end
    end
    $finish;
end
endmodule
