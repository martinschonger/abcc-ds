% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


classdef constants
    properties (Constant)
        LINEWIDTH = 1
        LINEWIDTH_THIN = 0.5
        LINEWIDTH_THICK = 2
        TRAJECTORY_COLOR_FG = '#3392ff'
        TRAJECTORY_COLOR_BG = '#3392ff'
        EQUILIBRIUM_COLOR = 'black'
        STATE_VAR = "x"
        STATE_VAR_TEX = "\mathbf{x}"
        F_VAR = "f"
        F_VAR_TEX = "f"
        LYAP_VAR = "V"
        LYAP_VAR_TEX = "V"
        BARR_VAR = "B"
        BARR_VAR_TEX = "B"
        DOT_SUFFIX = "dot"
        PRECISION = 128
        OUTPUT_PATH = 'd:\dev\ds-out\'
        OUTPUT_PATH_WSL = '/mnt/d/dev/ds-out/'
    end
end