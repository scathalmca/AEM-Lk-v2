function [FileMatrix, ResMatrix] = ReadFile(Filename)
%  READFILE Brief summary of this function.
% 
% Detailed explanation of this function.
file = fopen(Filename);
lines = {};
while ~feof(file)
    line = fgetl(file);
    lines = [lines  line];
end
fclose(file);
ResMatrix = {};
values = strsplit(char(lines(2)), ',');
% Regular expression pattern to match doubles
pattern1 = '[-+]?\d*\.?\d+';
% Extract the matched doubles
matchesFrequecies = regexp(values, pattern1, 'match');
% Regular expression pattern to extract strings between double quotation marks
pattern = '"([^"]*)"';
% Extract the matched strings
Filematches = regexp(lines(1), pattern, 'tokens');
FileMatrix = {};
for i=1:numel(Filematches{1})
    FileMatrix = [FileMatrix ; char(Filematches{1}{1,i})];
    ResMatrix = [ResMatrix ; char(matchesFrequecies{i})];
end
end