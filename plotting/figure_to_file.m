% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function figure_to_file(full_filepath, fig)

fig_op = fig.OuterPosition;
orig_width = fig_op(3);
orig_height = fig_op(4);

width = orig_width * 10; % pixels
height = orig_height * 10; % pixels
res = 600; % dpi

% set all units inside figure to normalized so that everything is scaling accordingly
set(findall(fig, 'Units', 'pixels'), 'Units', 'normalized');
% do not show figure on screen
set(fig, 'visible', 'off');
% set figure units to pixels & adjust figure size
fig.Units = 'pixels';
fig.OuterPosition = [0, 0, width, height];

% recalculate figure size to be saved
set(fig, 'PaperPositionMode', 'manual');
fig.PaperUnits = 'inches';
fig.PaperPosition = [0, 0, width, height] / res;
% save figure
print(fig, full_filepath, '-dpng', sprintf('-r%d', res));

end