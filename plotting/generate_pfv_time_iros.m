% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function generate_pfv_time_iros(input_root_path, output_root_path, timestamp, plot_id, args)

arguments
    input_root_path
    output_root_path
    timestamp
    plot_id
    args.traj_actual
    args.include_ref = true
    args.include_sim = true
    args.total_time = 6 % seconds
    args.fps = 24 % frames per second
end

linewidth_global = 4;
linewidth_global_major = 5;

input_path = fullfile(input_root_path, timestamp);
opts = load(fullfile(input_path, 'opts.mat'));
general_opts = opts.general_opts;
problem_opts = opts.problem_opts;
result = load(fullfile(input_path, 'result.mat'));
result = result.result;

num_subsystems = length(problem_opts.i_idxs);

if args.include_sim
    [pos_est, vel_est, tvec_est] = abcds.util.integrate_over_time(result.f_fh, general_opts.data.x0_mean(), general_opts.data.target);
    dat_est = abcds.data.data(pos = {pos_est}, vel = {vel_est}, tvec = {tvec_est});
end

[~, Pos] = general_opts.data.get_concatenated();


dim = general_opts.data.dim;

n_cols = 1;
n_rows = ceil(dim/n_cols);

width = 1*3.41275152778; % in
approx_height_per_plot = (3*3.41275152778) / 6; % in
height = approx_height_per_plot * n_rows;
fig = setup_figure2(width, height, setup_axes=false);

myVideo = VideoWriter(fullfile(output_root_path, plot_id), 'MPEG-4');  % open video file
myVideo.FrameRate = args.fps;  % can adjust this, 5 - 10 works well for me
open(myVideo);

t = tiledlayout(n_rows, n_cols, 'Padding', 'tight', 'TileSpacing', 'tight');
XTick = 0:ceil(args.total_time);


set(fig, 'Color', 'k');


limit_fact = 0.1;


cur_idx = 1;
for i = 1:num_subsystems
    i_idx = problem_opts.i_idxs{i};
    dim_i = size(i_idx, 2);
    for di = 1:dim_i
        axis_limits_cell{cur_idx} = [0, args.total_time, min(general_opts.data.pos{1}(cur_idx, :)), max(general_opts.data.pos{1}(cur_idx, :))];
        for n = 2:general_opts.data.num_traj
            axis_limits_cell{cur_idx} = [0, max(axis_limits_cell{cur_idx}(2), general_opts.data.tvec{n}(end)), min(axis_limits_cell{cur_idx}(3), min(general_opts.data.pos{n}(cur_idx, :))), max(axis_limits_cell{cur_idx}(4), max(general_opts.data.pos{n}(cur_idx, :)))];
        end
        cur_idx = cur_idx + 1;
    end
end

axis_limits_cell{1}(3:4) = [0.4, 0.6];
axis_limits_cell{2}(3:4) = [-0.2, 0.4];
axis_limits_cell{3}(3:4) = [0, 0.4];
axis_limits_cell{4}(3:4) = [0.8, 1.4];
axis_limits_cell{5}(3:4) = [-4.5, -3];
axis_limits_cell{6}(3:4) = [-1.3, 0];

frames = args.total_time * args.fps;

