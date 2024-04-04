% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function [fig, ax] = setup_figure(fig_width, fig_height, enable_legend, enable_tmp_fix, axis_equal)

arguments
    fig_width = 3.41275152778;
    fig_height = 3.41275152778;
    enable_legend = true;
    enable_tmp_fix = false;  % set to true if desired border box
    axis_equal = true;
end

% columnwidth = 3.41275152778;
% textwidth = 7.02625;

% 2 side by side: 1.627635606409449
% 3 side by side: 1.058843685114173

fig = figure;
tiledlayout(1, 1, 'Padding', 'tight', 'TileSpacing', 'none');
fig.Units = 'inches';
fig.OuterPosition = [0 0 fig_width fig_height];
fig.PaperUnits = 'inches';
if enable_tmp_fix
    fig.PaperSize = [fig_width*1.001 fig_height*1.001];
else
    fig.PaperSize = fig.PaperPosition(3:4);
end

fig.Renderer = 'Painters';

ax = nexttile;

if axis_equal
    axis equal;
end
hold on;
set(ax, 'TickLabelInterpreter', 'latex');

if enable_legend
    leg = legend();
    set(leg, 'Interpreter', 'latex');
end

fontsize(fig, 6, "points");

end