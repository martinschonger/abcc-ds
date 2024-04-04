function remove_license_notice(logfile)

% Open the text file for reading and writing
file_ID = fopen(logfile, 'r+');
text_data = fscanf(file_ID, '%c');

% Define the pattern
pattern = '(\n\*{45}\n\s*License will expire in (\d+) days\.\n\*{45}\n\n)';

% Replace the found instances with a custom string
replacement = '';
modified_text = regexprep(text_data, pattern, replacement);

% Write the modified text back to the file
frewind(file_ID); % Move the file pointer to the beginning
fprintf(file_ID, '%s', modified_text);
fclose(file_ID);

end