% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function plot_indiv_dims_over_time_wrapper(input_root_path, output_root_path, timestamp, plot_id, args)

arguments
    input_root_path, output_root_path, timestamp, plot_id
    args.traj_actual
end

input_cur_path = fullfile(input_root_path, timestamp);
opts = load(fullfile(input_cur_path, 'opts.mat'));
general_opts = opts.general_opts;
problem_opts = opts.problem_opts;
result = load(fullfile(input_cur_path, 'result.mat'));
result = result.result;

[pos_est, vel_est, tvec_est] = abcds.util.integrate_over_time(result.f_fh, general_opts.data.x0_mean(), general_opts.data.target);
dat_est = abcds.data.data(pos = {pos_est}, vel = {vel_est}, tvec = {tvec_est});

args_cell = abcds.util.struct_to_named_cellarray(args);
fig = plot_indiv_dims_over_time2(general_opts.data, dat_est, problem_opts.i_idxs, args_cell{:});
figure_to_file2(fig, fullfile(output_root_path, plot_id), format='-dpdf');
close(fig);

end