for f = 1:frames
    cur_sec = f/args.fps;


    cur_idx = 1;
    for i = 1:num_subsystems
        i_idx = problem_opts.i_idxs{i};
        dim_i = size(i_idx, 2);
        for di = 1:dim_i
            nexttile(cur_idx);
            hold on;
            if f == 1
                ax = gca();
                set(ax, 'fontsize', 24);
                set(ax, 'XTickLabel', []);
                set(ax, 'XTick', XTick);
                set(ax, 'YTickLabel', []);
                set(ax, 'TickLength', [0,0]);
                set(ax, 'XColor', 'white', 'YColor', 'white');
                set(ax, 'Color', 'k', 'XColor', 'w', 'YColor', 'w');
                box on;

                if cur_idx == 6
                    1;
                else
                    set(ax,'xticklabel',[]);
                end
            end

            % reference trajectories and equilibrium
            axis_limits = axis_limits_cell{cur_idx};

            if args.include_ref
                cur_data = general_opts.data;
                tmp_idx = find(cur_data.tvec{1} > cur_sec, 1);
                if isempty(tmp_idx) && (f > args.fps)
                    tmp_idx = length(cur_data.tvec{1});
                end
                tmp_idx_range_to_plot = 1:tmp_idx;
                plt_obj = {};
                plt_opts = {};
                for n = 1:cur_data.num_traj
                    plt_obj{n} = plot(cur_data.tvec{n}(tmp_idx_range_to_plot), cur_data.pos{n}(cur_idx, tmp_idx_range_to_plot), ...
                        'color', abcds.util.constants.TRAJECTORY_COLOR_BG, ...
                        'linewidth', linewidth_global, ...
                        'displayname', '$\ ' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{ref}}$', ...
                        plt_opts{:});
                    if n > 1 || f > 1
                        set(plt_obj{n}, 'handlevisibility', 'off');
                    end
                    hold on;
                end
            end

            if args.include_sim
                cur_data = dat_est;
                tmp_idx = find(cur_data.tvec{1} > cur_sec, 1);
                if isempty(tmp_idx) && (f > args.fps)
                    tmp_idx = length(cur_data.tvec{1});
                end
                tmp_idx_range_to_plot = 1:tmp_idx;
                plt_obj = {};
                for n = 1:cur_data.num_traj
                    plt_obj{n} = plot(cur_data.tvec{n}(tmp_idx_range_to_plot), cur_data.pos{n}(cur_idx, tmp_idx_range_to_plot), ...
                        'color', '#ff00ff', ...
                        'linewidth', linewidth_global_major, ...
                        'displayname', '$\ ' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{sim}}$');
                    if n > 1 || f > 1
                        set(plt_obj{n}, 'handlevisibility', 'off');
                    end
                    hold on;
                end
            end

            if isfield(args, 'traj_actual')
                cur_data = args.traj_actual;
                tmp_idx = find(cur_data.tvec{1} > cur_sec, 1);
                if isempty(tmp_idx) && (f > args.fps)
                    tmp_idx = length(cur_data.tvec{1});
                end
                tmp_idx_range_to_plot = 1:tmp_idx;
                plt_obj = {};
                for n = 1:cur_data.num_traj
                    plt_obj{n} = plot(cur_data.tvec{n}(tmp_idx_range_to_plot), cur_data.pos{n}(cur_idx, tmp_idx_range_to_plot), ...
                        'color', 'w', ...
                        'linewidth', linewidth_global_major, ...
                        'displayname', '$\ ' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{robot}}$');
                    if n > 1 || f > 1
                        set(plt_obj{n}, 'handlevisibility', 'off');
                    end
                    hold on;
                end
            end
            
            y_range = axis_limits(4) - axis_limits(3);
            offset_for_desired_y_range = y_range * limit_fact;
            xlim([axis_limits(1), axis_limits(2)]);
            ylim([axis_limits(3) - offset_for_desired_y_range, axis_limits(4) + offset_for_desired_y_range]);
    
            cur_idx = cur_idx + 1;
        end
    end

    pause(0.01)  % Pause and grab frame
    frame = getframe(gcf);  % get frame
    writeVideo(myVideo, frame);
end


close(myVideo);

tex_names = ["x", "y", "z", "\alpha", "\beta", "\gamma"];
for d = 1:6
    nexttile(d);
    if d == 6
        xticklabels('auto');
        set(gca, 'XTick', XTick);
        xlabel("$t (\mathrm{s})$", 'interpreter', 'latex');
        xtickangle(0);
    end
    yticklabels('auto');
    set(gca, 'YTick', axis_limits_cell{d}(3:4));
    ylabel(strcat('$', tex_names(d), '$'), 'interpreter', 'latex', 'Rotation', 0);
end


leg = legend();
leg.ItemTokenSize(1) = 18;
set(leg, 'Interpreter', 'latex');
set(leg, 'TextColor', 'white');
set(gcf, 'InvertHardCopy', 'off'); 
set(gcf, 'Color','k');
filename = strcat(output_root_path, plot_id, '.pdf');
print(fig, filename, '-dpdf');
close(fig);

end