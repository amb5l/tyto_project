# x1 to x2 multicycle
set_multicycle_path 2 -setup -from [get_clocks clk_x1] -to [get_clocks clk_x2]
set_multicycle_path 1 -hold -end -from [get_clocks clk_x1] -to [get_clocks clk_x2]

# x2 to x1 multicycle
set_multicycle_path 2 -setup -start -from [get_clocks clk_x2] -to [get_clocks clk_x1]
set_multicycle_path 1 -hold -from [get_clocks clk_x2] -to [get_clocks clk_x1]

# x2 to x2 multicycle - zero page and stack cache reads
set_multicycle_path 2 -setup -from [get_clocks clk_x2] -to [get_clocks clk_x2] -through [get_nets -hierarchical s1_zptr_d[*]]
set_multicycle_path 1 -hold -from [get_clocks clk_x2] -to [get_clocks clk_x2] -through [get_nets -hierarchical s1_zptr_d[*]]
set_multicycle_path 2 -setup -from [get_clocks clk_x2] -to [get_clocks clk_x2] -through [get_nets -hierarchical s1_pull_d[*]]
set_multicycle_path 1 -hold -from [get_clocks clk_x2] -to [get_clocks clk_x2] -through [get_nets -hierarchical s1_pull_d[*]]

# false paths   
set_false_path -through [get_nets -hierarchical vector_irq[*]]
set_false_path -through [get_nets -hierarchical vector_nmi[*]]