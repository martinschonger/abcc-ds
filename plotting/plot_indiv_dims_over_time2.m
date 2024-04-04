% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function fig = plot_indiv_dims_over_time2(dat, dat_est, i_idxs, args)

arguments
    dat, dat_est, i_idxs
    args.traj_actual
end

dim = dat.dim;
num_subsystems = length(i_idxs);

n_cols = 2;
n_rows = ceil(dim/n_cols);

width = 3.4; % in
approx_height_per_plot = 0.75; % in
height = approx_height_per_plot * n_rows;

fig = setup_figure2(width, height, setup_axes=false);
t = tiledlayout(n_rows, n_cols, 'Padding', 'tight', 'TileSpacing', 'tight');

tile_order = [1,3,5,2,4,6];
tex_names = ["x\ (\mathrm{m})", "y\ (\mathrm{m})", "z\ (\mathrm{m})", "\alpha\ (\mathrm{rad})", "\beta\ (\mathrm{rad})", "\gamma\ (\mathrm{rad})"];
cur_idx = 1;
for i = 1:num_subsystems
    i_idx = i_idxs{i};
    dim_i = size(i_idx, 2);
    for di = 1:dim_i
        nexttile(tile_order(cur_idx));
        hold on;
        title("");
        xlabel("$t\ (\mathrm{s})$", 'interpreter', 'latex');
        ylabel(strcat('$', tex_names(cur_idx), '$'), 'interpreter', 'latex');

        % reference trajectories and equilibrium
        dat.plot_pos_time(cur_idx);
        axis_limits = axis;

        dat_est.plot_pos_time(cur_idx, {'color', '#ff00ff', 'displayname', '$' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{sim}}$'});
        if isfield(args, 'traj_actual')
            args.traj_actual.plot_pos_time(cur_idx, {'color', '#000000', 'displayname', '$' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{robot}}$'});
        end
        
        y_range = axis_limits(4) - axis_limits(3);
        offset_for_desired_y_range = y_range * 0.1;
        xlim([axis_limits(1), axis_limits(2)]);
        ylim([axis_limits(3) - offset_for_desired_y_range, axis_limits(4) + offset_for_desired_y_range]);

        cur_idx = cur_idx + 1;

        if i == 1 && di == 1 % for exp1
            leg = legend();
            set(leg, 'Interpreter', 'latex');
            leg.ItemTokenSize(1) = 6;
            tmp = gca();
        end
    end
end

adjust_figure(fig, width, height);

% flush_legend(leg, tmp, 'northeast'); % [OPTIONAL] https://de.mathworks.com/matlabcentral/fileexchange/57962-flush-legend?s_tid=blogs_rc_6
% flush_legend(leg, tmp, 'northeast');

end