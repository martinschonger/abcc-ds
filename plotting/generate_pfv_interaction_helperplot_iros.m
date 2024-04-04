% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function fig = generate_pfv_interaction_helperplot_iros(output_root_path, traj_actual, plot_id)

arguments
    output_root_path
    traj_actual
    plot_id
end

frames = 1000; % note: need traj_actual to have the same number of samples 
linewidth_global = 1;
linewidth_global_major = 2;
linewidth_global_minor = 0.5;

Data = traj_actual.get_concatenated();

x_min = min(Data(1, :));
x_max = max(Data(1, :));
x_range = x_max - x_min;
y_min = min(Data(2, :));
y_max = max(Data(2, :));
y_range = y_max - y_min;
xy_range = max(x_range, y_range);
xy_range = xy_range * 1.75;
x_lowerlim = x_min - 0.5 * (xy_range - x_range);
x_upperlim = x_max + 0.5 * (xy_range - x_range);
y_lowerlim = y_min - 0.5 * (xy_range - y_range);
y_upperlim = y_max + 0.5 * (xy_range - y_range);
limits = [x_lowerlim, x_upperlim, y_lowerlim, y_upperlim];

initial_set_center = traj_actual.x0_mean;

[fig, ax] = setup_figure2(2*3*3.41275152778, 3*3.41275152778, false, false);
t = tiledlayout(6, 1, 'Padding', 'compact', 'TileSpacing', 'compact');

fontsize(fig, 10, "points");

tmp_xiref3 = traj_actual.pos;

dim_labels = ["x", "y", "z", "a", "b", "g"];
n = 1;
for d = 1:6
    nexttile;
    plt_objs3.trajectories{n} = plot(1:frames, tmp_xiref3{n}(d, :), 'linewidth', linewidth_global_major, 'displayname', dim_labels(d));
end

leg = legend();
leg.ItemTokenSize(1) = 10;
filename = strcat(output_root_path, plot_id, '.pdf');
print(fig, filename, '-dpdf');

end