% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function [fig] = plot_experiment_subsystems2(general_opts, problem_opts, lyapunov_opts, barrier_opts, result, args)

arguments
    general_opts
    problem_opts
    lyapunov_opts
    barrier_opts
    result
    args.dat_est
    args.width_per_tile = 1.67 % in
    args.height_per_tile = 2 % in
    args.limit_fact = [0.2, 0.2]
    args.view
    args.traj_actual
    args.custom_ylab_position
    args.cut_end_sim
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
    if ~isfield(args, 'cut_end_sim')
        args.dat_est = abcds.data.data(pos = {pos_est}, vel = {vel_est}, tvec = {tvec_est});
    else
        args.dat_est = abcds.data.data(pos = {pos_est(:, 1:end-args.cut_end_sim)}, vel = {vel_est(:, 1:end-args.cut_end_sim)}, tvec = {tvec_est(:, 1:end-args.cut_end_sim)});
    end
end

[~, Pos] = general_opts.data.get_concatenated();

fig = setup_figure2(setup_axes=false);
t = tiledlayout(1, num_subsystems, 'Padding', 'tight', 'TileSpacing', 'tight');

min_vals = min(Pos, [], 2);
max_vals = max(Pos, [], 2);
range_vals = max_vals - min_vals;
xy_range = max(range_vals);
limit_fact = [repmat(args.limit_fact(1), 3, 1); repmat(args.limit_fact(2), 3, 1)];
lower_lims = min_vals - xy_range .* limit_fact;
upper_lims = max_vals + xy_range .* limit_fact;
limits = ([lower_lims, upper_lims]');
limits = limits(:)';

tex_names = ["x\ (\mathrm{m})", "y\ (\mathrm{m})", "z\ (\mathrm{m})", "\alpha\ (\mathrm{rad})", "\beta\ (\mathrm{rad})", "\gamma\ (\mathrm{rad})"];

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

        % reference trajectories and equilibrium
        plt_equil = general_opts.data.plot_equilibrium3(plot_dim1, plot_dim2, plot_dim3);
        plt_ref = general_opts.data.plot_pos3(plot_dim1, plot_dim2, plot_dim3, {'linewidth', 0.5, 'color', [0.2, 0.5725490196078431, 1, 0.7]});

        xlim([limits((plot_dim1 - 1)*2+1), limits((plot_dim1 - 1)*2+2)]);
        ylim([limits((plot_dim2 - 1)*2+1), limits((plot_dim2 - 1)*2+2)]);
        zlim([limits((plot_dim3 - 1)*2+1), limits((plot_dim3 - 1)*2+2)]);
        axis_limits = axis;

        % plot Barrier zero-level curve and initial and unsafe set
        if any(enable_barrier) && enable_barrier(i)
            Bi_set = abcds.set.set(result.B_i_fh{i}, dim_i);
            plt_B = Bi_set.plot3(axlim1 = axis_limits(1:2), axlim2 = axis_limits(3:4), axlim3 = axis_limits(5:6), level = barrier_opts.sigma(i), plt_opts = {'facecolor', '#d41919', 'facealpha', 0.2, 'displayname', '$' + abcds.util.constants.BARR_VAR_TEX + '_i(' + abcds.util.constants.STATE_VAR_TEX + '_i)=\sigma_i$'});

            % plot initial set
            plt_X0 = barrier_opts.X_0{i}.plot3(axlim1 = axis_limits(1:2), axlim2 = axis_limits(3:4), axlim3 = axis_limits(5:6), plt_opts = {'facecolor', 'cyan', 'displayname', strcat('$X_0$')});

            % plot unsafe set
            plt_Xu = barrier_opts.X_u{i}.plot3(axlim1 = axis_limits(1:2), axlim2 = axis_limits(3:4), axlim3 = axis_limits(5:6), plt_opts = {'facecolor', 'black', 'facealpha', 0.25, 'displayname', strcat('$X_u$')});
        end

        plt_sim{1} = [];
        plt_actual{1} = [];
        plt_sim = args.dat_est.plot_pos3(plot_dim1, plot_dim2, plot_dim3, {'color', '#ff00ff', 'linewidth', 1, 'displayname', '$' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{sim}}$'});
        if isfield(args, 'traj_actual')
            plt_actual = args.traj_actual.plot_pos3(plot_dim1, plot_dim2, plot_dim3, {'color', '#000000', 'linewidth', 1, 'displayname', '$' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{robot}}$'});
        end

        if isfield(args, 'traj_actual') && i == 1
            plot_cframe(args.traj_actual.pos{1}(1:3,1), args.traj_actual.pos{1}(4:6,1));
            for tmp_i = 0:20:99
                plot_cframe(args.traj_actual.pos{1}(1:3,end-tmp_i), args.traj_actual.pos{1}(4:6,end-tmp_i));
            end
        end

        xlabel(strcat('$', tex_names(plot_dim1), '$'), 'interpreter', 'latex');
        ylab = ylabel(strcat('$', tex_names(plot_dim2), '$'), 'interpreter', 'latex');
        zlabel(strcat('$', tex_names(plot_dim3), '$'), 'interpreter', 'latex');

        xlim([axis_limits(1), axis_limits(2)]);
        ylim([axis_limits(3), axis_limits(4)]);
        zlim([axis_limits(5), axis_limits(6)]);

        if isfield(args, 'custom_ylab_position') && ~isempty(args.custom_ylab_position{i})
            set(ylab, 'position', ylab.Position + args.custom_ylab_position{i});
        end

        if isfield(args, 'view') && ~isempty(args.view{i})
            view(args.view{i});
        end
    end
end

width = args.width_per_tile * t.GridSize(2); % in
height = args.height_per_tile * t.GridSize(1); % in
adjust_figure(fig, width, height);

ax1 = axes(fig,'Units','Normalized','Position',[0, 0.913, 1, 0.1]);
set(ax1, 'color', 'none');
set(ax1, 'XTick', [], 'XTickLabel', []);
set(ax1, 'YTick', [], 'YTickLabel', []);
set(get(ax1, 'XAxis'), 'Visible', 'off');
set(get(ax1, 'YAxis'), 'Visible', 'off');
leg = legend(ax1, [plt_equil, plt_ref{1}, plt_X0, plt_Xu, plt_B, plt_sim{1}, plt_actual{1}], 'Orientation', 'Horizontal', 'location', 'north');
set(leg, 'Interpreter', 'latex');
leg.ItemTokenSize(1) = 6;

end