% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function fig = generate_pfv_interaction_iros(input_root_path, output_root_path, timestamp, plot_id, traj_actual, interaction_timepoints, args)

arguments
    input_root_path
    output_root_path
    timestamp
    plot_id
    traj_actual
    interaction_timepoints
    args.crop_frame_idx = 0
    args.fps = 24
end

frames = 1000;
linewidth_global = 4;
linewidth_global_major = 5;
perturbation_color = '#fa9f3e';

input_path = fullfile(input_root_path, timestamp);
opts = load(fullfile(input_path, 'opts.mat'));
general_opts = opts.general_opts;
barrier_opts = opts.barrier_opts;
result = load(fullfile(input_path, 'result.mat'));
result = result.result;


enable_barrier = ~cellfun(@isempty, barrier_opts.X_i);

[pos_est, vel_est, tvec_est] = abcds.util.integrate_over_time(result.f_fh, general_opts.data.x0_mean(), general_opts.data.target);
dat_est = abcds.data.data(pos = {pos_est}, vel = {vel_est}, tvec = {tvec_est});


[~, Pos] = general_opts.data.get_concatenated();

fig = setup_figure2(3*3.41275152778, 3*3.41275152778, setup_axes=false);

myVideo = VideoWriter(fullfile(output_root_path, plot_id), 'MPEG-4');  % open video file
myVideo.FrameRate = args.fps;  % can adjust this, 5 - 10 works well for me
open(myVideo);

t = tiledlayout('flow', 'Padding', 'compact', 'TileSpacing', 'compact');


