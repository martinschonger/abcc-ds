% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function adjust_figure(fig, width, height)

    arguments
        fig
        width % in
        height % in
    end
    
    SPPI = get(0,'ScreenPixelsPerInch');
    tmp_offset = 1/(SPPI-1);
    
    fig.Units = 'inches';
    fig.Position = [0 0 width height];
    
    set(fig, 'PaperPositionMode', 'manual');
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [-tmp_offset -tmp_offset width+2*tmp_offset height+2*tmp_offset];
    fig.PaperSize = [width height];
    
    fontsize(fig, 6, "points");
end