% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function [] = log_msg(format_spec, varargin)

pre_str = "";
pre_str = append(pre_str, "[");
pre_str = append(pre_str, abcds.util.get_formatted_timestamp('isolong'));
pre_str = append(pre_str, "] ");

processed_format_spec = strrep(format_spec, '\n', '\n  ');
processed_format_spec = append(processed_format_spec, "\n");

processed_varargin = {};
for i = 1:length(varargin)
    if isa(varargin{i}, 'string')
        processed_varargin{i} = strrep(varargin{i}, '\n', '\n  ');
        processed_varargin{i} = strrep(processed_varargin{i}, '\\n  ', '\\n');
        processed_varargin{i} = sprintf(processed_varargin{i});
    else
        processed_varargin{i} = varargin{i};
    end
end

post_str = "";
stack = dbstack('-completenames');
if numel(stack) >= 2
    source_str = sprintf("  (%s(): line %d in file '%s')\n", stack(2).name, stack(2).line, strrep(stack(2).file, "\", "/"));
    post_str = append(post_str, source_str);
end

fprintf(pre_str+processed_format_spec+post_str, processed_varargin{:});

end