min_vals = min(Pos, [], 2);
max_vals = max(Pos, [], 2);
range_vals = max_vals - min_vals;
xy_range = max(range_vals);
limit_fact = 0.3;
lower_lims = min_vals - xy_range * limit_fact;
upper_lims = max_vals + xy_range * limit_fact;
limits = ([lower_lims, upper_lims]');
limits = limits(:)';

limits(1:2) = [0,0.9];
limits(3:4) = [-0.6,0.6];
limits(5:6) = [0,0.7];

XTick = [0,0.3,0.6,0.9];
YTick = [-0.6,-0.3,0,0.3,0.6];
ZTick = [0,0.35,0.7];
XTickLabels = [];
YTickLabels = [];
ZTickLabels = [];

i = 1;
dim_i = 3;
dim1 = 1;
dim2 = 2;
dim3 = 3;


nexttile;

% reference trajectories and equilibrium
plt_equil = general_opts.data.plot_equilibrium3(dim1, dim2, dim3, {'markeredgecolor', 'w', 'markerfacecolor', 'w', 'linewidth', 10, 'displayname', '$\ ' + abcds.util.constants.STATE_VAR_TEX + '^*$'});
plt_ref = general_opts.data.plot_pos3(dim1, dim2, dim3, {'displayname', '$\ ' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{ref}}$'});

plt_sim = dat_est.plot_pos3(dim1, dim2, dim3, {'color', '#ff00ff', 'linewidth', linewidth_global, 'displayname', '$\ ' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{sim}}$'});

xlim([limits((dim1 - 1)*2+1), limits((dim1 - 1)*2+2)]);
ylim([limits((dim2 - 1)*2+1), limits((dim2 - 1)*2+2)]);
zlim([limits((dim3 - 1)*2+1), limits((dim3 - 1)*2+2)]);
axis_limits = axis;

ax = gca();
set(ax, 'fontsize', 24);
set(ax, 'XTick', XTick, 'YTick', YTick, 'ZTick', ZTick);
set(ax, 'XTickLabel', XTickLabels, 'YTickLabel', YTickLabels, 'ZTickLabel', ZTickLabels);
set(ax, 'TickLength', [0,0]);
set(ax, 'XTick', XTick, 'YTick', YTick, 'ZTick', ZTick);
set(ax, 'XColor', 'white', 'YColor', 'white');
set(fig, 'Color', 'k');
set(ax, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', 'ZColor', 'w');
set(ax, 'GridColor', 'white');
ax.GridAlpha = 1;

% plot Barrier zero-level curve and initial and unsafe set
if any(enable_barrier) && enable_barrier(i)
    Bi_set = abcds.set.set(result.B_i_fh{i}, dim_i);
    plt_B = Bi_set.plot3(axlim1 = axis_limits(1:2), axlim2 = axis_limits(3:4), axlim3 = axis_limits(5:6), level = barrier_opts.sigma(i), plt_opts = {'facecolor', '#7D0675', 'facealpha', 0.3, 'displayname', '$\ ' + abcds.util.constants.BARR_VAR_TEX + '_1(' + abcds.util.constants.STATE_VAR_TEX + '_1)=\sigma_1$'});

    % plot initial set
    plt_X0 = barrier_opts.X_0{i}.plot3(axlim1 = axis_limits(1:2), axlim2 = axis_limits(3:4), axlim3 = axis_limits(5:6), plt_opts = {'facecolor', 'cyan', 'displayname', strcat('$\ X_0$')});

    % plot unsafe set
    plt_Xu = barrier_opts.X_u{i}.plot3(axlim1 = axis_limits(1:2), axlim2 = axis_limits(3:4), axlim3 = axis_limits(5:6), plt_opts = {'facecolor', 'white', 'facealpha', 0.5, 'displayname', strcat('$\ X_u$')});
end


position = dat_est.pos{1}(1:3, end);
euler_angles = dat_est.pos{1}(4:6, end);
rot_mat = eul2rotm(euler_angles', 'ZXY');
transform_matrix = [[rot_mat; 0,0,0], [position; 1]];
h = triad_alpha('Parent',gca,'Scale',0.18,'LineWidth',8,'Tag','Triad Example','Matrix',transform_matrix);


xlim([axis_limits(1), axis_limits(2)]);
ylim([axis_limits(3), axis_limits(4)]);
zlim([axis_limits(5), axis_limits(6)]);

view([-57.0219,44.3992]);


axis equal;


n = 1;

for f = 1:frames
    idx_range_to_plot = 1:f;

    interactive_plot_idx = 1;
    tmp_end = min(f, interactive_plot_idx(1,1));
    cur_range = interactive_plot_idx:tmp_end;
    tmp_plot_color = 'w';
    plt_opts = {'color', tmp_plot_color};
    plt_objs3.trajectories{n} = plot3(traj_actual.pos{n}(dim1, cur_range), traj_actual.pos{n}(dim2, cur_range), traj_actual.pos{n}(dim3, cur_range), ...
        'linewidth', linewidth_global_major, 'displayname', '$\ ' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{actual}}$', 'handlevisibility', 'off', ...
        plt_opts{:});
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
                plt_objs3.trajectories{n} = plot3(traj_actual.pos{n}(dim1, cur_range), traj_actual.pos{n}(dim2, cur_range), traj_actual.pos{n}(dim3, cur_range), ...
                    'linewidth', linewidth_global_major, 'displayname', '$\ ' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{actual}}$', 'handlevisibility', 'off', ...
                    plt_opts{:});
                
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
                plt_objs3.trajectories{n} = plot3(traj_actual.pos{n}(dim1, cur_range), traj_actual.pos{n}(dim2, cur_range), traj_actual.pos{n}(dim3, cur_range), ...
                    'linewidth', linewidth_global_major, 'displayname', '$\ ' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{actual}}$', 'handlevisibility', 'off', ...
                    plt_opts{:});
                
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
    plt_objs3.trajectories{n} = plot3(traj_actual.pos{n}(dim1, cur_range), traj_actual.pos{n}(dim2, cur_range), traj_actual.pos{n}(dim3, cur_range), ...
        'linewidth', linewidth_global_major, 'displayname', '$\ ' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{actual}}$', 'handlevisibility', 'off', ...
        plt_opts{:});
    plt_robot = plt_objs3.trajectories{n};
    
    position = traj_actual.pos{n}(1:3, idx_range_to_plot(end));
    euler_angles = traj_actual.pos{n}(4:6, idx_range_to_plot(end));
    rot_mat = eul2rotm(euler_angles', 'ZXY');
    transform_matrix = [[rot_mat; 0,0,0], [position; 1]];

    if f == 1
        h = triad('Parent',gca,'Scale',0.18,'LineWidth',8,'Tag','Triad Example','Matrix',transform_matrix);
    end

    set(h,'Matrix',transform_matrix);
    drawnow

    xlim([axis_limits(1), axis_limits(2)]);
    ylim([axis_limits(3), axis_limits(4)]);
    zlim([axis_limits(5), axis_limits(6)]);

    pause(0.01);  % Pause and grab frame
    frame = getframe(gcf);  % get frame
    writeVideo(myVideo, frame);

    if args.crop_frame_idx > 0 && f >= args.crop_frame_idx
        break;
    end
end

plt_perturbation = plot([1e6, 1e6], [1e7, 1e7], 'linewidth', linewidth_global_major, 'color', perturbation_color, 'displayname', '$\ \mathrm{Perturbation}$');

close(myVideo);


tmp_speed_fact = (frames / args.fps) / traj_actual.tvec{1}(end);
fprintf("target_duration=%d\n", traj_actual.tvec{1}(end));
fprintf("tmp_speed_fact=%d\n", tmp_speed_fact);


XTickLabels = ["0", "", "", "0.9"];
YTickLabels = ["-0.6", "", "", "", "0.6"];
ZTickLabels = ["0", "", "0.7"];
set(ax, 'XTickLabel', XTickLabels, 'YTickLabel', YTickLabels, 'ZTickLabel', ZTickLabels);

xlabel(strcat('$x$'), 'interpreter', 'latex');
ylabel(strcat('$y$'), 'interpreter', 'latex');
zlabel(strcat('$z$'), 'interpreter', 'latex', 'Rotation', 0);


leg = legend([plt_equil, plt_ref{1}, plt_X0, plt_Xu, plt_B, plt_sim{1}, plt_robot, plt_perturbation]);
leg.ItemTokenSize(1) = 18;
set(leg, 'Interpreter', 'latex');
set(leg, 'TextColor', 'white');
set(gcf, 'InvertHardCopy', 'off'); 
set(gcf, 'Color','k');
filename = strcat(output_root_path, plot_id, '.pdf');
print(fig, filename, '-dpdf');
close(fig);

end
