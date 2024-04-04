% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function [fig] = plot_experiment_subsystems(general_opts, problem_opts, lyapunov_opts, barrier_opts, result, args)

arguments
    general_opts
    problem_opts
    lyapunov_opts
    barrier_opts
    result
    args.dat_est
    args.width_per_tile = 3.4 % in
    args.height_per_tile = 2 % in
    args.limit_fact = 0.2
end

if isfield(barrier_opts, 'X_i')
    enable_barrier = ~cellfun(@isempty, barrier_opts.X_i);
else
    enable_barrier = ~isempty(barrier_opts.X_0);
end

if ~isfield(problem_opts, 'i_idxs')
    problem_opts.i_idxs = {1:general_opts.data.dim};

    if lyapunov_opts.enable_lyapunov
        result.V_i_fh{1} = result.V_fh;
    end

    if enable_barrier
        barrier_opts.sigma(1) = 0.0;
        result.B_i_fh{1} = result.B_fh;
        tmp_X_0 = barrier_opts.X_0;
        barrier_opts.X_0 = {};
        barrier_opts.X_0{1} = tmp_X_0;
        tmp_X_u = barrier_opts.X_u;
        barrier_opts.X_u = {};
        barrier_opts.X_u{1} = tmp_X_u;
    end
end
num_subsystems = length(problem_opts.i_idxs);

if ~isfield(args, 'dat_est')
    [pos_est, vel_est, tvec_est] = abcds.util.integrate_over_time(result.f_fh, general_opts.data.x0_mean(), general_opts.data.target);
    args.dat_est = abcds.data.data(pos = {pos_est}, vel = {vel_est}, tvec = {tvec_est});
end

[~, Pos] = general_opts.data.get_concatenated();

fig = setup_figure2(setup_axes=false);
t = tiledlayout('flow', 'Padding', 'compact', 'TileSpacing', 'compact');
title(t, "State space");

min_vals = min(Pos, [], 2);
max_vals = max(Pos, [], 2);
range_vals = max_vals - min_vals;
xy_range = max(range_vals);
limit_fact = args.limit_fact;
lower_lims = min_vals - xy_range * limit_fact;
upper_lims = max_vals + xy_range * limit_fact;
limits = ([lower_lims, upper_lims]');
limits = limits(:)';

for i = 1:num_subsystems
    plot_dims = problem_opts.i_idxs{i};
    dim_i = length(problem_opts.i_idxs{i});


    if dim_i == 1
        assert(false);
    elseif dim_i == 2
        assert(false);
    elseif dim_i == 3
        plot_dim1 = plot_dims(1);
        plot_dim2 = plot_dims(2);
        plot_dim3 = plot_dims(3);

        nexttile;
        title("Subsystem ["+abcds.util.arr_to_str(i)+"]");
        xlabel(strcat('$', abcds.util.constants.STATE_VAR_TEX, '_', int2str(plot_dim1), '$'), 'interpreter', 'latex');
        ylabel(strcat('$', abcds.util.constants.STATE_VAR_TEX, '_', int2str(plot_dim2), '$'), 'interpreter', 'latex');
        zlabel(strcat('$', abcds.util.constants.STATE_VAR_TEX, '_', int2str(plot_dim3), '$'), 'interpreter', 'latex');

        % reference trajectories and equilibrium
        general_opts.data.plot_equilibrium3(plot_dim1, plot_dim2, plot_dim3);
        general_opts.data.plot_pos3(plot_dim1, plot_dim2, plot_dim3);

        xlim([limits((plot_dim1 - 1)*2+1), limits((plot_dim1 - 1)*2+2)]);
        ylim([limits((plot_dim2 - 1)*2+1), limits((plot_dim2 - 1)*2+2)]);
        zlim([limits((plot_dim3 - 1)*2+1), limits((plot_dim3 - 1)*2+2)]);
        axis_limits = axis;

        % plot Barrier zero-level curve and initial and unsafe set
        if any(enable_barrier) && enable_barrier(i)
            Bi_set = abcds.set.set(result.B_i_fh{i}, dim_i);
            Bi_set.plot3(axlim1 = axis_limits(1:2), axlim2 = axis_limits(3:4), axlim3 = axis_limits(5:6), level = barrier_opts.sigma(i), plt_opts = {'facecolor', '#7D0675', 'displayname', '$' + abcds.util.constants.BARR_VAR_TEX + '_i(' + abcds.util.constants.STATE_VAR_TEX + '_i)=\sigma_i$'});

            % plot initial set
            barrier_opts.X_0{i}.plot3(axlim1 = axis_limits(1:2), axlim2 = axis_limits(3:4), axlim3 = axis_limits(5:6), plt_opts = {'facecolor', 'cyan', 'displayname', strcat('$X_0$')});

            % plot unsafe set
            barrier_opts.X_u{i}.plot3(axlim1 = axis_limits(1:2), axlim2 = axis_limits(3:4), axlim3 = axis_limits(5:6), plt_opts = {'facecolor', 'black', 'displayname', strcat('$X_u$')});
        end

        args.dat_est.plot_pos3(plot_dim1, plot_dim2, plot_dim3, {'color', '#ff00ff', 'displayname', '$' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{sim}}$'});

        xlim([axis_limits(1), axis_limits(2)]);
        ylim([axis_limits(3), axis_limits(4)]);
        zlim([axis_limits(5), axis_limits(6)]);

        leg = legend();
        set(leg, 'Interpreter', 'latex');
        leg.ItemTokenSize(1) = 15;

        view([36.692 76.314]);
    end
end

width = args.width_per_tile * t.GridSize(2); % in
height = args.height_per_tile * t.GridSize(1); % in
adjust_figure(fig, width, height);

end