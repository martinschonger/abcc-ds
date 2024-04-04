% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


% Note: You may have to restart MATLAB after running 'generate_plots_video_iros.m' and before running
%       this script. Otherwise, the generated PDF's may be cropped.

setup;
input_root_path = './output/';
output_root_path = './output/figures_iros/';

%%
sim1_timestamp = 'REPLACE_WITH_TIMESTAMP_OF_SIM1'; % last tested with: 20240403T162927782
plot_indiv_dims_over_time_wrapper(input_root_path, output_root_path, sim1_timestamp, 'sim1_time4');
plot_experiment_subsystems_wrapper(input_root_path, output_root_path, sim1_timestamp, 'sim1_3d4', limit_fact=[0.68,1.055], custom_ylab_position={[],[0.2 0.6 0]});
%%
sim2_timestamp = 'REPLACE_WITH_TIMESTAMP_OF_SIM2'; % last tested with: 20240403T163048844
plot_indiv_dims_over_time_wrapper(input_root_path, output_root_path, sim2_timestamp, 'sim2_time4');
plot_experiment_subsystems_wrapper(input_root_path, output_root_path, sim2_timestamp, 'sim2_3d4', limit_fact=[0.4,1], custom_ylab_position={[],[0.3 0.7 0]});
%%
exp1_timestamp = 'REPLACE_WITH_TIMESTAMP_OF_EXP1'; % last tested with: 20240403T163111063
traj_actual = abcds.data.robot_rec('./datasets/robot_recordings/gbin/trajectory_following/trajs.txt', dims_to_keep=1:6, type="6d");
plot_indiv_dims_over_time_wrapper(input_root_path, output_root_path, exp1_timestamp, 'exp1_time4', traj_actual=traj_actual);
plot_experiment_subsystems_wrapper(input_root_path, output_root_path, exp1_timestamp, 'exp1_3d4', ...
    height_per_tile=1.77, limit_fact=[0.26,0.8], view={[76.31 30.65],[55.71, 19.09]}, traj_actual=traj_actual, custom_ylab_position={[],[1.8 2 0]}, ...
    cut_end_sim=1200);
