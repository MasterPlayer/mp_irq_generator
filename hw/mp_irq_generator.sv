`ifndef __MP_IRQ_GENERATOR_DEFINED__
`define __MP_IRQ_GENERATOR_DEFINED__

module mp_irq_generator #(
    parameter integer DEFAULT_DURATION = 100
)(
    input  logic        CLK           ,
    input  logic        RESET         ,
    input  logic        USER_EVENT_IN ,
    input  logic        RETRY         ,
    output logic        USER_EVENT_OUT,
    input  logic [31:0] DURATION
);


    logic [31:0] duration_reg    = '{default:0};
    logic        d_user_event_in = 1'b0        ;
    logic        has_user_event  = 1'b0        ;

    typedef enum {
        IDLE_ST         ,
        EVENT_GEN_ST     
    } fsm;

    fsm  current_state = IDLE_ST;


    always_ff @(posedge CLK) begin : user_event_out_reg_processing
        case (current_state) 
            EVENT_GEN_ST :
                USER_EVENT_OUT <= 1'b1;

            default: 
                USER_EVENT_OUT <= 1'b0;
        endcase
    end

    always_ff @(posedge CLK) begin : d_event_processing
        d_user_event_in <= USER_EVENT_IN;
    end

    always_ff @(posedge CLK) begin : has_user_event_processing
        if (USER_EVENT_IN & ~d_user_event_in) begin 
            has_user_event <= 1'b1;
        end else begin
            has_user_event <= 1'b0;
        end
    end

    always_ff @(posedge CLK) begin : duration_reg_processing
        if (RESET) begin 
            duration_reg <= DEFAULT_DURATION;
        end else begin

            case (current_state) 
                EVENT_GEN_ST :
                    if (duration_reg < (DURATION-1)) begin 
                        duration_reg <= duration_reg + 1;
                    end else begin 
                        duration_reg <= duration_reg;
                    end 

                default: 
                    duration_reg <= '{default:0};

            endcase
        end
    end

    always_ff @(posedge CLK) begin : current_state_processing
        if (RESET) begin 
            current_state <= IDLE_ST;
        end else begin 
            case (current_state)

                IDLE_ST :
                    if (has_user_event | RETRY) begin 
                        current_state <= EVENT_GEN_ST;
                    end else begin 
                        current_state <= current_state;
                    end
                
                EVENT_GEN_ST :
                    if (duration_reg == (DURATION-1)) begin 
                        current_state <= IDLE_ST;
                    end else begin 
                        current_state <= current_state;
                    end

                default: 
                    current_state <= current_state;

            endcase
        end
    end


endmodule : mp_irq_generator

`endif //__MP_IRQ_GENERATOR_DEFINED__