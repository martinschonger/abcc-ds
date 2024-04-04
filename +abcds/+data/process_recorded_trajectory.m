% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function res = process_recorded_trajectory(input_fullpath, args)

arguments
    input_fullpath string
    args.mode = "record" % "eval"
    args.type string = "cartesian" % "joint", "6d"
    args.vel_norm_th = 1.5e-7
    args.safety_margin_beginning = 1000
    args.safety_margin = 3000
    args.input_var_names
    args.cut_begin
    args.cut_end
    args.movemean = false
end

opts = detectImportOptions(input_fullpath);
opts.DataLines = [3 Inf];
opts.VariableNamesLine = 2;
warning_settings = warning;
warning('off');
full_recording = readtable(input_fullpath, opts);
warning(warning_settings);

if ~isfield(args, 'input_var_names')
    switch args.type
        case 'cartesian'
            args.input_var_names = ["time", "O_T_EE_12_", "O_T_EE_13_", "O_T_EE_14_"];
        case 'joint'
            args.input_var_names = ["time", "q_0_", "q_1_", "q_2_", "q_3_", "q_4_", "q_5_", "q_6_"];
        case '6d'
            args.input_var_names = ["time", "O_T_EE_0_", "O_T_EE_1_", "O_T_EE_2_", "O_T_EE_3_", "O_T_EE_4_", "O_T_EE_5_", "O_T_EE_6_", "O_T_EE_7_", "O_T_EE_8_", "O_T_EE_9_", "O_T_EE_10_", "O_T_EE_11_", "O_T_EE_12_", "O_T_EE_13_", "O_T_EE_14_", "O_T_EE_15_"];
        otherwise
            error("Invalid type: %s", args.type);
    end
end
rec = full_recording(:, args.input_var_names);
rec_arr_tmp = rec{:,:};

if strcmp(args.type, '6d')
    T = size(rec_arr_tmp, 1);
    rec_arr = zeros(T, 7);
    for t = 1:T
        rec_arr(t, 1) = rec_arr_tmp(t, 1);
        transform_matrix = reshape(rec_arr_tmp(t, 2:end), [4, 4]);
        translation_vector = transform_matrix(1:3, 4);
        rotation_matrix = transform_matrix(1:3, 1:3);
        rec_arr(t, 2:4) = translation_vector';
        [~, rec_arr(t, 5:7)] = rotm2eul(rotation_matrix, 'ZXY'); % cf. https://docs.unity3d.com/Manual/QuaternionAndEulerRotationsInUnity.html
    end

    sth_changed = true;
    while sth_changed
        sth_changed = false;
        for t = 2:T
            for angle_idx = 5:7
                tmp_diff = rec_arr(t, angle_idx) - rec_arr(t-1, angle_idx);
                tmp_sign = sign(tmp_diff);
                if abs(tmp_diff) > (1.75 * pi)
                    sth_changed = true;
                    rec_arr(t:T, angle_idx) = rec_arr(t:T, angle_idx) - tmp_sign * 2 * pi;
                end
            end
            if sth_changed
                break;
            end
        end
    end
else
    rec_arr = rec_arr_tmp;
end

if args.movemean
    rec_arr = movmean(rec_arr, 400, 1);
end

timediffs = rec_arr(2:end, 1) - rec_arr(1:end-1, 1);
vels_tmp = rec_arr(2:end, 2:end) - rec_arr(1:end-1, 2:end);
vels = vels_tmp ./ repmat(timediffs, 1, size(rec_arr, 2) - 1);
abcds.util.log_msg("Applied lowpass filter on velocities: lowpass(vels, 100, 1e3)");
vels = lowpass(vels, 100, 1e3);

% cut off beginning and end
switch args.mode
    case "record"
        vel_norms = sqrt(sum(vels.^2, 2));
        if strcmp(args.type, 'joint') || strcmp(args.type, '6d')
            args.vel_norm_th = 1.5e-5;
            args.safety_margin_beginning = 1500;
        end
        start_idx = args.safety_margin_beginning + find(vel_norms(args.safety_margin_beginning:end) > args.vel_norm_th, 1);
        if strcmp(args.type, 'cartesian') || strcmp(args.type, '6d')
            start_idx = find(vel_norms(1:start_idx+args.safety_margin) <= args.vel_norm_th, 1, 'last');
            tmp_end_idx = find(vel_norms(start_idx+1:end) < args.vel_norm_th, 1);
        else
            tmp_end_idx = find(vel_norms(start_idx+1:end) > args.vel_norm_th, 1, 'last');
        end
        if isempty(tmp_end_idx)
            tmp_end_idx = length(vel_norms(start_idx+1:end)) - 1;
        end
        end_idx = start_idx + 1 + tmp_end_idx;
        rec_arr_proc = rec_arr(start_idx:end_idx, :);
        vels_proc = vels(start_idx:end_idx, :);
    case "eval"
        rec_arr_proc = rec_arr(1:end-1, :);
        vels_proc = vels;
end

seconds_factor = 1e3;
rec_arr_proc(:, 1) = rec_arr_proc(:, 1) - rec_arr_proc(1, 1);
rec_arr_proc(:, 1) = rec_arr_proc(:, 1) ./ seconds_factor;
vels_proc = vels_proc .* seconds_factor;

res = [rec_arr_proc, vels_proc];

if isfield(args, 'cut_begin')
    res = res(args.cut_begin:end, :);
end
if isfield(args, 'cut_end')
    res = res(1:end-args.cut_end, :);
end

abcds.util.log_msg("Loaded robot trajectory with %d samples", size(res, 1));

end