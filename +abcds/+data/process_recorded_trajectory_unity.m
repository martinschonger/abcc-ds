% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function res = process_recorded_trajectory_unity(input_fullpath)

arguments
    input_fullpath string
end

opts = detectImportOptions(input_fullpath);
opts.DataLines = [2 Inf];
opts.VariableNamesLine = 1;
full_recording = readtable(input_fullpath, opts);

rec = full_recording(:, ["time", "x", "y", "z", "alpha", "beta", "gamma"]);
rec_arr = rec{:,:};

timediffs = rec_arr(2:end, 1) - rec_arr(1:end-1, 1);
vels_tmp = rec_arr(2:end, 2:end) - rec_arr(1:end-1, 2:end);
vels = vels_tmp ./ repmat(timediffs, 1, size(rec_arr, 2) - 1);

rec_arr_proc = rec_arr(1:end-1, :);
vels_proc = vels;

warning("Check if seconds_factor is correct for current dataset!");
seconds_factor = 1;
rec_arr_proc(:, 1) = rec_arr_proc(:, 1) - rec_arr_proc(1, 1);
rec_arr_proc(:, 1) = rec_arr_proc(:, 1) ./ seconds_factor;
vels_proc = vels_proc .* seconds_factor;

res = [rec_arr_proc, vels_proc];

abcds.util.log_msg("Loaded unity trajectory with %d samples", size(res, 1));

end