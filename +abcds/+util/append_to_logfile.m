% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function append_to_logfile(logfile_fid, files_to_log_cellarray)

for i = 1:length(files_to_log_cellarray)
    content_to_append = readlines(files_to_log_cellarray{i});
    sprintf('%s\n', content_to_append);
    content_to_append = sprintf('%s\n', content_to_append);
    content_to_append = content_to_append(1:end-1);

    if i > 1
        fprintf(logfile_fid, '\n\n\n');
    end
    fprintf(logfile_fid, '[BEGIN] %s\n\n%s\n[END] %s', files_to_log_cellarray{i}, content_to_append, files_to_log_cellarray{i});
end

end