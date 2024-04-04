% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


setup;
input_root_path = './output/';
output_root_path = './output/video_iros/';
exp2_timestamp = 'REPLACE_WITH_TIMESTAMP_OF_EXP2'; % last tested with: 20240403T163212297

generate_pfv_recording_multi_iros(input_root_path, output_root_path, exp2_timestamp, '2_recording_multi');
%%
generate_pfv_time_iros(input_root_path, output_root_path, exp2_timestamp, '2_recording_time', include_sim=false);

%%
traj_actual = abcds.data.robot_rec('./datasets/robot_recordings/gbin/trajectory_following/trajs.txt', dims_to_keep=1:6, type="6d", num_samples_per_trajectory=1000);
generate_pfv_trajectory_following_iros(input_root_path, output_root_path, exp2_timestamp, '3_trajectory_following', traj_actual, total_time=8);
%%
generate_pfv_time_iros(input_root_path, output_root_path, exp2_timestamp, '3_trajectory_following_time', traj_actual=traj_actual, total_time=7);

%%
traj_actual = abcds.data.robot_rec('./datasets/robot_recordings/gbin/perturbation/trajs.txt', dims_to_keep=1:6, type="6d", num_samples_per_trajectory=1000);
% generate_pfv_interaction_helperplot_iros(output_root_path, traj_actual, '4_perturbation_helper');
timestamp = exp2_timestamp;
interaction_timepoints = [256, 354; 648, 767];  % for 1000 frames; Recording_2024-03-21_17-16-47
generate_pfv_interaction_iros(input_root_path, output_root_path, timestamp, '4_perturbation', traj_actual, interaction_timepoints);
%%
generate_pfv_interaction_time_iros(input_root_path, output_root_path, exp2_timestamp, '4_perturbation_time', traj_actual, interaction_timepoints, total_time=9);
