% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function [Data, Target, indivTrajStartIndices, timestamps] = recorded_trajectories_to_refdata(input_fullpaths, args, preprocess_args)

arguments
    input_fullpaths
    args.num_samples_per_trajectory = 100
    preprocess_args.preprocess_args struct = struct() % see args of process_recorded_trajectory()
end

Data = [];
indivTrajStartIndices = [1];
timestamps = {};
preprocess_args_cell = abcds.util.struct_to_named_cellarray(preprocess_args.preprocess_args);
for i = 1:length(input_fullpaths)
    res_tmp = abcds.data.process_recorded_trajectory(input_fullpaths{i}, preprocess_args_cell{:});
    res_tmp = res_tmp';
    if args.num_samples_per_trajectory > 0
        idx = 1:size(res_tmp, 2);
        didx = linspace(min(idx), max(idx), args.num_samples_per_trajectory);
        res = zeros(size(res_tmp, 1), args.num_samples_per_trajectory);
        for j = 1:size(res_tmp, 1)
            res(j, :) = interp1(idx, res_tmp(j, :), didx);
        end
    else
        res = res_tmp;
    end

    Data = [Data, [res(2:end, :)]];
    indivTrajStartIndices = [indivTrajStartIndices, 1 + size(Data, 2)];
    timestamps{end+1} = res(1, :);
end

M = size(Data, 1) / 2;
Target = mean(Data(1:M, [indivTrajStartIndices(2:end) - 1]), 2);

end