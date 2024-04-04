% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function plot_experiment_subsystems_wrapper(input_root_path, output_root_path, timestamp, plot_id, args)

arguments
    input_root_path, output_root_path, timestamp, plot_id
    args.view
    args.limit_fact = [0.6, 1]
    args.traj_actual
    args.custom_ylab_position
    args.height_per_tile
    args.cut_end_sim
end

input_cur_path = fullfile(input_root_path, timestamp);
opts = load(fullfile(input_cur_path, 'opts.mat'));
general_opts = opts.general_opts;
problem_opts = opts.problem_opts;
lyapunov_opts = opts.lyapunov_opts;
barrier_opts = opts.barrier_opts;
result = load(fullfile(input_cur_path, 'result.mat'));
result = result.result;
args_cell = abcds.util.struct_to_named_cellarray(args);
fig = plot_experiment_subsystems2(general_opts, problem_opts, lyapunov_opts, barrier_opts, result, args_cell{:});
figure_to_file2(fig, fullfile(output_root_path, plot_id), format='-dpdf');
close(fig);

end