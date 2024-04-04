% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function res = struct_to_str(struct_in, delimiter)

arguments
    struct_in struct
    delimiter = ", "
end

fns = fieldnames(struct_in);
if ~isempty(fns)
    res = "";
    for i = 1:length(fns)
        try
            tmp_struct_content = struct_in.(fns{i});
            if isnumeric(tmp_struct_content)
                res = append(res, fns{i}, "=", mat2str(tmp_struct_content), delimiter);
            elseif isstruct(tmp_struct_content)
                res = append(res, fns{i}, "=", abcds.util.struct_to_str(tmp_struct_content, delimiter), delimiter);
            elseif iscell(tmp_struct_content)
                tmp_res = strings(0);
                for j = 1:length(tmp_struct_content)
                    tmp_res(end+1) = "[" + abcds.util.arr_to_str(tmp_struct_content{j}) + "]";
                end
                res = append(res, fns{i}, "={", join(tmp_res', ","), "}", delimiter);
            else
                res = append(res, fns{i}, "=", string(tmp_struct_content), delimiter);
            end
        catch
            res = append(res, fns{i}, "=NOT_CONVERTIBLE_TO_STRING", delimiter);
        end
    end
    res = convertStringsToChars(res);
    res = res(1:(end-strlength(delimiter))); % strip final delimiter
    res = convertCharsToStrings(res);
else
    res = "-";
end

end