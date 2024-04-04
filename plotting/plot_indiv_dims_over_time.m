% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function fig = plot_indiv_dims_over_time(dat, dat_est, i_idxs)

dim = dat.dim;
num_subsystems = length(i_idxs);

n_cols = 1;
n_rows = ceil(dim/n_cols);

width = 3.4; % in
approx_height_per_plot = 1; % in
height = approx_height_per_plot * n_rows;

fig = setup_figure2(width, height, setup_axes=false);
t = tiledlayout(n_rows, n_cols, 'Padding', 'compact', 'TileSpacing', 'compact');
title(t, "Individual dimensions over time");

cur_idx = 1;
for i = 1:num_subsystems
    i_idx = i_idxs{i};
    dim_i = size(i_idx, 2);
    for di = 1:dim_i
        nexttile;
        hold on;
        title("");
        xlabel("$t$", 'interpreter', 'latex');
        ylabel(strcat('$', abcds.util.constants.STATE_VAR_TEX, '_', int2str(cur_idx), '$'), 'interpreter', 'latex');

        % reference trajectories and equilibrium
        dat.plot_pos_time(cur_idx);
        axis_limits = axis;

        dat_est.plot_pos_time(cur_idx, {'color', '#ff00ff', 'displayname', '$' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{sim}}$'});
        
        y_range = axis_limits(4) - axis_limits(3);
        offset_for_desired_y_range = y_range * 0.1;
        xlim([axis_limits(1), axis_limits(2)]);
        ylim([axis_limits(3) - offset_for_desired_y_range, axis_limits(4) + offset_for_desired_y_range]);

        cur_idx = cur_idx + 1;

        if i == 1 && di == 1
            leg = legend();
            set(leg, 'Interpreter', 'latex');
            leg.ItemTokenSize(1) = 15;
        end
    end
end

adjust_figure(fig, width, height);

end