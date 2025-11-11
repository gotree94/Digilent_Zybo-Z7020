`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 나무
// 
// Create Date: 2025-11-12
// Module Name: alu_axi_lite_v1_0
// Description: 8-bit ALU with AXI-Lite Slave Interface for Zybo Z7-20
// 
// AXI-Lite Register Map:
// 0x00: Operand A Register [31:0]
//       [7:0]   - operand_a (8-bit)
//       [31:8]  - reserved
// 0x04: Operand B Register [31:0]
//       [7:0]   - operand_b (8-bit)
//       [31:8]  - reserved
// 0x08: Control Register [31:0]
//       [2:0]   - opcode (3-bit)
//       [3]     - enable
//       [31:4]  - reserved
// 0x0C: Result Register [31:0] (Read Only)
//       [15:0]  - result (16-bit)
//       [31:16] - reserved
//////////////////////////////////////////////////////////////////////////////////

module alu_axi_lite_v1_0 #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
)(
    // AXI-Lite Clock and Reset
    input  wire                                 s_axi_aclk,
    input  wire                                 s_axi_aresetn,
    
    // AXI-Lite Write Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]      s_axi_awaddr,
    input  wire [2:0]                          s_axi_awprot,
    input  wire                                 s_axi_awvalid,
    output wire                                 s_axi_awready,
    
    // AXI-Lite Write Data Channel
    input  wire [C_S_AXI_DATA_WIDTH-1:0]      s_axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0]  s_axi_wstrb,
    input  wire                                 s_axi_wvalid,
    output wire                                 s_axi_wready,
    
    // AXI-Lite Write Response Channel
    output wire [1:0]                           s_axi_bresp,
    output wire                                 s_axi_bvalid,
    input  wire                                 s_axi_bready,
    
    // AXI-Lite Read Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]      s_axi_araddr,
    input  wire [2:0]                          s_axi_arprot,
    input  wire                                 s_axi_arvalid,
    output wire                                 s_axi_arready,
    
    // AXI-Lite Read Data Channel
    output wire [C_S_AXI_DATA_WIDTH-1:0]      s_axi_rdata,
    output wire [1:0]                           s_axi_rresp,
    output wire                                 s_axi_rvalid,
    input  wire                                 s_axi_rready
);

    // AXI-Lite Signals
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg                          axi_awready;
    reg                          axi_wready;
    reg [1:0]                    axi_bresp;
    reg                          axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    reg                          axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    reg [1:0]                    axi_rresp;
    reg                          axi_rvalid;

    // Register addresses
    localparam ADDR_OPERAND_A = 4'h0;
    localparam ADDR_OPERAND_B = 4'h4;
    localparam ADDR_CONTROL   = 4'h8;
    localparam ADDR_RESULT    = 4'hC;

    // Internal registers
    reg [7:0]  reg_operand_a;
    reg [7:0]  reg_operand_b;
    reg [2:0]  reg_opcode;
    reg        reg_enable;
    wire [15:0] alu_result;

    // ALU instance
    ALU alu_inst (
        .a(reg_operand_a),
        .b(reg_operand_b),
        .opcode(reg_opcode),
        .ena(reg_enable),
        .result(alu_result)
    );

    // AXI-Lite signal assignments
    assign s_axi_awready = axi_awready;
    assign s_axi_wready  = axi_wready;
    assign s_axi_bresp   = axi_bresp;
    assign s_axi_bvalid  = axi_bvalid;
    assign s_axi_arready = axi_arready;
    assign s_axi_rdata   = axi_rdata;
    assign s_axi_rresp   = axi_rresp;
    assign s_axi_rvalid  = axi_rvalid;

    // Write address ready
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_awready <= 1'b0;
            axi_awaddr  <= 0;
        end else begin
            if (~axi_awready && s_axi_awvalid && s_axi_wvalid) begin
                axi_awready <= 1'b1;
                axi_awaddr  <= s_axi_awaddr;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    // Write data ready
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_wready <= 1'b0;
        end else begin
            if (~axi_wready && s_axi_wvalid && s_axi_awvalid) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end

    // Write response
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_bvalid <= 1'b0;
            axi_bresp  <= 2'b0;
        end else begin
            if (axi_awready && s_axi_awvalid && ~axi_bvalid && axi_wready && s_axi_wvalid) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b0; // OKAY response
            end else begin
                if (s_axi_bready && axi_bvalid) begin
                    axi_bvalid <= 1'b0;
                end
            end
        end
    end

    // Write to registers
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            reg_operand_a <= 8'h00;
            reg_operand_b <= 8'h00;
            reg_opcode    <= 3'b000;
            reg_enable    <= 1'b0;
        end else begin
            if (axi_wready && s_axi_wvalid && axi_awready && s_axi_awvalid) begin
                case (axi_awaddr[3:0])
                    ADDR_OPERAND_A: begin
                        if (s_axi_wstrb[0]) reg_operand_a <= s_axi_wdata[7:0];
                    end
                    ADDR_OPERAND_B: begin
                        if (s_axi_wstrb[0]) reg_operand_b <= s_axi_wdata[7:0];
                    end
                    ADDR_CONTROL: begin
                        if (s_axi_wstrb[0]) begin
                            reg_opcode <= s_axi_wdata[2:0];
                            reg_enable <= s_axi_wdata[3];
                        end
                    end
                    default: begin
                        // Do nothing for read-only or invalid addresses
                    end
                endcase
            end
        end
    end

    // Read address ready
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 0;
        end else begin
            if (~axi_arready && s_axi_arvalid) begin
                axi_arready <= 1'b1;
                axi_araddr  <= s_axi_araddr;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    // Read data valid
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_rvalid <= 1'b0;
            axi_rresp  <= 2'b0;
        end else begin
            if (axi_arready && s_axi_arvalid && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0; // OKAY response
            end else if (axi_rvalid && s_axi_rready) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    // Read from registers
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_rdata <= 0;
        end else begin
            if (axi_arready && s_axi_arvalid && ~axi_rvalid) begin
                case (axi_araddr[3:0])
                    ADDR_OPERAND_A: begin
                        axi_rdata <= {24'h000000, reg_operand_a};
                    end
                    ADDR_OPERAND_B: begin
                        axi_rdata <= {24'h000000, reg_operand_b};
                    end
                    ADDR_CONTROL: begin
                        axi_rdata <= {28'h0000000, reg_enable, reg_opcode};
                    end
                    ADDR_RESULT: begin
                        axi_rdata <= {16'h0000, alu_result};
                    end
                    default: begin
                        axi_rdata <= 32'h00000000;
                    end
                endcase
            end
        end
    end

endmodule
