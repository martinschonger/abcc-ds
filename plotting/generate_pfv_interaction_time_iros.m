% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function fig = generate_pfv_interaction_time_iros(input_root_path, output_root_path, timestamp, plot_id, traj_actual, interaction_timepoints, args)

arguments
    input_root_path
    output_root_path
    timestamp
    plot_id
    traj_actual
    interaction_timepoints
    args.total_time = 6 % seconds
    args.fps = 24
end

frames = 1000;
linewidth_global = 4;
linewidth_global_major = 5;
perturbation_color = '#fa9f3e';

input_path = fullfile(input_root_path, timestamp);
opts = load(fullfile(input_path, 'opts.mat'));
general_opts = opts.general_opts;
problem_opts = opts.problem_opts;
result = load(fullfile(input_path, 'result.mat'));
result = result.result;

num_subsystems = length(problem_opts.i_idxs);

[pos_est, vel_est, tvec_est] = abcds.util.integrate_over_time(result.f_fh, general_opts.data.x0_mean(), general_opts.data.target);
dat_est = abcds.data.data(pos = {pos_est}, vel = {vel_est}, tvec = {tvec_est});


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
        % axis_limits_cell{cur_idx} = [0, max(general_opts.data.tvec{1}), min(general_opts.data.pos{1}(cur_idx, :)), max(general_opts.data.pos{1}(cur_idx, :))];
        axis_limits_cell{cur_idx} = [0, args.total_time, min(general_opts.data.pos{1}(cur_idx, :)), max(general_opts.data.pos{1}(cur_idx, :))];
        for n = 2:general_opts.data.num_traj
            axis_limits_cell{cur_idx} = [0, max(axis_limits_cell{cur_idx}(2), general_opts.data.tvec{n}(end)), min(axis_limits_cell{cur_idx}(3), min(general_opts.data.pos{n}(cur_idx, :))), max(axis_limits_cell{cur_idx}(4), max(general_opts.data.pos{n}(cur_idx, :)))];
        end
        cur_idx = cur_idx + 1;
    end
end

axis_limits_cell{1}(3:4) = [0.3, 0.6]; % 0.3 differs from the default 0.4 in generate_pfv_time_iros
axis_limits_cell{2}(3:4) = [-0.2, 0.4];
axis_limits_cell{3}(3:4) = [0, 0.4];
axis_limits_cell{4}(3:4) = [0.8, 1.4];
axis_limits_cell{5}(3:4) = [-4.5, -3];
axis_limits_cell{6}(3:4) = [-1.3, 0];


n = 1;

for f = 1:frames
    idx_range_to_plot = 1:f;

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


            cur_data = traj_actual;

            interactive_plot_idx = 1;
            tmp_end = min(f, interactive_plot_idx(1,1));
            cur_range = interactive_plot_idx:tmp_end;
            tmp_plot_color = 'w';
            plt_opts = {'color', tmp_plot_color};
            plt_objs3.trajectories{n} = plot(traj_actual.tvec{n}(cur_range), traj_actual.pos{n}(cur_idx, cur_range), 'linewidth', linewidth_global_major, 'displayname', '$\ ' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{actual}}$', 'handlevisibility', 'off', plt_opts{:});
            hold on;
            for itp = 1:size(interaction_timepoints, 1)
                if f >= interaction_timepoints(itp, 1)
                    if f > interaction_timepoints(itp, 2)
                        % interaction has passed
                        % just plot it in full
                        tmp_start_idx = interaction_timepoints(itp, 1);
                        tmp_end_idx = interaction_timepoints(itp, 2);
                        cur_range = tmp_start_idx:tmp_end_idx;
                        tmp_plot_color = perturbation_color;
                        plt_opts = {'color', tmp_plot_color};
                        plt_objs3.trajectories{n} = plot(traj_actual.tvec{n}(cur_range), traj_actual.pos{n}(cur_idx, cur_range), 'linewidth', linewidth_global_major, 'displayname', '$\ ' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{actual}}$', 'handlevisibility', 'off', plt_opts{:});
                        hold on;

                        interactive_plot_idx = interaction_timepoints(itp, 2);
                        tmp_plot_color = 'w';
                        plt_opts = {'color', tmp_plot_color};
                        if itp < size(interaction_timepoints, 1)
                            tmp_end = min(f, interaction_timepoints(itp+1,1));
                            cur_range = interactive_plot_idx:tmp_end;
                        else
                            tmp_end = min(f, frames);
                            cur_range = interactive_plot_idx:tmp_end;
                        end
                        plt_objs3.trajectories{n} = plot(traj_actual.tvec{n}(cur_range), traj_actual.pos{n}(cur_idx, cur_range), 'linewidth', linewidth_global_major, 'displayname', '$\ ' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{actual}}$', 'handlevisibility', 'off', plt_opts{:});
                        
                        interactive_plot_idx = tmp_end;
                    else
                        % interaction is ongoing
                        % set interactive plot start idx to start of interaction
                        tmp_plot_color = perturbation_color;
                        interactive_plot_idx = interaction_timepoints(itp, 1);
                        break;
                    end
                end
            end
            
            cur_range = interactive_plot_idx:f;
            plt_opts = {'color', tmp_plot_color};
            plt_objs3.trajectories{n} = plot(traj_actual.tvec{n}(cur_range), traj_actual.pos{n}(cur_idx, cur_range), 'linewidth', linewidth_global_major, 'displayname', '$\ ' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{actual}}$', 'handlevisibility', 'off', plt_opts{:});
            plt_robot = plt_objs3.trajectories{n};
            

            y_range = axis_limits(4) - axis_limits(3);
            offset_for_desired_y_range = y_range * limit_fact;
            xlim([axis_limits(1), axis_limits(2)]);
            ylim([axis_limits(3) - offset_for_desired_y_range, axis_limits(4) + offset_for_desired_y_range]);
    
            cur_idx = cur_idx + 1;
        end
    end

    pause(0.01);  % Pause and grab frame
    frame = getframe(gcf);  % get frame
    writeVideo(myVideo, frame);
end

plt_perturbation = plot([1e6, 1e6], [1e7, 1e7], 'linewidth', linewidth_global_major, 'color', perturbation_color, 'displayname', '$\ \mathrm{Perturbation}$');

close(myVideo);


tmp_speed_fact = (frames / args.fps) / traj_actual.tvec{1}(end);
fprintf("target_duration=%d", traj_actual.tvec{1}(end));
fprintf("tmp_speed_fact=%d", tmp_speed_fact);


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


leg = legend([plt_robot, plt_perturbation]);
leg.ItemTokenSize(1) = 18;
set(leg, 'Interpreter', 'latex');
set(leg, 'TextColor', 'white');
set(gcf, 'InvertHardCopy', 'off'); 
set(gcf, 'Color','k');
filename = strcat(output_root_path, plot_id, '.pdf');
print(fig, filename, '-dpdf');
close(fig);

end
    